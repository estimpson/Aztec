
/*
Create Table.FxEDI.EDI_DICT.DictionaryDTFormat.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionaryDTFormat
if	objectproperty(object_id('EDI_DICT.DictionaryDTFormat'), 'IsTable') is null begin

	create table EDI_DICT.DictionaryDTFormat
	(	DictionaryVersion varchar(50) default ('0') not null
	,	Type int not null default(0)
	,	FormatString varchar(12) not null
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	DictionaryVersion
		,	Type
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionaryDTFormat_uRowModified on EDI_DICT.DictionaryDTFormat
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionaryDTFormat_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionaryDTFormat_uRowModified
end
go

create trigger EDI_DICT.tr_DictionaryDTFormat_uRowModified on EDI_DICT.DictionaryDTFormat after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionaryDTFormat'
		
		update
			ddf
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionaryDTFormat ddf
			join inserted i
				on i.RowID = ddf.RowID
		
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
	EDI_DICT.DictionaryDTFormat
...

update
	...
from
	EDI_DICT.DictionaryDTFormat
...

delete
	...
from
	EDI_DICT.DictionaryDTFormat
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

insert
	EDI_DICT.DictionaryDTFormat
(	DictionaryVersion
,	Type
,	FormatString
)
select
	DictionaryVersion = '002002FORD'
,	Type = 2
,	FormatString = 'HHMM'