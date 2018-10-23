SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FXSYS].[usp_LogError]
@ErrorLogID int = 0 output
as
begin
	set nocount on

	/*	Output parameter value of 0 indicates that error information was not logged. */
	set @ErrorLogID = 0

	--print 'Error logging reached. '
	begin try
		--- <Body>
		/*	Return if there is no error information to log. */
		if	error_number() is null return

		/*	Return if inside an uncomittable transaction. */
		--print error_number()
		if	xact_state() = -1 begin
			print 'Cannot log error since the current transaction is in an uncommittable state. Rollback the transaction before executing usp_LogError in order to successfully log error information.'
			return
		end

		insert
			FXSYS.ErrorLog
		(	UserName
		,	ErrorNumber
		,	ErrorSeverity
		,	ErrorState
		,	ErrorProcedure
		,	ErrorLine
		,	ErrorMessage
		)
		select
			UserName = convert(sysname, current_user)
		,	ErrorNumber = error_number()
		,	ErrorSeverity = error_severity()
		,	ErrorState = error_state()
		,	ErrorProcedure = error_procedure()
		,	ErrorLine = error_line()
		,	ErrorMessage = error_message()

		/*	Pass back the ErrorLogId for the row inserted. */
		set	@ErrorLogID = scope_identity()
		--- </Body>
	end try
	begin catch
		print 'An error occurred in stored procedure usp_LogError: '
		execute FXSYS.usp_PrintError
	end catch
end
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = FXSYS.usp_LogError
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
