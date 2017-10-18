SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_CreateReceiverLines_fromOutPReceiverHeader]
	@ReceiverID int,
	@Result int output
as
/*
select
	*
from
	dbo.ReceiverHeaders rh

begin tran Test
declare
	@ReceiverID int

set @ReceiverID = 10

execute	usp_ReceivingDock_CreateReceiverLines_fromOutPReceiverHeader
	@ReceiverID = @ReceiverID,
	@Result = 0
	
select	*
from	ReceiverLines

select	ReceiverLineID,
	ReceiverID,
	[LineNo],
	PartCode,
	PONumber,
	POLineNo,
	POLineDueDate,
	PackageType,
	RemainingBoxes,
	StdPackQty,
	TotalReceiveQty = convert (numeric(20,6), null),
	TotalOnOrderQty =
	(	select	balance
		from	dbo.po_detail po_detail
		where	po_detail.part_number = ReceiverLines.PartCode and
			po_detail.po_number = ReceiverLines.PONumber and
			po_detail.row_id = ReceiverLines.POLineNo and
			po_detail.date_due = ReceiverLines.POLineDueDate),
	SupplierLotNumber,
	ArrivalDT
from	dbo.ReceiverLines ReceiverLines
where	ReceiverID = @ReceiverID

select	ro.*
from	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl on ro.ReceiverLineID = rl.ReceiverLineID
where	rl.ReceiverID = @ReceiverID

--commit
rollback tran


*/
set ansi_warnings off
set nocount on
set	@Result = 999999

--- <ErrorHandling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </ErrorHandling>

--- <Tran required=Yes autoCreate=Yes tranDTParm=No>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--	Constants:
declare
	@ATPROCESSOR_OBJECT_STATUS char(1); set @ATPROCESSOR_OBJECT_STATUS = 'P'

--	Argument transformations:
--		Supplier, expected / actual receive DT.
declare
	@ShipFrom varchar (20)
,	@VendorCode varchar (10)
,	@ReceiveDT datetime

select
	@ShipFrom = rh.ShipFrom
,	@VendorCode = d.vendor
,	@ReceiveDT = coalesce(rh.ReceiveDT, rh.ActualArrivalDT, rh.ConfirmedArrivalDT, rh.ExpectedReceiveDT)
from
	dbo.ReceiverHeaders rh
	join dbo.destination d on
		d.destination = rh.ShipFrom
where
	rh.ReceiverID = @ReceiverID

if	@ReceiveDT is null begin
	rollback tran @ProcName
	set	@Result = 1000004
	raiserror ('Unable to create lines for Receiver %d.  Please set the expected arrival date.', 16, 1, @ReceiverID)
	return @Result
end

--	Calculate new receiver lines...
--		Calculate the expected quantity based on material at the outside processor.
declare
	@ExpectedReceiptQty table
(
	ParentPart varchar(25) primary key
,	ExpectedQty numeric(20,6) null
)

--- <Insert>
set	@TableName = '@ExpectedReceiptQty'

insert
	@ExpectedReceiptQty
select
	ParentPart
,	ExpectedQty = sum(ParentOnHandQty)
from
	(
		select
			VendorCode = pv.vendor
		,	ParentPart = bom.parent_part
		,	ChildPart = bom.part
		,	ParentOnHandQty = coalesce (ProcessorBOMInventory.OnHandQty, 0) / nullif (bom.std_qty, 0)
		from
			dbo.bill_of_material bom
			join dbo.part_vendor pv
				join dbo.destination d
					on d.vendor = pv.vendor
				on bom.parent_part = pv.part
			left join
			(	select
					ChildPart = o.part
				,	Location = o.location
				,	OnHandQty = sum(std_quantity)
				from
					dbo.object o
				group by
					o.part
				,	o.location
			) ProcessorBOMInventory on
				bom.part = ProcessorBOMInventory.ChildPart
				and d.destination like ProcessorBOMInventory.Location + '%'
		where
			pv.vendor = @VendorCode
	) ExpectedProcessorReceipts
where
	VendorCode = @VendorCode
group by
	ParentPart

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--		See what's on po_detail.
declare
	@Requirements table
