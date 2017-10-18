
/*
Create Table.Fx.EDIToyota.ShipScheduleAccums.sql
*/

--use Fx
--go

--drop table EDIToyota.ShipScheduleAccums
if	objectproperty(object_id('EDIToyota.ShipScheduleAccums'), 'IsTable') is null begin

	create table EDIToyota.ShipScheduleAccums
	(	Status int not null default(0)
	,	Type int not null default(0)
	,	RawDocumentGUID uniqueidentifier null
	,	ReleaseNo varchar (50) null
	,	ShipToCode varchar (50) null
	,	ConsigneeCode varchar (50) null
	,	ShipFromCode varchar (50) null
	,	SupplierCode varchar (50) null
	,	CustomerPart varchar (50) null
	,	CustomerPO varchar (50) null
	,	CustomerPOLine varchar (50) null
	,	CustomerModelYear varchar (50) null
	,	CustomerECL varchar (50) null
	,	ReferenceNo varchar (50) null
	,	UserDefined1 varchar (50) null
	,	UserDefined2 varchar (50) null
	,	UserDefined3 varchar (50) null
	,	UserDefined4 varchar (50) null
	,	UserDefined5 varchar (50) null
	,	LastQtyReceived numeric (20, 6) null
	,	LastQtyDT datetime null
	,	LastShipper varchar (50) null
	,	LastAccumQty numeric (20, 6) null
	,	LastAccumDT datetime null
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	)
end
go

/*
Create trigger EDIToyota.tr_ShipScheduleAccums_uRowModified on EDIToyota.ShipScheduleAccums
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.tr_ShipScheduleAccums_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDIToyota.tr_ShipScheduleAccums_uRowModified
end
go

create trigger EDIToyota.tr_ShipScheduleAccums_uRowModified on EDIToyota.ShipScheduleAccums after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
		set	@TableName = 'EDIToyota.ShipScheduleAccums'
		
		update
			ssa
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDIToyota.ShipScheduleAccums ssa
			join inserted i
				on i.RowID = ssa.RowID
		
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
	EDIToyota.ShipScheduleAccums
...

update
	...
from
	EDIToyota.ShipScheduleAccums
...

delete
	...
from
	EDIToyota.ShipScheduleAccums
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

