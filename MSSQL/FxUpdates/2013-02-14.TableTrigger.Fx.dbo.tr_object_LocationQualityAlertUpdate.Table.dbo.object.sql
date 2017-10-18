
/*
Create trigger TableTrigger.Fx.dbo.tr_object_LocationQualityAlertUpdate.Table.dbo.object.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.tr_object_LocationQualityAlertUpdate'), 'IsTrigger') = 1 begin
	drop trigger dbo.tr_object_LocationQualityAlertUpdate
end
go

create trigger dbo.tr_object_LocationQualityAlertUpdate on dbo.object after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
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
	if	update(location) begin
    
		/*	Set inventory on hold if approved inventory is put in a quality hold location. */
		if	exists
				(	select
						*
					from
						dbo.object o
						join inserted i
							on i.serial = o.serial
						join deleted d
							on d.serial = i.serial
							and d.location != i.location
						join dbo.location lQualityAlert
							on i.location = lQualityAlert.code
							and lQualityAlert.QualityAlert = 1
					where
						o.status = 'A'
				) begin

		declare
			@userDefinedHoldStatus varchar(30)

		set	@userDefinedHoldStatus = dbo.udf_GetBaseUserDefinedStatus('H')

			--- <Update rows="*">
			set	@TableName = 'object'
	
			update
				o
			set
				status = 'H'
			,	user_defined_status = @userDefinedHoldStatus
			from
				dbo.object o
				join inserted i
					on i.serial = o.serial
				join deleted d
					on d.serial = i.serial
					and d.location != i.location
				join dbo.location lQualityAlert
					on i.location = lQualityAlert.code
					and lQualityAlert.QualityAlert = 1
	
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
		end
	end
	--- </Body>
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
	dbo.object
...

update
	...
from
	dbo.object
...

delete
	...
from
	dbo.object
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

