SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_ReceiveObjects]
(	@User varchar (5),
	@PONumber integer,
	@PartCode varchar(25),
	@PackageType varchar(20),
	@PerBoxQty numeric (20,6),
	@NewObjects integer,
	@Shipper varchar (20),
	@LotNumber varchar (20),
	@SerialNumber integer out,
	@Location varchar(10) = null,
	@TranDT datetime out,
	@Result integer out)
as
/*
Initial queries {
select	*
from	employee
where	operator_code = 'ES'

select	po_detail.po_number, po_detail.part_number, po_detail.balance, PerBoxQty = (select standard_pack from part_inventory where part = part_number),
	po_detail.date_due, row_id
from	po_detail
	join po_header on po_header.po_number = po_detail.po_number
where	po_header.release_control != 'A' and
	po_detail.status = 'A' and
	po_detail.balance > 0 and
	po_detail.po_number = 3217 and
	po_detail.part_number = 'KSR0018-HB01'
order by
	po_detail.date_due

update	po_header
set	release_control = 'A'
where	po_number = 3217
}

Test syntax {
declare	@User varchar(5),
	@PONumber integer,
	@PartCode varchar(25),
	@PackageType varchar(20),
	@PerBoxQty numeric(20,6),
	@NewObjects integer,
	@Shipper varchar(20),
	@LotNumber varchar(20),
	@FirstNewSerial int,
	@TranDT datetime

set	@User = 'ES'
set	@PONumber = 3217
set	@PartCode = 'KSR0018-HB01'
set	@PackageType = null
set	@PerBoxQty = 275
set	@NewObjects = 8800/275
set	@Shipper = 'Test123'
set	@LotNumber = '123'

select	po_detail.po_number, po_detail.part_number, po_detail.balance, PerBoxQty = (select standard_pack from part_inventory where part = part_number),
	po_detail.date_due, row_id,
	received,
	standard_qty,
	last_recvd_date,
	last_recvd_amount
from	po_detail
where	po_number = @PONumber
order by
	date_due

begin transaction ReceiveObjects_againstLineItem

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

execute	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObjects
	@User = @User,
	@PONumber = @PONumber,
	@PartCode = @PartCode,
	@PackageType = @PackageType,
	@PerBoxQty = @PerBoxQty,
	@NewObjects = @NewObjects,
	@Shipper = @Shipper,
	@LotNumber = @LotNumber,
	@SerialNumber = @FirstNewSerial out,
	@TranDT = @TranDT out,
	@Result = @ProcResult out

set	@Error = @@error

select	ProcReturn = @ProcReturn, ProcResult = @ProcResult, Error = @Error, Serials = @NewObjects, NewSerial = @FirstNewSerial, TranDateTime = @TranDT, NextSerial = next_serial
from	parameters

select	*
from	object
where	serial between @FirstNewSerial and @FirstNewSerial + @NewObjects

select	*
from	audit_trail
where	serial between @FirstNewSerial and @FirstNewSerial + @NewObjects

select	po_detail.po_number, po_detail.part_number, po_detail.balance, PerBoxQty = (select standard_pack from part_inventory where part = part_number),
	po_detail.date_due, row_id,
	received,
	standard_qty,
	last_recvd_date,
	last_recvd_amount
from	po_detail
where	po_number = @PONumber
order by
	date_due

rollback
}

Results {
See dbo.usp_ReceivingDock_ReceiveObjects_againstLineItem.sql or
dbo.usp_ReceivingDock_ReceiveObjects_againstBlanketPO.sql
}
*/
set ansi_warnings off
set nocount on
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran required=Yes autoCreate=Yes tranDTParm=Yes>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

declare	@NewSerial int
if exists
(	select	1
	from	po_header
	where	po_number = @PONumber and
		release_control = 'A')
begin
	--- <Call>	
	set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObjects_againstBlanketPO'
	execute	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObjects_againstBlanketPO
		@User = @User,
		@PONumber = @PONumber,
		@PartCode = @PartCode,
		@PackageType = @PackageType,
		@PerBoxQty = @PerBoxQty,
		@NewObjects = @NewObjects,
		@Shipper = @Shipper,
		@LotNumber = @LotNumber,
		@Location = @Location,
		@SerialNumber = @SerialNumber out,
		@TranDT = @TranDT out,
		@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end
else
begin
	--- <Call>
	set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObjects_againstLineItem'
	execute	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObjects_againstLineItem
		@User = @User,
		@PONumber = @PONumber,
		@PartCode = @PartCode,
		@PackageType = @PackageType,
		@PerBoxQty = @PerBoxQty,
		@NewObjects = @NewObjects,
		@Shipper = @Shipper,
		@LotNumber = @LotNumber,
		@Location = @Location,
		@SerialNumber = @SerialNumber out,
		@TranDT = @TranDT out,
		@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	II.	Return.
set	@Result = 0
return	@Result
GO
