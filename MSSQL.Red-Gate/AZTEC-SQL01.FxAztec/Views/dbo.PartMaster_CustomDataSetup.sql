SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PartMaster_CustomDataSetup]
as
select
	PartCode = p.part
,	pmcsv.CustomFieldName
,	pmcsv.StringValue
,	ValueSelected = case when pmpcsv.StringValue = pmcsv.StringValue then 1 else 0 end
,	pmcf.AllowMultipleValues
,	pmcf.OnlyDefinedValues
,	ValueID = pmcsv.RowID
from
	dbo.part p
	cross join dbo.PartMaster_CustomStringValues pmcsv
		join dbo.PartMaster_CustomFields pmcf
			on pmcf.CustomFieldName = pmcsv.CustomFieldName
	left join dbo.PartMaster_PartCustomStringValues pmpcsv
		on pmpcsv.PartCode = p.part
		and pmpcsv.CustomFieldName = pmcf.CustomFieldName
		and pmpcsv.StringValue = pmcsv.StringValue
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[tr_PartMaster_CustomDataSetup_u] on [dbo].[PartMaster_CustomDataSetup] instead of update
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
	/*	If there were string values that were changed that don't already exist, add them. */
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
						dbo.PartMaster_CustomStringValues pmcsv
					where
						pmcsv.CustomFieldName = i.CustomFieldName
						and pmcsv.StringValue = i.StringValue
				)
				and i.OnlyDefinedValues = 0              
		) begin

		--- <Insert rows="1+">
		set	@TableName = 'dbo.PartMaster_CustomStringValues'
		
		insert
			dbo.PartMaster_CustomStringValues
		(	CustomFieldName
		,	StringValue
		)
		select distinct
			CustomFieldName = i.CustomFieldName
		,	StringValue = i.StringValue
		from
			inserted i
		where
			not exists
			(	select
					*
				from
					dbo.PartMaster_CustomStringValues pmcsv
				where
					pmcsv.CustomFieldName = i.CustomFieldName
					and pmcsv.StringValue = i.StringValue
			)                  
			and i.OnlyDefinedValues = 0              
		
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
	end
	
	/*	Insert the selected value (or values if AllowMultipleValues). */
	if	exists
		(	select
			i.PartCode
		,	i.CustomFieldName
		,	i.StringValue
		from
			inserted i
		where
			i.ValueSelected = 1
			and not exists
			(	select
					*
				from
					dbo.PartMaster_PartCustomStringValues pmpcsv
				where
					pmpcsv.PartCode = i.PartCode
					and pmpcsv.CustomFieldName = i.CustomFieldName
					and pmpcsv.StringValue = i.StringValue
			)
		) begin

		--- <Insert rows="*">
		set	@TableName = 'dbo.PartMaster_PartCustomStringValues'
	
		insert
			dbo.PartMaster_PartCustomStringValues
		(	PartCode
		,	CustomFieldName
		,	StringValue
		)
		select
			i.PartCode
		,	i.CustomFieldName
		,	i.StringValue
		from
			inserted i
		where
			i.ValueSelected = 1
			and not exists
			(	select
					*
				from
					dbo.PartMaster_PartCustomStringValues pmpcsv
				where
					pmpcsv.PartCode = i.PartCode
					and pmpcsv.CustomFieldName = i.CustomFieldName
					and pmpcsv.StringValue = i.StringValue
			)
			and
			(	i.AllowMultipleValues = 1
				or i.ValueID =
				(	select
						min(ValueID)
					from
						inserted
					where
						PartCode = i.PartCode
						and CustomFieldName = i.CustomFieldName
						and ValueSelected = 1
				)
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

	/*	If only a single value is allowed, remove other selected value. */
	if	exists
		(	select
				*
			from
				dbo.PartMaster_PartCustomStringValues pmpcsv
			where
				exists
                (	select
                		*
                	from
                		inserted
					where
						PartCode = pmpcsv.PartCode
						and CustomFieldName = pmpcsv.CustomFieldName
						and StringValue != pmpcsv.StringValue
						and AllowMultipleValues = 0
						and ValueSelected = 1
				)
		) begin
        
		--- <Delete rows="1">
		set	@TableName = 'dbo.PartMaster_PartCustomStringValues'
		
		delete
			pmpcsv
		from
			dbo.PartMaster_PartCustomStringValues pmpcsv
		where
			exists
			(	select
                	*
                from
                	inserted
				where
					PartCode = pmpcsv.PartCode
					and CustomFieldName = pmpcsv.CustomFieldName
					and StringValue != pmpcsv.StringValue
					and AllowMultipleValues = 0
					and ValueSelected = 1
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
	end
	
	/*	Delete unselected values. */
	if	exists
		(	select
				*
			from
				dbo.PartMaster_PartCustomStringValues pmpcsv
				join inserted i
					on i.PartCode = pmpcsv.PartCode
					and i.CustomFieldName = pmpcsv.CustomFieldName
					and i.StringValue = pmpcsv.StringValue
			where
				i.ValueSelected = 0
		) begin

		--- <Delete rows="*">
		set	@TableName = 'dbo.PartMaster_PartCustomStringValues'
	
		delete
			pmpcsv
		from
			dbo.PartMaster_PartCustomStringValues pmpcsv
			join inserted i
				on i.PartCode = pmpcsv.PartCode
				and i.CustomFieldName = pmpcsv.CustomFieldName
				and i.StringValue = pmpcsv.StringValue
		where
			i.ValueSelected = 0
	
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
	
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		--- </Delete end>
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
	dbo.PartMaster_CustomDataSetup
...

update
	...
from
	dbo.PartMaster_CustomDataSetup
...

delete
	...
from
	dbo.PartMaster_CustomDataSetup
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
