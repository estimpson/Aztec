
/*
Create Procedure.FxUtilities.dbo.usp_CommandShell_Execute.sql
*/

use FxUtilities
go

if	objectproperty(object_id('dbo.usp_CommandShell_Execute'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_CommandShell_Execute
end
go

create procedure dbo.usp_CommandShell_Execute
	@Command varchar(8000)
,	@CommandOutput varchar(max) out
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

--- <Tran Allowed=No AutoCreate=No TranDTParm=Yes>
if	@@TRANCOUNT > 0 begin

	RAISERROR ('This procedure cannot be run in the context of a transaction.', 16, 1, @ProcName)
	return
end

set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
declare
	@cmdShellEnabled int

select
	@cmdShellEnabled =
		(	select
				isEnabled = convert(int, value_in_use)
			from
				master.sys.configurations	
			where
				name = 'xp_cmdshell'
		)

if	(	select
  			isEnabled = convert(int, value_in_use)
		from
			master.sys.configurations
		where
			name = 'show advanced options'
  	) = 0 begin
	execute
		sp_configure 'show advanced options', 1
	reconfigure
end

execute
	sp_configure 'xp_cmdshell', 1
reconfigure

create table
	#cmdoutput
(	Text nvarchar(max)
,	RowID int not null IDENTITY(1, 1) primary key
)

insert
	#cmdoutput
(	Text
)
execute
	xp_cmdshell
    @command_string = @Command

set	@CommandOutput = ''

select
	@CommandOutput = @CommandOutput + coalesce(c.Text, '') + '
'
from
	#cmdoutput c
order by
	c.RowID

if	@cmdShellEnabled = 0
	begin

	if	(	select
  				isEnabled = convert(int, value_in_use)
			from
				master.sys.configurations
			where
				name = 'show advanced options'
  		) = 0 begin
		execute
			sp_configure 'show advanced options', 1
		reconfigure
	end

	execute
		sp_configure 'xp_cmdshell', 0
	reconfigure
end

if	(	select
  			isEnabled = convert(int, value_in_use)
		from
			master.sys.configurations
		where
			name = 'show advanced options'
  	) = 1 begin
	execute
		sp_configure 'show advanced options', 0
	reconfigure
end
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_CommandShell_Execute
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
go

