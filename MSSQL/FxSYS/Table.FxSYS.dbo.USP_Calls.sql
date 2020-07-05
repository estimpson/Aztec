
/*
Create Table.FxSYS.dbo.USP_Calls.sql
*/

use FxSYS
go

--drop table dbo.USP_Calls
if	objectproperty(object_id('dbo.USP_Calls'), 'IsTable') is null begin

	create table dbo.USP_Calls
	(	Status int not null default(0)
	,	Type int not null default(0)
	,	USP_Name sysname
	,	BeginDT datetime
	,	EndDT datetime
	,	InArguments varchar(max)
	,	OutArguments varchar(max)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	)
end
go

/*
Create trigger dbo.tr_USP_Calls_uRowModified on dbo.USP_Calls
*/

--use FxSYS
--go

if	objectproperty(object_id('dbo.tr_USP_Calls_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger dbo.tr_USP_Calls_uRowModified
end
go

create trigger dbo.tr_USP_Calls_uRowModified on dbo.USP_Calls after update
as
declare
	@TranDT datetime
,	@Result int

set xact_abort off
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. FxSYS.usp_Test
--- </Error Handling>

begin try
	--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount
	set	@TranDT = coalesce(@TranDT, GetDate())
	save tran @ProcName
	--- </Tran>

	---	<ArgumentValidation>

	---	</ArgumentValidation>
	
	--- <Body>
	if	not update(RowModifiedDT) begin
		--- <Update rows="*">
		set	@TableName = 'dbo.USP_Calls'
		
		update
			uc
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			dbo.USP_Calls uc
			join inserted i
				on i.RowID = uc.RowID
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		--- </Update>
		
		--- </Body>
	end
end try
begin catch
	declare
		@errorName int
	,	@errorSeverity int
	,	@errorState int
	,	@errorLine int
	,	@errorProcedures sysname
	,	@errorMessage nvarchar(2048)
	,	@xact_state int
	
	select
		@errorName = error_number()
	,	@errorSeverity = error_severity()
	,	@errorState = error_state ()
	,	@errorLine = error_line()
	,	@errorProcedures = error_procedure()
	,	@errorMessage = error_message()
	,	@xact_state = xact_state()

	if	xact_state() = -1 begin
		print 'Error number: ' + convert(varchar, @errorName)
		print 'Error severity: ' + convert(varchar, @errorSeverity)
		print 'Error state: ' + convert(varchar, @errorState)
		print 'Error line: ' + convert(varchar, @errorLine)
		print 'Error procedure: ' + @errorProcedures
		print 'Error message: ' + @errorMessage
		print 'xact_state: ' + convert(varchar, @xact_state)
		
		rollback transaction
	end
	else begin
		/*	Capture any errors in SP Logging. */
		rollback tran @ProcName
	end
end catch

---	<Return>
set	@Result = 0
return
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

insert
	dbo.USP_Calls
...

update
	...
from
	dbo.USP_Calls
...

delete
	...
from
	dbo.USP_Calls
...
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

/*
set identity_insert dbo.USP_Calls on

insert
	dbo.USP_Calls
(	Status
,	Type
,	USP_Name
,	BeginDT
,	EndDT
,	InArguments
,	OutArguments
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	MONITOR.FXSYS.USP_Calls uc
where
	not exists
		(	select
				*
			from
				dbo.USP_Calls uc2
			where
				uc2.RowID = uc.RowID
		)

set identity_insert dbo.USP_Calls off
*/

select
	uc.Status
,   uc.Type
,   uc.USP_Name
,   uc.BeginDT
,   uc.EndDT
,   uc.InArguments
,   uc.OutArguments
,   uc.RowID
,   uc.RowCreateDT
,   uc.RowCreateUser
,   uc.RowModifiedDT
,   uc.RowModifiedUser
from
	dbo.USP_Calls uc
