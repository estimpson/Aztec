
/*
Create Procedure.FxAztec.SPORTAL.usp_Q_Preobjects_BySupplierLot.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_Q_Preobjects_BySupplierLot'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_Q_Preobjects_BySupplierLot
end
go

create procedure SPORTAL.usp_Q_Preobjects_BySupplierLot
	@SupplierCode varchar(20)
,	@LotNumber varchar(100)
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
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
/*	Return pre-objects.*/
select
	so.Serial
,	so.Status
,	so.Type
,	sob.SupplierCode
,	sob.SupplierPartCode
,	sob.InternalPartCode
,	so.Quantity
,	so.LotNumber
,	spl.LabelFormatName
,	so.RowCreateDT
,	so.RowModifiedDT
from
	SPORTAL.SupplierObjects so
	join SPORTAL.SupplierObjectBatches sob
		on sob.RowID = so.SupplierObjectBatch
	join SPORTAL.SupplierPartList spl
		on spl.SupplierCode = sob.SupplierCode
		and spl.InternalPartCode = sob.InternalPartCode
		and spl.Status = 0
where
	sob.SupplierCode = @SupplierCode
	and so.LotNumber = @LotNumber
	and so.Status = 0
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
,	@LotNumber varchar(100) = 'TEST'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierLot
	@SupplierCode = @SupplierCode
,	@LotNumber = @LotNumber
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