(	ReceiverID int
,	PartCode varchar(25)
,	PONumber integer
,	POLineNo integer
,	POLineDueDate datetime
,	PackageType varchar(20)
,	POBalance numeric(20, 6)
,	StdPackQty numeric(20, 6)
)
--- <Insert>
set	@TableName = '@Requirements'

insert
	@Requirements
(	ReceiverID,
	PartCode,
	PONumber,
	POLineNo,
	POLineDueDate,
	PackageType,
	POBalance,
	StdPackQty)
select
	ReceiverID = @ReceiverID,
	PartCode = pd.part_number,
	PONumber = pd.po_number,
	POLineNo = pd.row_id,
	POLineDueDate = pd.date_due,
	PackageType =
	(	select
			min(part_packaging.code)
		from
			dbo.part_packaging part_packaging
		where
			part_packaging.part = pd.part_number
		and	part_packaging.quantity = PartSupplierStdPack.StdPack),
	POBalance = pd.balance,
	StdPackQty = coalesce(PartSupplierStdPack.StdPack, pd.balance)
from
	dbo.po_detail pd
		join dbo.po_header ph on
			pd.po_number = ph.po_number
		join dbo.destination d on
			d.destination = @ShipFrom
			and
				d.vendor = pd.vendor_code
	left join
	(	select
			Part = p.part,
			SupplierCode = pv.vendor,
			StdPack = coalesce (nullif(pv.vendor_standard_pack, 0.0), nullif(pi.standard_pack, 0.0), -1)
		from
			dbo.part p
			left join dbo.part_inventory pi on
				p.part = pi.part
			left join dbo.part_vendor pv on
				p.part = pv.part
	) PartSupplierStdPack on
		pd.part_number = PartSupplierStdPack.Part
		and
			pd.vendor_code = PartSupplierStdPack.SupplierCode
where
	pd.balance > 0

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--		Load to temp table to generate line no's.
--- <Insert>
set	@TableName = '#ReceiverLines'

select
	ReceiverID
,	[LineNo] = identity(int, 1, 1)
,	PartCode
,	PONumber
,	POLineNo
,	POLineDueDate
,	PackageType
,	Boxes
,	StdPackQty
,	PriorAccum = convert(numeric(20,6), 0)
,	PostAccum = convert(numeric(20,6), 0)
into
	#ReceiverLines
from
	(
		select
			r.ReceiverID
		,	r.PartCode
		,	r.PONumber
		,	r.POLineNo
		,	r.POLineDueDate
		,	r.PackageType
		,	Boxes = 1
		,	StdPackQty = ceiling(r.POBalance)
		from
			@Requirements r
			join @ExpectedReceiptQty erq on
				r.PartCode = erq.ParentPart
		where
			r.POBalance > 0
	) Requirements
order by
	PartCode
,	PONumber
,	POLineNo
,	Boxes desc

--- <Update>
set	@TableName = '#ReceiverLines'

update
	#ReceiverLines
set
	PostAccum =
		(	select
				sum(Boxes * StdPackQty)
			from
				#ReceiverLines rl2
			where
				PartCode = rl.PartCode
				and
					[LineNo] <= rl.[LineNo]
		)
from
	#ReceiverLines rl

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--- <Update>
set	@TableName = '#ReceiverLines'

update
	#ReceiverLines
set
	PriorAccum = PostAccum - (Boxes * StdPackQty)

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--	Recalculate Receiver Objects and Receiver Lines.
--		Remove old receiver objects (not yet received against).
--- <Delete>
set	@TableName = 'dbo.ReceiverObjects'

delete
	dbo.ReceiverObjects
from
	dbo.ReceiverObjects rlo
		join dbo.ReceiverLines rl on
			rlo.ReceiverLineID = rl.ReceiverLineID
		and rl.ReceiverID = @ReceiverID
where
	 rlo.Status = 0	

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Delete>

--		Remove old receiver line (not yet received against).
--- <Delete>
set	@TableName = 'dbo.ReceiverLines'

delete
	dbo.ReceiverLines
from
	dbo.ReceiverLines rl
where
	ReceiverID = @ReceiverID
and
	not exists
	(	select
			*
		from
			dbo.ReceiverObjects ro
		where
			ReceiverLineID = rl.ReceiverLineID)

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Delete>

--		Set quantity remaining on lines that have been partially received.
--- <Update>
set	@TableName = 'dbo.part_vendor'

update
	dbo.ReceiverLines
