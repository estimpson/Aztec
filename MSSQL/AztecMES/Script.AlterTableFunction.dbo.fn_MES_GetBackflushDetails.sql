
declare
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
,	@QtyRequested numeric(20,6)

set	@WorkOrderNumber = 'WO_0000000001'
set	@WorkOrderDetailLine = 1
set @QtyRequested = 40

declare
	@WODID int

select
	@WODID = wod.RowID
from
	dbo.WorkOrderDetails wod
where
	wod.WorkOrderNumber = @WorkOrderNumber
	and wod.Line = @WorkOrderDetailLine

declare
	@InventoryConsumption table
(
	Serial int
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

begin
--- <Body>
/*	Get the current inventory allocations. */
	declare	@MaterialAllocations table
	(	Serial int
	,	Part varchar (25)
	,	Sequence tinyint
	,	Suffix int
	,	AllocationDT datetime
	,	QtyAvailable float
	,	QtyOriginal float
	,	QtyPer float null
	,	unique
		(
			Sequence
		,	Suffix
		,	Serial
		)
	)

	insert
		@MaterialAllocations
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
	,	Part = wodbom.ChildPart
	,	Sequence = wodbom.ChildPartSequence
	,	Suffix = coalesce (wodbom.Suffix, 0)
	,	AllocationDT = coalesce
		(	(	select
					max(atTransfer.date_stamp)
				from
					dbo.audit_trail atTransfer
				where
					atTransfer.Serial = oAvailable.Serial
					and atTransfer.type = 'T'
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
	,	QtyAvailable = coalesce(oAvailable.QtyAvailable, 0)
	,	QtyPer = wodbom.QtyPer
	from
		(	select
				Serial = o.serial
			,	PartCode = o.part
			,	LocationCode = o.location
			,	QtyAvailable = o.std_quantity
			from
				dbo.object o
			where
				o.status = 'A'
		) oAvailable
		left join dbo.MES_SetupBackflushingPrinciples msbp
			on msbp.Type = 3
			and msbp.ID = oAvailable.PartCode
		left join dbo.MES_StagingLocations msl
			on msbp.BackflushingPrinciple = 3 --StagingLocation
			and msl.PartCode = oAvailable.PartCode
			and msl.StagingLocationCode = oAvailable.LocationCode
		left join dbo.location lGroupTechActive
			join dbo.location lGroupMachines
				on lGroupTechActive.group_no = lGroupMachines.group_no
			on msbp.BackflushingPrinciple = 4 --GroupTechnology (sequence)
			and lGroupTechActive.code = oAvailable.LocationCode
			and lGroupTechActive.sequence > 0
		join dbo.machine m
			on m.machine_no = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
		join dbo.WorkOrderDetails wod
			join dbo.WorkOrderDetailBillOfMaterials wodbom
				on wod.WorkOrderNumber = wodbom.WorkOrderNumber
				and wod.Line = wodbom.WorkOrderDetailLine
			join dbo.WorkOrderHeaders woh
				on woh.WorkOrderNumber = wod.WorkOrderNumber
			on wod.RowID = @WODID
			and wodbom.ChildPart = oAvailable.PartCode
			and woh.MachineCode = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)

/*	Get the job BOM. */
	declare	@XRt table
	(
		Sequence smallint not null
	,	BillOfMaterialID int
	,	BOMLevel smallint
	,	ChildPart varchar (25)
	,	XQty float
	,	unique (Sequence)
	)

	insert
		@XRt
	(
		Sequence
	,	BillOfMaterialID
	,	BOMLevel
	,	ChildPart
	,	XQty
	)
	select
		wodbom.ChildPartSequence
	,	wodbom.BillOfMaterialID
	,	wodbom.ChildPartBOMLevel
	,	wodbom.ChildPart
	,	wodbom.XQty
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
	where
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and
			wodbom.WorkOrderDetailLine = @WorkOrderDetailLine

/*	Loop through bill of material levels and calculate issue quantities. */
	declare	@AllocInventory table
	(
		Serial int
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
		(
			Serial
		,	Suffix
		,	BillOfMaterialID
		)
	)

	declare	@BOMLevel int
	set	@BOMLevel = 0

	while	@BOMLevel <=
		(	select	max (BOMLevel)
			from	@XRt) begin

/*		Build requirements. */
		insert	@AllocInventory
		(
			Serial
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
		,	QtyOverage)
		select
			Serial = ma.Serial
		,	Part = XRt.ChildPart
		,	BOMLevel = XRt.BOMLevel
		,	Sequence = XRt.Sequence
		,	Suffix = coalesce (ma.Suffix, 0)
		,	BillOfMaterialID = XRt.BillOfMaterialID
		,	AllocationDT = ma.AllocationDT
		,	QtyPer = coalesce
			(	ma.QtyPer
			,	XRt.XQty / TotalSequenceAllocations.AllocCount
			)
		,	QtyOriginal = ma.QtyOriginal
		,	QtyPriorAvailable = 0
		,	QtyPostAvailable = 0
		,	QtyAvailable = ma.QtyAvailable * Coalesce (ma.QtyPer, XRt.XQty / TotalSequenceAllocations.AllocCount) / TotalSerialAllocations.TotalAllocated
		,	QtyRequired = @QtyRequested * Coalesce (ma.QtyPer, XRt.XQty / TotalSequenceAllocations.AllocCount)
		,	QtyIssue = 0
		,	QtyOverage = 0
		from
			@XRt XRt
			join
				@MaterialAllocations ma on
				XRt.Sequence = ma.Sequence
			join
			(
				select
					Sequence
				,	AllocCount = count (1)
				from
					@MaterialAllocations ma2
				group by
					Sequence
			) TotalSequenceAllocations on
				XRt.Sequence = TotalSequenceAllocations.Sequence
			join
			(
				select
					Serial = ma2.Serial
				,	TotalAllocated = sum(coalesce(ma2.QtyPer, XRt.XQty))
				from
					@XRt XRt
					left join @MaterialAllocations ma2 on
						XRt.Sequence = ma2.Sequence
				group by
					ma2.Serial) TotalSerialAllocations on
				ma.Serial = TotalSerialAllocations.Serial
		where
			XRt.BOMLevel = @BOMLevel
		order by
			XRt.Sequence
		,	ma.AllocationDT

		update
			ai
		set	QtyPriorAvailable = QtyPriorAvailable + coalesce
			(
				(
					select
						sum(QtyAvailable)
					from
						@AllocInventory Inv1
					where
						ai.Sequence = Inv1.Sequence
						and
							ai.Suffix = Inv1.Suffix
						and
							ai.AllocationDT > Inv1.AllocationDT
				)
			,	0
			)
		,	QtyPostAvailable = coalesce
			(
				(
					select
						sum(QtyAvailable)
					from
						@AllocInventory Inv1
					where
						ai.Sequence = Inv1.Sequence
						and
							ai.Suffix = Inv1.Suffix
						and
							ai.AllocationDT < Inv1.AllocationDT
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
	,	QtyOverage)
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
	,	QtyIssue
	,	QtyOverage
	from
		@AllocInventory
	
--- </Body>

---	<Return>
	select
		*
	from
		@InventoryConsumption
end
go
