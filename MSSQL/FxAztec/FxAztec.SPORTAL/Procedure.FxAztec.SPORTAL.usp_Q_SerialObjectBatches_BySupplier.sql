
/*
Create Procedure.FxAztec.SPORTAL.usp_Q_SerialObjectBatches_BySupplier.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_Q_SerialObjectBatches_BySupplier'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_Q_SerialObjectBatches_BySupplier
end
go

create procedure SPORTAL.usp_Q_SerialObjectBatches_BySupplier
	@SupplierCode varchar(20)
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

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
/*	Validate supplier code. */
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
	--rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Return pre-object batches for this supplier. */
select
	sob.SupplierCode
,	sob.LotNumber
,	sob.SupplierPartCode
,	sob.InternalPartCode
,	sob.FirstSerial
,	SerialList =
		(	select
				FX.ToList(so.Serial)
			from
				SPORTAL.SupplierObjects so
			where
				so.SupplierObjectBatch = sob.RowID
		)
,	sob.QuantityPerObject
,	sob.ObjectCount
,	BatchCreateDT = sob.RowCreateDT
from
	SPORTAL.SupplierObjectBatches sob
where
	sob.SupplierCode = @SupplierCode
	and sob.Status = 0
--- </Body>

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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_SerialObjectBatches_BySupplier
	@SupplierCode = @SupplierCode
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

