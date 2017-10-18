
/*
Create procedure fx21st.dbo.usp_MES_SchedulePlanningJobs
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_SchedulePlanningJobs'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_SchedulePlanningJobs
end
go

create procedure dbo.usp_MES_SchedulePlanningJobs
	@HorizonEndDT datetime
,	@TranDT datetime out
,	@Result integer out
as
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

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Do an rebuild on XRt. */
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
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

/*	Close completed jobs. */
declare
	@completedJobs table
(	WorkOrderNumber varchar(50)
,	WorkOrderDetailLine float
)

insert
	@completedJobs
select
	mjl.WorkOrderNumber
,	mjl.WorkOrderDetailLine
from
	dbo.MES_JobList mjl
where
	mjl.QtyCompleted >= mjl.QtyRequired
	and mjl.QtyCompleted >= mjl.QtyLabelled

if	exists
	(	select
			*
		from
			@completedJobs
	) begin
	
	--- <Update rows="1+">
	set	@TableName = 'dbo.WorkOrderHeaders'
	
	update
		woh
	set
		Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'Completed')
	from
		dbo.WorkOrderHeaders woh
		join @completedJobs cj
			on cj.WorkOrderNumber = woh.WorkOrderNumber
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
	
	--- <Update rows="1+">
	set	@TableName = 'dbo.WorkOrderDetails'
	
	update
		wod
	set
		Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Completed')
	from
		dbo.WorkOrderDetails wod
		join @completedJobs cj
			on cj.WorkOrderNumber = wod.WorkOrderNumber
			and cj.WorkOrderDetailLine = wod.Line
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
	
end

/*	Calculate new planning requirements. */
set	@HorizonEndDT = coalesce(@HorizonEndDT, getdate() + 7)

declare
	@requirements table
(	ID int not null IDENTITY(1, 1) primary key
,	PartCode varchar(25) not null
,	BillToCode varchar(10) null
,	RequiredDT datetime not null
,	QtyRequired numeric(20,6) not null
,	AccumRequired numeric(20,6)	null
)

declare
	@NOBILLTO char(4)

set	@NOBILLTO = '~~~~'

insert
	@requirements
(	PartCode
,	BillToCode
,	RequiredDT
,	QtyRequired
)
select
	PartCode = fmnm.Part
,	BillToCode = coalesce(oh.customer, @NOBILLTO)
,	RequiredDT = fmnm.RequiredDT
,	QtyRequired = fmnm.Balance
from
	dbo.fn_MES_NetMPS() fmnm
	left join dbo.order_header oh
		on oh.order_no = fmnm.OrderNo
		and oh.blanket_part = fmnm.Part
where
	--fmnm.Balance > 0
	--and
	fmnm.RequiredDT <= @HorizonEndDT
order by
	fmnm.Part
,	oh.customer
,	fmnm.RequiredDT

update
	r
set
	AccumRequired =
	(	select
			sum(QtyRequired)
		from
			@requirements r1
		where
			r1.PartCode = r.PartCode
			and r1.BillToCode = r.BillToCode
			and r1.ID <= r.ID
	)
from
	@requirements r

declare
	@netPlanningRequirements table
(	PartCode varchar(25)
,	BillToCode varchar(10)
,	PrimaryMachineCode varchar(10)
,	RunningMachineCode varchar(10)
,	NewPlanningQty numeric(20,6)
,	NewPlanningDueDT datetime
,	CurrentPlanningWODID integer
,	CurrentPlanningQty numeric(20,6)
)

insert
	@netPlanningRequirements
select
	PartCode = coalesce(requirements.PartCode, jobsRunning.PartCode, jobsPlanning.PartCode)
,	BillToCode = nullif(coalesce(requirements.BillToCode, jobsRunning.BilltoCode, jobsPlanning.BilltoCode), @NOBILLTO)
,	PrimaryMachineCode = min(pmPrimary.machine)
,	RunningMachineCode = min(jobsRunning.RunningMachineCode)
,	NewPlanningQty = case when min(coalesce(jobsRunning.QtyScheduled, 0)) < sum(requirements.QtyRequired) then sum(requirements.QtyRequired) - min(coalesce(jobsRunning.QtyScheduled, 0)) else 0 end
,	NewPlanningDueDT = min(case when coalesce(jobsRunning.QtyScheduled, 0) < requirements.AccumRequired then requirements.RequiredDT end)
,	CurrentPlanningWODID = min(jobsPlanning.WODID)
,   CurrentPlanningQty = min(jobsPlanning.QtyScheduled)
from
	@requirements requirements
	full join
	(	select
			wod.PartCode
		,	BillToCode = coalesce(wod.CustomerCode, @NOBILLTO)
		,	RunningMachineCode = coalesce(min(case when woh.MachineCode = pmPrimary.machine then woh.MachineCode end), min(case when woh.MachineCode != pmPrimary.machine then woh.MachineCode end))
		,	QtyScheduled = sum(case when wod.QtyLabelled > wod.QtyRequired then wod.QtyLabelled else wod.QtyRequired end - wod.QtyCompleted)
		from
			dbo.WorkOrderHeaders woh
			join dbo.WorkOrderDetails wod
				on wod.WorkOrderNumber = woh.WorkOrderNumber
			join dbo.part_machine pmPrimary
				on pmPrimary.part = wod.PartCode
				and pmPrimary.sequence = 1
		where
			woh.Status in
			(	select
	 				sd.StatusCode
	 			from
	 				FT.StatusDefn sd
	 			where
	 				sd.StatusTable = 'dbo.WorkOrderHeaders'
					and sd.StatusName in ('Running')
			)
		group by
			wod.PartCode
		,	wod.CustomerCode
	) jobsRunning
	on jobsRunning.PartCode = requirements.PartCode
		and jobsRunning.BillToCode = requirements.BillToCode
	full join
	(	select
			wod.PartCode
		,	BillToCode = coalesce(wod.CustomerCode, @NOBILLTO)
		,	WODID = max(wod.RowID)
		,	QtyScheduled = sum(wod.QtyRequired - wod.QtyCompleted)
		from
			dbo.WorkOrderHeaders woh
			join dbo.WorkOrderDetails wod
				on wod.WorkOrderNumber = woh.WorkOrderNumber
		where
			woh.Status in
			(	select
	 				sd.StatusCode
	 			from
	 				FT.StatusDefn sd
	 			where
	 				sd.StatusTable = 'dbo.WorkOrderHeaders'
	 				and sd.StatusName = 'New'
			)
		group by
			wod.PartCode
		,	wod.CustomerCode
	) jobsPlanning
	on jobsPlanning.PartCode = coalesce(requirements.PartCode, jobsRunning.PartCode)
		and jobsPlanning.BillToCode = coalesce(requirements.BillToCode, jobsRunning.BillToCode)
	join dbo.part_machine pmPrimary
		on pmPrimary.part = coalesce(requirements.PartCode, jobsRunning.PartCode, jobsPlanning.PartCode)
		and pmPrimary.sequence = 1
