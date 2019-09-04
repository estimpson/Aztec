SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [EDI].[usp_IgnoreUnusedDocuments]
	@TranDT datetime out
,	@Result integer out
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
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Mark new and reprocessed unused EDI documents as ignored.*/
--- <Update rows="*">
set	@TableName = 'EDI.UnusedEDIDocuments'

update
	ued
set
	Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'Ignored')
from
	EDI.UnusedEDIDocuments ued
where
	Status in (dbo.udf_StatusValue('EDI.EDIDocuments', 'New'), dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	return
end
--- </Update>
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
go

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_IgnoreUnusedDocuments
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

select
	*
from
	EDI.UnusedEDIDocuments ued
where
	Status != dbo.udf_StatusValue('EDI.EDIDocuments', 'Ignored')
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
