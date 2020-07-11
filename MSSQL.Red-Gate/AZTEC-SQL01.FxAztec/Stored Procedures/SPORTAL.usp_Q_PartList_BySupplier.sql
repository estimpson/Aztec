SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SPORTAL].[usp_Q_PartList_BySupplier]
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
declare
	@Exception varchar(1000)
,	@ProcedureName varchar(50)

set @ProcedureName = 'SPORTAL.usp_Q_PartList_BySupplier'

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

	set @Exception = 'Invalid supplier code: ' + @SupplierCode
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier code %s.  Procedure %s.', 16, 1, @SupplierCode, @ProcName)
	--rollback tran @ProcName
	return
end

/* Validate part list. */
if not exists (
		select
			*
		from
			SPORTAL.SupplierPartList spl
		where
			spl.SupplierCode = @SupplierCode
			and spl.Status = 0 ) begin

	set @Exception = 'No parts found for supplier: ' + @SupplierCode + '.'
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	raiserror ('Error:  No parts found for supplier %s.  Procedure %s.', 16, 1, @SupplierCode, @ProcName)
	return
end
---	</ArgumentValidation>


--- <Body>
/*	Return part list for this supplier. */
select
	spl.SupplierCode
,	spl.SupplierName
,	spl.SupplierPartCode
,	spl.Status
,	spl.SupplierStdPack
,	spl.InternalPartCode
,	spl.Decription
,	spl.PartClass
,	spl.PartSubClass
,	spl.HasBlanketPO
,	spl.LabelFormatName
from
	SPORTAL.SupplierPartList spl
where
	spl.SupplierCode = @SupplierCode
	and spl.Status = 0
order by
	spl.SupplierPartCode
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

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_PartList_BySupplier
	@SupplierCode = @SupplierCode
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
GRANT EXECUTE ON  [SPORTAL].[usp_Q_PartList_BySupplier] TO [SupplierPortal]
GO