group by
	coalesce(requirements.PartCode, jobsRunning.PartCode, jobsPlanning.PartCode)
,	coalesce(requirements.BillToCode, jobsRunning.BilltoCode, jobsPlanning.BillToCode)

/*	Delete jobs that are no longer needed (planning jobs only). */
if	exists
	(	select
			*
		from
			@netPlanningRequirements npr
		where
			npr.CurrentPlanningWODID is not null
			and npr.NewPlanningQty = 0
	) begin
	
	-- <Update rows="1+">
	set	@TableName = 'dbo.WorkOrderDetails'
		
	update
		wod
	set
		Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Deleted')
	from
		dbo.WorkOrderDetails wod
		join @netPlanningRequirements npr
			on npr.CurrentPlanningWODID = wod.RowID
	where
		npr.CurrentPlanningWODID is not null
		and npr.NewPlanningQty = 0
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	-- </Update>
		
	-- <Update rows="1+">
	set	@TableName = 'dbo.WorkOrderHeaders'
	
	update
		woh
	set
		Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'Deleted')
	from
		dbo.WorkOrderHeaders woh
		join dbo.WorkOrderDetails wod
			on woh.WorkOrderNumber = wod.WorkOrderNumber
		join @netPlanningRequirements npr
			on npr.CurrentPlanningWODID = wod.RowID
	where
		npr.CurrentPlanningWODID is not null
		and npr.NewPlanningQty = 0
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	-- </Update>
end

declare newPlanning cursor local for
select
	npr.PartCode
,   npr.BillToCode
,   npr.PrimaryMachineCode
,   npr.NewPlanningQty
,   npr.NewPlanningDueDT
from
	@netPlanningRequirements npr
where
	npr.CurrentPlanningWODID is null
	and npr.NewPlanningQty > 0 

open
	newPlanning

while
	1 = 1 begin
	declare
		@newPlanningWorkOrderNumber varchar(50)
	,	@newPlanningPartCode varchar(25)
	,	@newPlanningBillToCode varchar(10)
	,	@newPlanningMachineCode varchar(25)
	,	@newPlanningPlanningQty numeric(20,6)
	,	@newPlanningDueDT datetime
	
	fetch
		newPlanning
	into
		@newPlanningPartCode
	,	@newPlanningBillToCode
	,	@newPlanningMachineCode
	,	@newPlanningPlanningQty
	,	@newPlanningDueDT
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	set	@newPlanningWorkOrderNumber = null
	--- <Call>
	set	@CallProcName = 'dbo.usp_Scheduling_ScheduleJob'
	execute
		@ProcReturn = dbo.usp_Scheduling_ScheduleJob
		@WorkOrderNumber = @newPlanningWorkOrderNumber out
	,	@Operator = 'mon'
	,	@MachineCode = @newPlanningMachineCode
	,	@ToolCode = null
	,	@ProcessCode = null
	,	@PartCode = @newPlanningPartCode
	,	@NewFirmQty = @newPlanningPlanningQty
	,	@DueDT = @newPlanningDueDT
	,	@TopPart = null
	,	@SalesOrderNo = null
	,	@ShipToCode = null
	,	@BillToCode = @newPlanningBillToCode
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

if	exists
	(	select
			*
		from
			@netPlanningRequirements npr
		where
			npr.CurrentPlanningWODID is not null
			and npr.NewPlanningQty > 0
	) begin
	
	--- <Update rows="1+">
	set	@TableName = '[tableName]'
	
	update
		wod
	set
		QtyRequired = npr.NewPlanningQty
	,	DueDT = npr.NewPlanningDueDT
	from
		dbo.WorkOrderDetails wod
		join @netPlanningRequirements npr
			on npr.CurrentPlanningWODID = wod.RowID
	where
		npr.CurrentPlanningWODID is not null
		and npr.NewPlanningQty > 0
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
end
--- </Body>

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>
---	<Return>
set	@Result = 0
return
	@Result
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

declare
	@HorizonEndDT datetime

set	@HorizonEndDT = dateadd(wk, 6, getdate())

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_SchedulePlanningJobs
	@HorizonEndDT = @HorizonEndDT
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.WorkOrderHeaders woh
	join dbo.WorkOrderDetails wod
		on woh.WorkOrderNumber = wod.WorkOrderNumber
order by
	wod.PartCode
go

--commit
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