set
	RemainingBoxes =
		case
			when erq.ParentPart is null then 0
			else 1
		end
,	StdPackQty =
		case
			when erq.ParentPart is null then 0
			when rl2.PostAccum > erq.ExpectedQty then ceiling (erq.ExpectedQty - rl2.PriorAccum)
			else rl2.StdPackQty
		end
,	[LineNo] =
		(	select
				count(1)
			from
				dbo.ReceiverLines
			where
				ReceiverID = @ReceiverID
			and
				[LineNo] <= rl.[LineNo]
		)
from
	dbo.ReceiverLines rl
	join #ReceiverLines rl2 on
		rl.PartCode = rl2.PartCode
		and
			rl.PONumber = rl2.PONumber
		and
			rl.POLineNo = rl2.POLineNo
		and
			rl.POLineDueDate = rl2.POLineDueDate
	left join @ExpectedReceiptQty erq on
		rl.PartCode = erq.ParentPart
		and
			rl2.PriorAccum < erq.ExpectedQty
where
	rl.ReceiverID = @ReceiverID

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--		Create new receiver lines.
--- <Insert>
set	@TableName = 'dbo.ReceiverLines'

insert
	dbo.ReceiverLines
(	ReceiverID,
	[LineNo],
	PartCode,
	PONumber,
	POLineNo,
	POLineDueDate,
	PackageType,
	RemainingBoxes,
	StdPackQty)
select
	rl.ReceiverID,
	rl.[LineNo] + coalesce(
		(	select
				max([LineNo])
			from
				dbo.ReceiverLines
			where
				ReceiverID = @ReceiverID), 0
		),
	rl.PartCode,
	rl.PONumber,
	rl.POLineNo,
	rl.POLineDueDate,
	rl.PackageType,
	RemainingBoxes = 1,
	StdPackQty =
		case
			when rl.PostAccum > erq.ExpectedQty then ceiling(erq.ExpectedQty - rl.PriorAccum)
			else rl.Boxes
		end
from
	#ReceiverLines rl
	join @ExpectedReceiptQty erq on
		rl.PartCode = erq.ParentPart
		and
			rl.PriorAccum < erq.ExpectedQty
where
	not exists
	(	select
			*
		from
			dbo.ReceiverLines rl2
		where
			rl.PartCode = rl2.PartCode
			and
				rl.PONumber = rl2.PONumber
			and
				rl.POLineNo = rl2.POLineNo
			and
				rl.POLineDueDate = rl2.POLineDueDate
			and
				rl2.ReceiverID = @ReceiverID
	)


select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--		Done with temporary receiver lines.
drop table #ReceiverLines

--		Create new receiver objects.
--- <Insert>
set	@TableName = 'dbo.ReceiverLines'

insert
	dbo.ReceiverObjects
(	ReceiverLineID
,	[LineNo]
,	Status
,	PONumber
,	POLineNo
,	POLineDueDate
,	PartCode
,	PartDescription
,	EngineeringLevel
,	QtyObject
,	PackageType
,	Location
,	Plant
,	DrAccount
,	CrAccount)
select
	rl.ReceiverLineID
,	[LineNo] = coalesce
	(	(	select
				max([LineNo]) + 1
			from
				dbo.ReceiverObjects
			where
				ReceiverLineID = rl.ReceiverLineID
		)
	,	1
	)
,	rl.Status
,	rl.PONumber
,	rl.POLineNo
,	rl.POLineDueDate
,	rl.PartCode
,	PartDescription = null
,	EngineeringLevel = p.engineering_level
,	rl.RemainingBoxes
,	rl.PackageType
,	coalesce(case coalesce(p.class, 'N') when 'N' then '' else pi.primary_location end, 'N/S')
,	l.plant
,	p.gl_account_code
,	pp.gl_account_code
from
	dbo.ReceiverLines rl
	left join dbo.part p on rl.PartCode = p.part
	left join dbo.part_inventory pi on rl.PartCode = pi.part
	left join dbo.location l on pi.primary_location = l.code
	left join dbo.part_purchasing pp on rl.PartCode = pp.part
where
	rl.ReceiverID = @ReceiverID

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--- <CloseTran required=Yes autoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran>

---	<Return success=True>
set	@Result = 0
return	@Result
--- </Return>
GO
