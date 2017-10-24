
/*
Create Procedure.FxAztec.SPORTAL.usp_SupplierShipment_ChangeCarrier.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_SupplierShipment_ChangeCarrier'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_SupplierShipment_ChangeCarrier
end
go

create procedure SPORTAL.usp_SupplierShipment_ChangeCarrier
	@SupplierCode varchar(20)
,	@ShipperNumber varchar(50)
,	@CarrierCode varchar(4)
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings off
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SPORTAL.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
/*	Valid supplier code. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierList sl
		where
			sl.SupplierCode = @SupplierCode
			and sl.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier code %s in procedure %s', 16, 1, @SupplierCode, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid shipper. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierShipments ss
		where
			ss.SupplierCode = @SupplierCode
			and ss.ShipperNumber = @ShipperNumber
			and ss.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid shipper %s for supplier code %s in procedure %s', 16, 1, @ShipperNumber, @SupplierCode, @ProcName)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Change tracking number. */
--- <Update rows="1">
set	@TableName = 'SPORTAL.SupplierShipments'

update
	ss
set
	ss.CarrierCode = @CarrierCode
from
	SPORTAL.SupplierShipments ss
where
	ss.SupplierCode = @SupplierCode
	and ss.ShipperNumber = @ShipperNumber
	and ss.Status = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@SupplierCode varchar(20) = 'MAR0200'
,	@ShipperNumber varchar(50) = 'SS_000000000'
,	@CarrierCode varchar(100) = 'ABCD'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_SupplierShipment_ChangeCarrier
	@SupplierCode = @SupplierCode
,	@ShipperNumber = @ShipperNumber
,	@CarrierCode = @CarrierCode
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
go

