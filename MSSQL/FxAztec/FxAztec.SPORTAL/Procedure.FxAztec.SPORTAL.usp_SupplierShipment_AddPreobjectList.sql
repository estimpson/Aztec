
/*
Create Procedure.FxAztec.SPORTAL.usp_SupplierShipment_AddPreobjectList.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_SupplierShipment_AddPreobjectList'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_SupplierShipment_AddPreobjectList
end
go

create procedure SPORTAL.usp_SupplierShipment_AddPreobjectList
	@SupplierCode varchar(20)
,	@ShipperNumber varchar(50)
,	@SerialList varchar(max)
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

/*	Validate serial list is numeric. */
if	exists
	(	select
			*
		from
			dbo.fn_SplitStringToRows(@SerialList, ',') fsstr
		where
			fsstr.Value like '%[^0-9]%'
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Non-numeric values in serial list %s in procedure %s', 16, 1, @SerialList, @ProcName)
	rollback tran @ProcName
	return
end

/*	Validate all serials in list are valid. */
declare
	@Serials table
(	Serial int
)
insert
	@Serials
(	Serial
)
select
	Serial = convert(int, fsstr.Value)
from
	dbo.fn_SplitStringToRows(@SerialList, ',') fsstr
where
	fsstr.Value like '%[0-9]%'

declare
	@InvalidSerialList varchar(max)
select
	@InvalidSerialList = Fx.ToList(s.Serial)
from
	@Serials s
where
	not exists
	(	select
			so.Serial
		from
			SPORTAL.SupplierObjects so
			join SPORTAL.SupplierObjectBatches sob
				on sob.RowID = so.SupplierObjectBatch
		where
			sob.SupplierCode = @SupplierCode
			and so.Serial = s.Serial
			and so.Status = 0
	)

if	@InvalidSerialList > '' begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid serials in serial list %s in procedure %s', 16, 1, @InvalidSerialList, @ProcName)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Assign shipper number to pre-objects. */
declare
	@ObjectCount int =
		(	select
				count(distinct s.Serial)
			from
				@Serials s
		)

--- <Update rows="n">
set	@TableName = 'SPORTAL.SupplierObjects'

update
	so
set
	ShipperNumber = @ShipperNumber
from
	SPORTAL.SupplierObjects so
where
	so.Serial in
		(	select
				s.Serial
			from
				@Serials s
		)
	and so.Status = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @ObjectCount begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @ObjectCount)
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
	@SupplierCode varchar(20)
,	@ShipperNumber varchar(50)
,	@SerialList varchar(max)

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_SupplierShipment_AddPreobjectList
	@SupplierCode = @SupplierCode
,	@ShipperNumber = @ShipperNumber
,	@SerialList = @SerialList
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

