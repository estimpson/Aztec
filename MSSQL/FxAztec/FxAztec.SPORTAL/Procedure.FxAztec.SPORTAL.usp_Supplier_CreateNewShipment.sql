
/*
Create Procedure.FxAztec.SPORTAL.usp_Supplier_CreateNewShipment.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_Supplier_CreateNewShipment'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_Supplier_CreateNewShipment
end
go

create procedure SPORTAL.usp_Supplier_CreateNewShipment
	@SupplierCode varchar(20)
,	@CarrierCode varchar(4)
,	@TrackingNumber varchar(100)
,	@ShipperNumber varchar(50) out
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
---	</ArgumentValidation>

--- <Body>
--- <Insert rows="1">
set	@TableName = 'SPORTAL.SupplierShipments'

insert
	SPORTAL.SupplierShipments
(	SupplierCode
,	CarrierCode
,	TrackingNumber
)
select
	SupplierCode = @SupplierCode
,	CarrierCode = @CarrierCode
,	TrackingNumber = @TrackingNumber

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

set	@ShipperNumber =
	(	select
			ss.ShipperNumber
		from
			SPORTAL.SupplierShipments ss
		where
			ss.RowID = scope_identity()
	)
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
,	@CarrierCode varchar(4) = 'XXXX'
,	@TrackingNumber varchar(100) = '1Z123'
,	@ShipperNumber varchar(50)

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Supplier_CreateNewShipment
	@SupplierCode = @SupplierCode
,	@CarrierCode = @CarrierCode
,	@TrackingNumber = @TrackingNumber
,	@ShipperNumber = @ShipperNumber out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, ShipmentNumber = @ShipperNumber, @TranDT, @ProcResult

execute
	@ProcReturn = SPORTAL.usp_SupplierShipment_ChangeTrackingNumber
	@SupplierCode = @SupplierCode
,	@ShipperNumber = @ShipperNumber
,	@TrackingNumber = '1Z125'

execute
	@ProcReturn = SPORTAL.usp_SupplierShipment_ChangeCarrier
	@SupplierCode = @SupplierCode
,	@ShipperNumber = @ShipperNumber
,	@CarrierCode = 'ABCD'

execute
	@ProcReturn = SPORTAL.usp_Q_Shipments_BySupplier
	@SupplierCode = @SupplierCode
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

