
/*
Create TableFunction.FxAztec.dbo.fn_ReceivingDock_GetBackflushDetails.sql
*/

use FxAztec
go

if	objectproperty(object_id('dbo.fn_ReceivingDock_GetBackflushDetails'), 'IsTableFunction') = 1 begin
	drop function dbo.fn_ReceivingDock_GetBackflushDetails
end
go

create function dbo.fn_ReceivingDock_GetBackflushDetails
(	@BackflushNumber varchar(50)
)
returns @InventoryConsumption table
(	Serial int
,	PartCode varchar(25)
,	BOMLevel tinyint
,	Sequence tinyint
,	Suffix int
,	ChildPartSequence int
,	ChildPartBOMLevel int
,	BillOfMaterialID int
,	AllocationDT datetime
,	QtyPer float
,	QtyAvailable float
,	QtyRequired float
,	QtyIssue float
,	QtyOverage float
)
as
begin
--- <Body>
declare	
	@qtyRequested numeric(20,6)

set	@qtyRequested =
		(	select
				QtyProduced
			from
				dbo.BackflushHeaders
			where
				BackflushNumber = @BackflushNumber
		)

/*	Get the current material available to backflush. */
	declare	@MaterialAvailable table
	(	Serial int
	,	Part varchar (25)
	,	Sequence tinyint
	,	Suffix int
	,	AllocationDT datetime
	,	QtyAvailable float
	,	QtyOriginal float
	,	QtyPer float null
	,	unique
		(	Sequence
		,	Suffix
		,	Serial
		)
	)

	insert
		@MaterialAvailable
	(	Serial
	,	Part
	,	Sequence
	,	Suffix
	,	AllocationDT
	,	QtyOriginal
	,	QtyAvailable
	,	QtyPer)
	select
		Serial = oAvailable.Serial
	,	Part = oAvailable.part
	,	Sequence = xr.Sequence
	,	Suffix = 0
	,	AllocationDT = coalesce
		(	(	select
					max(atOutShip.date_stamp)
				from
					dbo.audit_trail atOutShip
				where
					atOutShip.Serial = oAvailable.Serial
					and atOutShip.type = 'O'
			)
		,	(	select
					max(atReceipt.date_stamp)
				from
					dbo.audit_trail atReceipt
				where
					atReceipt.Serial = oAvailable.Serial
					and atReceipt.type = 'R'
			)
		,	(	select
					max(atBreak.date_stamp)
				from
					dbo.audit_trail atBreak
				where
					atBreak.Serial = oAvailable.Serial
					and atBreak.type = 'B'
			)
		)
	,	QtyOriginal = null
	,	QtyAvailable = coalesce(oAvailable.std_quantity, 0)
	,	QtyPer = null
	from
		dbo.BackflushHeaders bh
		cross apply
		(	select top(1)
				at.vendor
			from
				dbo.audit_trail at
			where
				at.type = 'R'
				and at.serial = bh.SerialProduced
				and at.std_quantity > 0
			order by
				at.date_stamp desc
		) atRLast
		join FT.XRt xr
			on xr.TopPart = bh.PartProduced
			and xr.BOMLevel = 1
		join dbo.object oAvailable
			left join dbo.destination d
				on d.destination = oAvailable.location
			on oAvailable.part = xr.ChildPart
			and oAvailable.status in ('A', 'P')
			and oAvailable.std_quantity > 0
			and d.vendor = atRLast.vendor
	where
		bh.BackflushNumber = @BackflushNumber

/*	Get the job BOM. */
	declare	@XRt table
	(	Sequence smallint not null
	,	BillOfMaterialID int
	,	BOMLevel smallint
	,	ChildPart varchar (25)
	,	XQty float
	,	unique (Sequence)
	)

	insert
		@XRt
	(	Sequence
	,	BillOfMaterialID
	,	BOMLevel
	,	ChildPart
	,	XQty
	)
	select
		Sequence = xr.Sequence
	,	BillOfMaterialID = xr.BOMID
	,	BOMLevel = xr.BOMLevel
	,	ChildPart = xr.ChildPart
	,	XQty = xr.XQty * xr.XScrap
	from
		dbo.BackflushHeaders bh
		join FT.XRt xr
			on xr.TopPart = bh.PartProduced
			and xr.BOMLevel = 1
	where
		bh.BackflushNumber = @BackflushNumber

/*	Loop through bill of material levels and calculate issue quantities. */
	declare	@AllocInventory table
	(	ID int not null IDENTITY(1, 1) primary key
	,	Serial int
	,	Part varchar (25)
	,	BOMLevel tinyint
	,	Sequence tinyint
	,	Suffix tinyint
	,	ChildPartSequence int
	,	ChildPartBOMLevel int
	,	BillOfMaterialID int
	,	AllocationDT datetime
	,	QtyPer float
	,	QtyOriginal float
	,	QtyPriorAvailable float
	,	QtyPostAvailable float
	,	QtyAvailable float
	,	QtyRequired float
	,	QtyIssue float
	,	QtyOverage float
	,	unique
		(	Serial
		,	Suffix
		,	BillOfMaterialID
		)
	)

	declare	@BOMLevel int
	set	@BOMLevel = 0

	while
		@BOMLevel <=
		(	select
				max (BOMLevel)
			from
				@XRt
		) begin

