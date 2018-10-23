SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SPORTAL].[usp_Q_Lots_BySupplier]
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
/*	Return lot list for this supplier. */
select
	sob.SupplierCode
,	so.LotNumber
,	SupplierlPartList = FX.ToList(distinct sob.SupplierPartCode)
,	InternalPartList = FX.ToList(distinct sob.InternalPartCode)
,	SerialList = FX.ToList(so.Serial)
,	TotalQuantity = sum(so.Quantity)
,	LotCreateDT = min(so.RowCreateDT)
from
	SPORTAL.SupplierObjects so
	join SPORTAL.SupplierObjectBatches sob
		on sob.RowID = so.SupplierObjectBatch
where
	sob.SupplierCode = @SupplierCode
	and so.Status = 0
group by
	sob.SupplierCode
,	so.LotNumber
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
	@ProcReturn = SPORTAL.usp_Q_Lots_BySupplier
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
GO
GRANT EXECUTE ON  [SPORTAL].[usp_Q_Lots_BySupplier] TO [SupplierPortal]
GO
