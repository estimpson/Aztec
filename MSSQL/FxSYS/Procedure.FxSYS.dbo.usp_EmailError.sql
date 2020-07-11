
/*
Create Procedure.FxSYS.dbo.usp_EmailError.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.usp_EmailError'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_EmailError
end
go

create procedure dbo.usp_EmailError
	@Recipients varchar(max) = ''
,	@CopyRecipients varchar(max)= 'estimpson@fore-thought.com'
as
begin
	set nocount on

	--- <Body>
	declare
		@html nvarchar(max)
	,	@emailTableName sysname = N'#errorInfo'

	select
		[Error] = convert(varchar(50), error_number())
	,	[Severity] =  convert(varchar(5), error_severity())
	,	[State] = convert(varchar(5), error_state())
	,	[Procedure] = isnull(error_procedure(), '-')
	,	[Line] = convert(varchar(5), error_line())
	into
		#errorInfo

	declare @html1 nvarchar(max);
	
	execute dbo.usp_TableToHTML
			@tableName = @emailTableName
		,	@html = @html out
		,	@orderBy = N'[Error]'
		,	@includeRowNumber = 0
		,	@camelCaseHeaders = 1
	
	declare
		@emailHeader nvarchar(max) = 'Error in procedure'

	declare
		@emailBody nvarchar(max) = N'<H1>' + @emailHeader + N'<H1>' + @html
	
	exec msdb.dbo.sp_send_dbmail
			@profile_name = N'FxAlerts'
		,	@recipients = @Recipients
		,	@copy_recipients = @CopyRecipients
		,	@subject = @emailHeader
		,	@body = @emailBody
		,	@body_format = 'HTML'
		,	@importance = 'HIGH'
	
	--- </Body>
end
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
	@ProcReturn = dbo.usp_EmailError

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

