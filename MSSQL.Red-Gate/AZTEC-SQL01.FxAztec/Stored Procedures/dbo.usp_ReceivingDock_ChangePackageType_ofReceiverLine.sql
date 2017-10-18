SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_ChangePackageType_ofReceiverLine]
(	@ReceiverLineID int,
	@PackageType varchar(25),
	@Result int output)
as
/*

begin tran Test
select
	*
from
	dbo.ReceiverLines rl
	join dbo.ReceiverObjects ro on
		rl.ReceiverLineID = ro.ReceiverLineID
where
	rl.ReceiverLineID = 163

execute	dbo.usp_ReceivingDock_ChangePackageType_ofReceiverLine
	@ReceiverLineID = 163,
	@PackageType = 'SC12124',
	@Result = 0
	
select
	*
from
	dbo.ReceiverLines rl
	join dbo.ReceiverObjects ro on
		rl.ReceiverLineID = ro.ReceiverLineID
where
	rl.ReceiverLineID = 163

--commit
rollback tran Test

*/
set nocount on
set	@Result = 999999

--- <Error Handling>
declare
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes>
declare
	@TranCount smallint
set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
--- </Tran>

--	Argument transformations:
--	Get remaining quantity.
declare
	@RemainingBalance numeric(20,6)

set
	@RemainingBalance =
	(	select
			balance
		from
			dbo.po_detail pod
			join dbo.ReceiverLines rl on
				pod.po_number = rl.PONumber
			and
				pod.part_number = rl.PartCode
			and
				pod.row_id = rl.POLineNo
			and
				pod.date_due = rl.POLineDueDate
		where
			ReceiverLineID = @ReceiverLineID)

--	Set std pack qty.
declare
	@StdPackQty numeric(20,6)

update
	dbo.ReceiverLines
set	PackageType = @PackageType,
	StdPackQty = coalesce(
	(	select
			quantity
		from
			dbo.part_packaging pp
		where
			part = dbo.ReceiverLines.PartCode
			and
				code = @PackageType),
	(	select
			StdPack = coalesce (nullif(pv.vendor_standard_pack, 0.0), nullif(pi.standard_pack, 0.0), -1)
		from
			dbo.part p
			left join dbo.part_inventory pi on
				p.part = pi.part
			left join dbo.part_vendor pv on
				p.part = pv.part
		where
			p.part = dbo.ReceiverLines.PartCode))
where
	dbo.ReceiverLines.ReceiverLineID = @ReceiverLineID

update
	dbo.ReceiverLines
set
	RemainingBoxes = ceiling(@RemainingBalance / StdPackQty)
where
	dbo.ReceiverLines.ReceiverLineID = @ReceiverLineID

--	Delete any non-received boxes.
delete
	dbo.ReceiverObjects
where
	ReceiverLineID = @ReceiverLineID
	and
		Status = 0

--	Renumber any received boxes.
update
	dbo.ReceiverObjects
set
	[LineNo] =
	(	select
			count(1)
		from
			dbo.ReceiverObjects ro2
		where
			ReceiverLineID = @ReceiverLineID
			and
				[LineNo] <= dbo.ReceiverObjects.[LineNo])
where
	ReceiverLineID = @ReceiverLineID

--	Re-insert remaining objects.
insert
	dbo.ReceiverObjects
(	ReceiverLineID
,	[LineNo]
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
,	[LineNo] = ObjectRows.RowNumber + coalesce(
	(	select
			max([LineNo])
		from
			dbo.ReceiverObjects ro2
		where
			ReceiverLineID = @ReceiverLineID), 0)
,	PONumber = rl.PONumber
,	POLineNo = rl.POLineNo
,	POLineDueDate = rl.POLineDueDate
,	PartCode = rl.PartCode
,	PartDescription = null
,	EngineeringLevel = p.engineering_level
,	QtyObject = rl.StdPackQty
,	PackageType = rl.PackageType
,	Location = pi.primary_location
,	Plant = l.plant
,	DrAccount = p.gl_account_code
,	CrAccount = pp.gl_account_code
from
	dbo.ReceiverLines rl
	join dbo.udf_Rows(1000) ObjectRows on
		ObjectRows.RowNumber <= rl.RemainingBoxes
	left join dbo.part p on rl.PartCode = p.part
	left join dbo.part_inventory pi on rl.PartCode = pi.part
	left join dbo.location l on pi.primary_location = l.code
	left join dbo.part_purchasing pp on rl.PartCode = pp.part
where
	rl.ReceiverLineID = @ReceiverLineID

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

---	<Return>
set	@Result = 0
return	@Result
--- </Return>
GO
