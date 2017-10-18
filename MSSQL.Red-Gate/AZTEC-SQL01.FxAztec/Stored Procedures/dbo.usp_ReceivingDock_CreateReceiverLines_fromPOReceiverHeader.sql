SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[usp_ReceivingDock_CreateReceiverLines_fromPOReceiverHeader]
	@ReceiverID int,
	@Result int output
as
/*

begin tran Test
declare
	@ReceiverID int

set @ReceiverID = 1

execute	usp_ReceivingDock_CreateReceiverLines_fromPOReceiverHeader
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

--	Argument transformations:
--		Supplier, expected / actual receive DT.
declare
	@ShipFrom varchar (10)
,	@ReceiveDT datetime

select
	@ShipFrom = rh.ShipFrom
,	@ReceiveDT = coalesce(rh.ReceiveDT, rh.ActualArrivalDT, rh.ConfirmedArrivalDT, rh.ExpectedReceiveDT)
from
	dbo.ReceiverHeaders rh
where
	rh.ReceiverID = @ReceiverID

if	@ReceiveDT is null begin
	rollback tran @ProcName
	set	@Result = 1000004
	raiserror ('Unable to create lines for Receiver %d.  Please set the expected arrival date.', 16, 1, @ReceiverID)
	return @Result
end

--		Prior expected / actual receive DT.
declare
	@PriorReceiveDT datetime

select
	@PriorReceiveDT = max (coalesce(ReceiveDT, ActualArrivalDT, ConfirmedArrivalDT, ExpectedReceiveDT))
from
	ReceiverHeaders
where
	ShipFrom = @ShipFrom
	and
		coalesce(ReceiveDT, ActualArrivalDT, ConfirmedArrivalDT, ExpectedReceiveDT) < @ReceiveDT
	and
		Status < dbo.udf_StatusValue ('ReceiverHeaders', 'Put Away')

--	Calculate new receiver lines...
--		See what's on po_detail.
declare
	@Requirements table
(	ReceiverID int,
	PartCode varchar(25),
	PONumber integer,
	POLineNo integer,
	POLineDueDate datetime,
	PackageType varchar(20),
	POBalance numeric(20,6),
	StdPackQty numeric(20,6))

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
	pd.date_due <= @ReceiveDT
	and
		(
			pd.date_due > @PriorReceiveDT
			or
				@PriorReceiveDT is null
		)
	and
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
		,	Boxes = ceiling(r.POBalance / r.StdPackQty)
		,	r.StdPackQty
		from
			@Requirements r
		where
			ceiling(r.POBalance / r.StdPackQty) > 0
	) Requirements
order by
	PartCode
,	PONumber
,	POLineNo
,	Boxes desc

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

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
	RemainingBoxes = rl2.Boxes
,	StdPackQty = rl2.StdPackQty
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
	rl.Boxes,
	rl.StdPackQty
from
	#ReceiverLines rl
where
	not exists
	(	select
			*
		from
			dbo.ReceiverLines rl2
		where
			rl.ReceiverID = rl2.ReceiverID
			and
				rl.PartCode = rl2.PartCode
			and
				rl.PONumber = rl2.PONumber
			and
				rl.POLineNo = rl2.POLineNo
			and
				rl.POLineDueDate = rl2.POLineDueDate
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
,	[LineNo] = r.RowNumber
,	rl.Status
,	rl.PONumber
,	rl.POLineNo
,	rl.POLineDueDate
,	rl.PartCode
,	PartDescription = null
,	EngineeringLevel = p.engineering_level
,	rl.StdPackQty
,	rl.PackageType
,	coalesce((case coalesce(p.class, 'N') when 'N' then '' else pi.primary_location end),'')
,	l.plant
,	p.gl_account_code
,	pp.gl_account_code
from
	dbo.ReceiverLines rl
	join dbo.udf_Rows(1000) r on
		r.RowNumber <= rl.RemainingBoxes
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
