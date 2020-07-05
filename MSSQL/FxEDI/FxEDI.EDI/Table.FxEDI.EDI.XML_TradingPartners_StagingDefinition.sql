
/*
Create Table.FxEDI.EDI.XML_TradingPartners_StagingDefinition.sql
*/

use FxEDI
go

/*
exec FT.sp_DropForeignKeys

drop table EDI.XML_TradingPartners_StagingDefinition

exec FT.sp_AddForeignKeys
*/
if	objectproperty(object_id('EDI.XML_TradingPartners_StagingDefinition'), 'IsTable') is null begin

	create table EDI.XML_TradingPartners_StagingDefinition
	(	DocumentTradingPartner varchar(50)
	,	DocumentType varchar(10)
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	EDIVersion varchar(10)
	,	StagingProcedureSchema sysname null
	,	StagingProcedureName sysname null
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	DocumentTradingPartner
		,	DocumentType
		)
	)
end
go

/*
Create trigger EDI.tr_XML_TradingPartners_StagingDefinition_uRowModified on EDI.XML_TradingPartners_StagingDefinition
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI.tr_XML_TradingPartners_StagingDefinition_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI.tr_XML_TradingPartners_StagingDefinition_uRowModified
end
go

create trigger EDI.tr_XML_TradingPartners_StagingDefinition_uRowModified on EDI.XML_TradingPartners_StagingDefinition after update
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		set	@TableName = 'EDI.XML_TradingPartners_StagingDefinition'
		
		update
			xtpsd
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.XML_TradingPartners_StagingDefinition xtpsd
			join inserted i
				on i.RowID = xtpsd.RowID
		
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
	EDI.XML_TradingPartners_StagingDefinition
...

update
	...
from
	EDI.XML_TradingPartners_StagingDefinition
...

delete
	...
from
	EDI.XML_TradingPartners_StagingDefinition
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
insert
	EDI.XML_TradingPartners_StagingDefinition
(	DocumentTradingPartner
,	DocumentType
,	Status
,	Type
,	EDIVersion
,	StagingProcedureSchema
,	StagingProcedureName
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	xtpsd.DocumentTradingPartner
,	xtpsd.DocumentType
,	xtpsd.Status
,	xtpsd.Type
,	xtpsd.EDIVersion
,	xtpsd.StagingProcedureSchema
,	xtpsd.StagingProcedureName
,	xtpsd.RowCreateDT
,	xtpsd.RowCreateUser
,	xtpsd.RowModifiedDT
,	xtpsd.RowModifiedUser
from
	FxDependencies.EDI.XML_TradingPartners_StagingDefinition xtpsd
*/

select
	*
from
	EDI.XML_TradingPartners_StagingDefinition xtpsd
