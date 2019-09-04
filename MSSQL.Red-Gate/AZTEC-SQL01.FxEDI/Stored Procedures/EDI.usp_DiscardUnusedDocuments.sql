SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [EDI].[usp_DiscardUnusedDocuments]
	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings on
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
declare
	@TranCount smallint

select
	@TranCount = @@TRANCOUNT

if	@TranCount > 0 begin
	save tran @ProcName
end

set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>

update
	ed
set
	Status = -1
from
	EDI.EDIDocuments ed
where
	ed.Data.exist('/FileList') = 1
	and ed.Status in (dbo.udf_StatusValue('EDI.EDIDocuments', 'New'), dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))

update
	ed
set
	Status = -1
from
	EDI.EDIDocuments ed
where
	ed.Data.exist('/TRN-997') = 1
	and ed.Status in (dbo.udf_StatusValue('EDI.EDIDocuments', 'New'), dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))

update
	ed
set
	Status = -1
from
	EDI.EDIDocuments ed
where
	FileName like '%.xsl'
	and ed.Status in (dbo.udf_StatusValue('EDI.EDIDocuments', 'New'), dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))

update
	ed
set
	Status = -1
from
	EDI.EDIDocuments ed
where
	ed.RowCreateDT < getdate() - 1
	and ed.Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'New')
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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_DiscardUnusedDocuments
	@TranDT = @TranDT out
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
