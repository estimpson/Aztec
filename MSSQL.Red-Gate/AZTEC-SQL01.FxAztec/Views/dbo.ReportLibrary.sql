SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReportLibrary]
as
select
	ReportName = rl.name
,	ReportType = rl.report
,	TypeDescription = rlist.description
,	Type =
		case
			when LabelPath > '' then 'E'
			else rl.type
		end			
,	ObjectName = rl.object_name
,	LibraryName = rl.library_name
,	Preview = rl.preview
,	PrintSetup = rl.print_setup
,	Printer = rl.printer
,	Copies = rl.copies
,	LabelFormat = bl.LabelFormat
,	LabelPath = bl.LabelPath
from
	dbo.report_library rl
	left join dbo.report_list rlist
		on rlist.report = rl.report
	left join dbo.BartenderLabels bl
		on bl.LabelFormat = rl.name
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_ReportLibrary_iud] on [dbo].[ReportLibrary] instead of insert, update, delete
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
	/*	Deletes. */
	if	exists
			(	select
					*
				from
					deleted d
				where
					not exists
						(	select
								*
							from
								inserted i
							where
								i.ReportName = d.ReportName
						)
			) begin
		
		--- <Delete rows="*">
		set	@TableName = 'dbo.BartenderLabels'
		
		delete
			bl
		from
			dbo.BartenderLabels bl
			join deleted d
				on d.ReportName = bl.LabelFormat
		where
			not exists
				(	select
						*
					from
						inserted i
					where
						i.ReportName = d.ReportName
				)
				
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		--- </Delete>
		
		--- <Delete rows="1+">
		set	@TableName = 'dbo.report_library'
		
		delete
			rl
		from
			dbo.report_library rl
			join deleted d
				on d.ReportName = rl.name
		where
			not exists
				(	select
						*
					from
						inserted i
					where
						i.ReportName = d.ReportName
				)
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		if	@RowCount < 1 begin
			set	@Result = 999999
			RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
			rollback tran @ProcName
			return
		end
		--- </Delete>
	end

	/*	Updates. */
	if	exists
			(	select
					*
				from
					inserted i
					join deleted d
						on i.ReportName = d.ReportName
			) begin
		
		if	exists
				(	select
						*
					from
						inserted i
						join deleted d
							on i.ReportName = d.ReportName
					where
						i.LabelPath is not null
				) begin

				--- <Insert rows="*">
				set	@TableName = 'dbo.BartenderLabels'

				insert
					dbo.BartenderLabels
				(	LabelFormat
				,	LabelPath
				)
				select
					LabelFormat = i.ReportName
				,	LabelPath = i.LabelPath
				from
					inserted i
					join deleted d
						on i.ReportName = d.ReportName
				where
					i.LabelPath is not null
					and not exists
						(	select
								*
							from
								dbo.BartenderLabels bl
							where
								bl.LabelFormat = i.LabelFormat
						)
				
				select
					@Error = @@Error,
					@RowCount = @@Rowcount
				
				if	@Error != 0 begin
					set	@Result = 999999
					RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
					rollback tran @ProcName
					return
				end
				--- </Insert>
				
				--- <Update rows="*">
				set	@TableName = 'dbo.BartenderLabels'
				
				update
					bl
				set
					LabelPath = i.LabelPath
				from
					dbo.BartenderLabels bl
					join inserted i
						on i.LabelFormat = bl.LabelFormat
					join deleted d
						on i.ReportName = d.ReportName
				
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

		--- <Update rows="*">
		set	@TableName = 'dbo.report_library'
		
		update
			rl
		set
			report = i.ReportType
		,	type =
				case
					when i.Type = 'E' then 'W'
					else i.Type
				end
		,	object_name = i.ObjectName
		,	library_name = i.LibraryName
		,	preview = i.Preview
		,	print_setup = i.PrintSetup
		,	printer = i.Printer
		,	copies = i.Copies
		from
			dbo.report_library rl
				join inserted i
					on i.ReportName = rl.name
				join deleted d
					on i.ReportName = d.ReportName
		
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

	if	exists
			(	select
					*
				from
					inserted i
				where
					not exists
						(	select
								*
							from
								deleted d
							where
								d.ReportName = i.ReportName
						)
			) begin

		--- <Insert rows="1+">
		set	@TableName = 'dbo.report_library'
		
		insert
			dbo.report_library
		(	name
		,	report
		,	type
		,	object_name
		,	library_name
		,	preview
		,	print_setup
		,	printer
		,	copies
		)
		select
			name = i.ReportName
		,	report = i.ReportType
		,	type = i.Type
		,	object_name = i.ObjectName
		,	library_name = i.LibraryName
		,	preview = i.Preview
		,	print_setup = i.PrintSetup
		,	printer = i.Printer
		,	copies = i.Copies
		from
			inserted i
		where
			not exists
				(	select
						*
					from
						deleted d
					where
						d.ReportName = i.ReportName
				)
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		if	@RowCount <= 0 begin
			set	@Result = 999999
			RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
			rollback tran @ProcName
			return
		end
		--- </Insert>

		--- <Insert rows="*">
		set	@TableName = 'dbo.report_library'
		
		insert
			dbo.BartenderLabels
		(	LabelFormat
		,	LabelPath
		)
		select
			LabelFormat = i.ReportName
		,	LabelPath = i.LabelPath
		from
			inserted i
		where
			i.LabelPath is not null
			and not exists
				(	select
						*
					from
						deleted d
					where
						d.ReportName = i.ReportName
				)
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		--- </Insert>
		
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
	dbo.ReportLibrary
...

update
	...
from
	dbo.ReportLibrary
...

delete
	...
from
	dbo.ReportLibrary
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
GO
