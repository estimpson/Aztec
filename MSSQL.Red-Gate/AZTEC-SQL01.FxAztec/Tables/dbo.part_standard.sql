CREATE TABLE [dbo].[part_standard]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [numeric] (20, 6) NULL,
[cost] [numeric] (20, 6) NULL,
[account_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material] [numeric] (20, 6) NULL,
[labor] [numeric] (20, 6) NULL,
[burden] [numeric] (20, 6) NULL,
[other] [numeric] (20, 6) NULL,
[cost_cum] [numeric] (20, 6) NULL,
[material_cum] [numeric] (20, 6) NULL,
[burden_cum] [numeric] (20, 6) NULL,
[other_cum] [numeric] (20, 6) NULL,
[labor_cum] [numeric] (20, 6) NULL,
[flag] [int] NULL,
[premium] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qtd_cost] [numeric] (20, 6) NULL,
[qtd_material] [numeric] (20, 6) NULL,
[qtd_labor] [numeric] (20, 6) NULL,
[qtd_burden] [numeric] (20, 6) NULL,
[qtd_other] [numeric] (20, 6) NULL,
[qtd_cost_cum] [numeric] (20, 6) NULL,
[qtd_material_cum] [numeric] (20, 6) NULL,
[qtd_labor_cum] [numeric] (20, 6) NULL,
[qtd_burden_cum] [numeric] (20, 6) NULL,
[qtd_other_cum] [numeric] (20, 6) NULL,
[planned_cost] [numeric] (20, 6) NULL,
[planned_material] [numeric] (20, 6) NULL,
[planned_labor] [numeric] (20, 6) NULL,
[planned_burden] [numeric] (20, 6) NULL,
[planned_other] [numeric] (20, 6) NULL,
[planned_cost_cum] [numeric] (20, 6) NULL,
[planned_material_cum] [numeric] (20, 6) NULL,
[planned_labor_cum] [numeric] (20, 6) NULL,
[planned_burden_cum] [numeric] (20, 6) NULL,
[planned_other_cum] [numeric] (20, 6) NULL,
[frozen_cost] [numeric] (20, 6) NULL,
[frozen_material] [numeric] (20, 6) NULL,
[frozen_burden] [numeric] (20, 6) NULL,
[frozen_labor] [numeric] (20, 6) NULL,
[frozen_other] [numeric] (20, 6) NULL,
[frozen_cost_cum] [numeric] (20, 6) NULL,
[frozen_material_cum] [numeric] (20, 6) NULL,
[frozen_burden_cum] [numeric] (20, 6) NULL,
[frozen_labor_cum] [numeric] (20, 6) NULL,
[frozen_other_cum] [numeric] (20, 6) NULL,
[cost_changed_date] [datetime] NULL,
[qtd_changed_date] [datetime] NULL,
[planned_changed_date] [datetime] NULL,
[frozen_changed_date] [datetime] NULL,
[os_cost] [numeric] (20, 6) NULL,
[os_cost_cum] [numeric] (20, 6) NULL,
[os_qtd_cost] [numeric] (20, 6) NULL,
[os_qtd_cost_cum] [numeric] (20, 6) NULL,
[os_planned_cost] [numeric] (20, 6) NULL,
[os_planned_cost_cum] [numeric] (20, 6) NULL,
[os_frozen_cost] [numeric] (20, 6) NULL,
[os_frozen_cost_cum] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_part_standard_MaterialCostChangeLog_iud] on [dbo].[part_standard] after insert, update, delete
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

	---	<Paring>
	if	not exists
		(	select
				*
			from
				Inserted
		)
		and not exists
		(	select
				*
			from
				Deleted
		) return
	---	</Paring>
	
	--- <Body>
	insert
		custom.MaterialCostChangeLog
	(	Type
	,	Part
	,	OriginalMaterialCost
	,	NewMaterialCost
	)
	select
		Type = case when i.part is null then '-1' when d.part is null then '1' else '0' end
	,	Part = coalesce(i.part, d.part)
	,	OriginalMaterialCost = (d.material)
	,	NewMaterialCost = (i.material)
	from
		Inserted i
		full join Deleted d
			on i.part = d.part

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
	dbo.part_standard
...

update
	...
from
	dbo.part_standard
...

delete
	...
from
	dbo.part_standard
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
ALTER TABLE [dbo].[part_standard] ADD CONSTRAINT [PK__part_standard__0EC32C7A] PRIMARY KEY CLUSTERED  ([part]) ON [PRIMARY]
GO