/*		Build requirements. */
		insert
			@AllocInventory
		(	Serial
		,	Part
		,	BOMLevel
		,	Sequence
		,	Suffix
		,	BillOfMaterialID
		,	AllocationDT
		,	QtyPer
		,	QtyOriginal
		,	QtyPriorAvailable
		,	QtyPostAvailable
		,	QtyAvailable
		,	QtyRequired
		,	QtyIssue
		,	QtyOverage
		)
		select
			Serial = ma.Serial
		,	Part = XRt.ChildPart
		,	BOMLevel = XRt.BOMLevel
		,	Sequence = XRt.Sequence
		,	Suffix = coalesce (ma.Suffix, 0)
		,	BillOfMaterialID = XRt.BillOfMaterialID
		,	AllocationDT = ma.AllocationDT
		,	QtyPer = coalesce(ma.QtyPer, XRt.XQty)
		,	QtyOriginal = ma.QtyOriginal
		,	QtyPriorAvailable = 0
		,	QtyPostAvailable = 0
		,	QtyAvailable = ma.QtyAvailable
		,	QtyRequired = @QtyRequested * coalesce(ma.QtyPer, XRt.XQty)
		,	QtyIssue = 0
		,	QtyOverage = 0
		from
			@XRt XRt
			join @MaterialAvailable ma
				on XRt.Sequence = ma.Sequence
			join
			(	select
					Sequence
				,	AllocCount = count (1)
				from
					@MaterialAvailable ma2
				group by
					Sequence
			) TotalSequenceAllocations
				on XRt.Sequence = TotalSequenceAllocations.Sequence
			join
			(	select
					Serial = ma2.Serial
				,	TotalAllocated = sum(coalesce(ma2.QtyPer, XRt.XQty))
				from
					@XRt XRt
					left join @MaterialAvailable ma2
						on XRt.Sequence = ma2.Sequence
				group by
					ma2.Serial
			) TotalSerialAllocations
				on ma.Serial = TotalSerialAllocations.Serial
		where
			XRt.BOMLevel = @BOMLevel
		order by
			XRt.Sequence
		,	coalesce(ma.Suffix, 0)
		,	ma.AllocationDT

		update
			ai
		set	QtyPriorAvailable = QtyPriorAvailable + coalesce
			(	(	select
						sum(QtyAvailable)
					from
						@AllocInventory Inv1
					where
						ai.Sequence = Inv1.Sequence
						and ai.Suffix = Inv1.Suffix
						and ai.ID > Inv1.ID
				)
			,	0
			)
		,	QtyPostAvailable = coalesce
			(	(	select
						sum(QtyAvailable)
					from
						@AllocInventory Inv1
					where
						ai.Sequence = Inv1.Sequence
						and ai.Suffix = Inv1.Suffix
						and ai.ID < Inv1.ID
				)
			,	0
			)
		from
			@AllocInventory ai
		where
			BOMLevel = @BOMLevel

		update
			ai
		set	QtyIssue =
			case
				when QtyPriorAvailable > QtyRequired then 0
				when QtyPriorAvailable + QtyAvailable > QtyRequired then QtyRequired - QtyPriorAvailable
				else QtyAvailable
			end
		from
			@AllocInventory ai
		where
			BOMLevel = @BOMLevel

		update
			ai
		set	QtyOverage =
			case
				when QtyRequired < QtyIssue + QtyPriorAvailable then 0
				else QtyRequired - QtyIssue - QtyPriorAvailable
			end
		from
			@AllocInventory ai
		where
			BOMLevel = @BOMLevel and
			QtyPostAvailable = 0

		select	@BOMLevel = @BOMLevel + 1
	end
	
	insert
		@InventoryConsumption
	(	Serial
	,	PartCode
	,	BOMLevel
	,	Sequence
	,	Suffix
	,	ChildPartSequence
	,	ChildPartBOMLevel
	,	BillOfMaterialID
	,	AllocationDT
	,	QtyPer
	,	QtyAvailable
	,	QtyRequired
	,	QtyIssue
	,	QtyOverage
	)
	select
		Serial
	,	Part
	,	BOMLevel
	,	Sequence
	,	Suffix
	,	ChildPartSequence
	,	ChildPartBOMLevel
	,	BillOfMaterialID
	,	AllocationDT
	,	QtyPer
	,	QtyAvailable
	,	QtyRequired
	,	QtyIssue + QtyOverage
	,	QtyOverage
	from
		@AllocInventory ai
	
--- </Body>

---	<Return>
	return
end
go

