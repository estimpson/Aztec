SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [EDIFORD].[usp_ClearQueue]
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
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*		Set in process documents to requeued.*/
--- <Update rows="*">
set	@TableName = 'EDIFord.ShipScheduleHeaders'

update
	fh
set
	Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued')
from
	EDIFord.ShipScheduleHeaders fh
where
	Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess')

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	return
end
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIFord.PlanningHeaders'

update
	fh
set
	Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued')
from
	EDIFord.PlanningHeaders fh
where
	Status = dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess')

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
delete [SQL.LEXAMAR.DECOMA.COM].MONITOR.EDI.StagingFord_862_Headers
delete [SQL.LEXAMAR.DECOMA.COM].MONITOR.EDI.StagingFord_830_Headers

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_Ford_ClearQueue
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

select
	*
from
	EDIFord.ShipScheduleHeaders fh

select
	*
from
	EDIFord.PlanningHeaders fh
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
