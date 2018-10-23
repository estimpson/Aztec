SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FXSYS].[usp_PrintError]
as
begin
	set nocount on

	--- <Body>
	print
		'Error ' + convert(varchar(50), error_number())
		+ ', Severity ' + convert(varchar(5), error_severity())
		+ ', State ' + convert(varchar(5), error_state())
		+ ', Procedure ' + isnull(error_procedure(), '-')
		+ ', Line '
		+ convert(varchar(5), error_line())

	print error_message()
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

declare
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = FXSYS.usp_PrintError
	@Param1 = @Param1
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
