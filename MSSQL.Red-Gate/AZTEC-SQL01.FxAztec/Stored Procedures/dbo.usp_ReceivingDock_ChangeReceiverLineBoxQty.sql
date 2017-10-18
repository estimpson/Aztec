SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[usp_ReceivingDock_ChangeReceiverLineBoxQty]
(	@User varchar (5),
	@ReceiverLineBoxID int,
	@QtyBox numeric(20,6),
	@Result integer out)
as
/*
Example:
Initial queries {
}

Test syntax {
declare	@User varchar (5),
	@ReceiverLineBoxID int,
	@TranDT datetime

set	@User = 'ES'
set	@ReceiverLineBoxID = 1

begin transaction ReceiveObject

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

execute	@ProcReturn = dbo.usp_ReceivingDock_ChangeReceiverLineBoxQty
	@User = @User,
	@ReceiverLineBoxID = @ReceiverLineBoxID,
	@TranDT = @TranDT out,
	@Result = @ProcResult out

set	@Error = @@error

select	@ProcReturn, @ProcResult

select	*
from	dbo.ReceiverLineBoxes ReceiverLineBoxes
	join dbo.object object on object.serial = ReceiverLineBoxes.Serial
where	ReceiverLineBoxes.ReceiverLineBoxID = @ReceiverLineBoxID

select	*
from	dbo.ReceiverLineBoxes ReceiverLineBoxes
	join dbo.audit_trail audit_trail on audit_trail.serial = ReceiverLineBoxes.Serial
where	ReceiverLineBoxes.ReceiverLineBoxID = @ReceiverLineBoxID

rollback
}

Results {
See below...
}
*/
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
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

declare	@PONumber integer,
	@PartCode varchar(25),
	@PackageType varchar(20),
	@PerBoxQty numeric (20,6),
	@NewObjects integer,
	@Shipper varchar (20),
	@LotNumber varchar (20),
	@SerialNumber integer

--	Argument Validation:
--		ReceiverLineBoxID is valid and not received.
if	(	select	ReceiverLineBoxStatus
		from	dbo.ReceiverLineBoxes
		where	ReceiverLineBoxID = @ReceiverLineBoxID) != dbo.udf_StatusValue ('ReceiverLineBoxes', 'New') begin
	set	@ProcResult = 1000007
	RAISERROR ('Error encountered in %s.  Validation: ReceiverLineBoxID %d is already received.', 16, 1, @ProcName, @ReceiverLineBoxID)
	rollback tran @ProcName
	return	@ProcResult
end

select	@PONumber = ReceiverLines.PONumber,
	@PartCode = ReceiverLines.PartCode,
	@PerBoxQty = ReceiverLines.PerBoxQty,
	@NewObjects = 1,
	@Shipper = ReceiverHeaders.SupplierSID,
	@LotNumber = ReceiverLineBoxes.Lot,
	@SerialNumber = ReceiverLineBoxes.Serial
from	dbo.ReceiverLineBoxes
	join dbo.ReceiverLines on dbo.ReceiverLineBoxes.ReceiverLineID = dbo.ReceiverLines.ReceiverLineID
	join dbo.ReceiverHeaders on dbo.ReceiverLines.ReceiverID = dbo.ReceiverHeaders.ReceiverID
where	ReceiverLineBoxID = @ReceiverLineBoxID and
	ReceiverLineBoxes.ReceiverLineBoxStatus = dbo.udf_StatusValue ('ReceiverLineBoxes', 'New')

if	@@RowCount != 1 begin
	set	@ProcResult = 1000008
	RAISERROR ('Error encountered in %s.  Validation: ReceiverLineBoxID %d not found or invalid.', 16, 1, @ProcName, @ReceiverLineBoxID)
	rollback tran @ProcName
	return	@ProcResult
end

--	

---<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
---</CloseTran>

---<Return ReturnValuu=success>
set	@Result = 0
return	@Result
---</Return>

GO
