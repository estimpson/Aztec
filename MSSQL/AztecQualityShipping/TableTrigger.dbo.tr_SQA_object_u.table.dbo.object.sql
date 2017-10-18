/*
Create trigger TableTrigger.dbo.tr_SQA_object_u.table.dbo.object.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.tr_SQA_object_u'), 'IsTrigger') = 1 begin
	drop trigger dbo.tr_SQA_object_u
end
go

create trigger dbo.tr_SQA_object_u on dbo.object after update
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
	/*	Quality alert. */
	if	exists
		(	select
				*
			from
				inserted i
				join deleted d
					on d.serial = i.serial
				join dbo.SQA_Parts sp
					on sp.PartCode = i.part
			where
				i.shipper > 0
				and i.shipper != coalesce(d.shipper, 0)
		) begin
      
		declare	stagedObjects cursor local for
		select
			BoxSerial = i.serial
		from
			inserted i
			join deleted d
				on d.serial = i.serial
			join dbo.SQA_Parts sp
				on sp.PartCode = i.part
		where
			i.shipper > 0
			and i.shipper != coalesce(d.shipper, 0)

		open stagedObjects

		while
			1 = 1 begin
		
			declare
				@stagedBoxSerial int
		      
			fetch
				stagedObjects
			into
				@stagedBoxSerial  

			if	@@FETCH_STATUS != 0 begin
				break
			end
        
			--- <Call>	
			set	@CallProcName = 'dbo.usp_SQA_StageObject'
			execute
				@ProcReturn = dbo.usp_SQA_StageObject
					@OperatorCode = 'dbo'
				,	@Serial = @stagedBoxSerial
				,	@TranDT = @TranDT out
				,	@Result = @ProcResult out
		
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
				rollback tran @ProcName
				return
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
				rollback tran @ProcName
				return
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
				rollback tran @ProcName
				return
			end
			--- </Call>
		end
		close
			stagedObjects
		deallocate
			stagedObjects  
	end
		      
	/*	Quality alert. */
	if	exists
		(	select
				*
			from
				inserted i
				join deleted d
					on d.serial = i.serial
				join dbo.SQA_Parts sp
					on sp.PartCode = i.part
			where
				d.shipper != 0
				and coalesce(i.shipper, 0) != d.shipper
		) begin
      
		declare	unstagedObjects cursor local for
		select
			BoxSerial = i.serial
		,	Shipper = d.shipper
		from
			inserted i
			join deleted d
				on d.serial = i.serial
			join dbo.SQA_Parts sp
				on sp.PartCode = i.part
		where
			d.shipper != 0
			and coalesce(i.shipper, 0) != d.shipper

		open unstagedObjects

		while
			1 = 1 begin
			
			declare
				@unstagedBoxSerial int
			,	@shipperID int
  
			fetch
				unstagedObjects
			into
				@unstagedBoxSerial
			,	@shipperID

			if	@@FETCH_STATUS != 0 begin
				break
			end
        
			--- <Call>	
			set	@CallProcName = 'dbo.usp_SQA_UnstageObject'
			execute
				@ProcReturn = dbo.usp_SQA_UnstageObject
					@OperatorCode = 'dbo'
				,	@Serial = @unstagedBoxSerial
				,	@FromShipperID = @shipperID
				,	@TranDT = @TranDT out
				,	@Result = @ProcResult out
		
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
				rollback tran @ProcName
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
				rollback tran @ProcName
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
				rollback tran @ProcName
			end
			--- </Call>
		end
		close
			unstagedObjects
		deallocate
			unstagedObjects  
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

