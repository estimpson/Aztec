CREATE TABLE [dbo].[bill_of_material_ec]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__bill_of_m__LastU__1B0907CE] DEFAULT (suser_sname()),
[LastDT] [datetime] NULL CONSTRAINT [DF__bill_of_m__LastD__1BFD2C07] DEFAULT (getdate()),
[parent_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_datetime] [datetime] NOT NULL,
[end_datetime] [datetime] NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [numeric] (20, 6) NOT NULL,
[unit_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[std_qty] [numeric] (20, 6) NULL,
[scrap_factor] [numeric] (20, 6) NOT NULL,
[engineering_level] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[substitute_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_changed] [datetime] NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_bill_of_material_ec_CheckConsistancy] on [dbo].[bill_of_material_ec] after insert
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

/*	Handle duplicates. */
--if	exists
--	(	select
--			*
--		from
--			dbo.bill_of_material_ec bome
--			join inserted i
--				on i.parent_part = bome.parent_part
--				and i.part = bome.part
--				and i.ID != bome.ID
--		where
--			getdate() between bome.start_datetime and coalesce(bome.end_datetime, getdate())
--	) begin
	
--	RAISERROR ('Error inserting into table %s in procedure %s.  Error: duplicate parent part and child part row(s) exists.', 16, 1, 'dbo.bill_of_material_ec', @ProcName)
--	rollback tran
--	return
--end

/*	*/
--- <Call>	
set	@CallProcName = 'dbo.usp_Scheduling_BuildXRt'
execute
	@ProcReturn = dbo.usp_Scheduling_BuildXRt
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran
	return
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran
	return
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran
	return
end
--- </Call>

/*	Handle infinite loops. */
if	exists
	(	select
			*
		from
			FT.XRt xr
		where
			xr.Infinite = 1
	) begin
	RAISERROR ('Error encountered in %s.  Information: Infinite loop in BOM', 16, 1, @ProcName)
	rollback tran
	return
end		

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
	dbo.bill_of_material_ec
...

update
	...
from
	dbo.bill_of_material_ec
...

delete
	...
from
	dbo.bill_of_material_ec
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
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_bill_of_material_ec_d]
on [dbo].[bill_of_material_ec] instead of delete
as
declare
	@tranDT datetime

set	@tranDT = getdate()

--	End records that were deleted (if they are still active).
update
	dbo.bill_of_material_ec
set
	end_datetime = @tranDT
where
	@tranDT <= coalesce(end_datetime, @tranDT)
	and
		ID in (select ID from deleted)

--	Delete records that haven't started yet.
delete
	dbo.bill_of_material_ec
where
	@tranDT <= start_datetime
	and
		ID in (select ID from deleted)
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_bill_of_material_ec_i]
on [dbo].[bill_of_material_ec] instead of insert
as
declare
	@tranDT datetime

set	@tranDT = getdate()

--	Create new records (only allow records to start and/or end after now)...
insert
	dbo.bill_of_material_ec
(	parent_part
,   part
,   start_datetime
,   end_datetime
,   type
,   quantity
,   unit_measure
,   reference_no
,   std_qty
,   scrap_factor
,   engineering_level
,   operator
,   substitute_part
,   date_changed
,   note
)
select
	parent_part
,   part
,   start_datetime = coalesce (case when start_datetime > @tranDT then start_datetime end, @tranDT)
,   end_datetime = coalesce ((select min(start_datetime) from dbo.bill_of_material_ec bome where parent_part = inserted.parent_part and part = inserted.part and coalesce (case when start_datetime > @tranDT then start_datetime end, @tranDT) > coalesce (case when start_datetime > @tranDT then start_datetime end, @tranDT)), end_datetime)
,   type
,   quantity
,   unit_measure
,   reference_no
,   std_qty = coalesce(std_qty, dbo.udf_GetStdQtyFromQty(part, quantity, unit_measure))
,   scrap_factor
,   engineering_level
,   operator
,   substitute_part
,   date_changed
,   note
from
	inserted
where
	@tranDT >= coalesce(end_datetime, @tranDT)

--	End records for the same parts that end after these records begin but start before these records end.
update
	dbo.bill_of_material_ec
set
	end_datetime = coalesce ((select min (case when start_datetime > @tranDT then start_datetime end) from inserted where parent_part = bome.parent_part and part = bome.part and start_datetime < bome.end_datetime), @tranDT)
,	LastUser = suser_sname()
,	LastDT = @tranDT
from
	dbo.bill_of_material_ec bome
where
	exists
	(	select
			*
		from
			inserted
		where
			parent_part = bome.parent_part
			and
				part = bome.part
			and
				coalesce (case when start_datetime > @tranDT then start_datetime end, @tranDT) <= coalesce (bome.end_datetime, @tranDT)
	)
	and
		exists
		(	select
				*
			from
				inserted
			where
				parent_part = bome.parent_part
				and
					part = bome.part
				and
					coalesce (case when start_datetime > @tranDT then start_datetime end, @tranDT) > bome.start_datetime
		)
	and
		@tranDT >= coalesce(end_datetime, @tranDT)
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[tr_bill_of_material_ec_u]
on [dbo].[bill_of_material_ec] instead of update
as
set nocount on
declare
	@tranDT datetime

set	@tranDT = getdate()

--	Create new records...

update
	dbo.bill_of_material_ec
set
	end_datetime = @tranDT
,	LastUser = suser_sname()
,	LastDT = @tranDT
where
	ID in (select ID from deleted where @tranDT between start_datetime and coalesce(end_datetime, @tranDT))

insert
	dbo.bill_of_material_ec
(	parent_part
,   part
,   start_datetime
,   end_datetime
,   type
,   quantity
,   unit_measure
,   reference_no
,   std_qty
,   scrap_factor
,   engineering_level
,   operator
,   substitute_part
,   date_changed
,   note
)
select
	parent_part
,   part
,   start_datetime = @tranDT
,   Null
,   type
,   quantity
,   unit_measure
,   reference_no
,   std_qty = coalesce(dbo.udf_GetStdQtyFromQty(part, quantity, unit_measure), std_qty)
,   scrap_factor
,   engineering_level
,   operator
,   substitute_part
,   date_changed
,   note
from
	inserted
where
	@tranDT between start_datetime and coalesce(end_datetime, @tranDT)

--	End old records.
update
	dbo.bill_of_material_ec
set
	end_datetime = @tranDT
,	LastUser = suser_sname()
,	LastDT = @tranDT
where
	ID in (select ID from deleted where @tranDT between start_datetime and coalesce(end_datetime, @tranDT))


GO
ALTER TABLE [dbo].[bill_of_material_ec] ADD CONSTRAINT [PK__bill_of___FBCC7F71164452B1] PRIMARY KEY CLUSTERED  ([parent_part], [part], [start_datetime]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bill_of_material_ec] ADD CONSTRAINT [UQ__bill_of___3214EC261920BF5C] UNIQUE NONCLUSTERED  ([ID]) ON [PRIMARY]
GO
