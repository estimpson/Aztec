
if	objectproperty(object_id('dbo.usp_WorkOrders_CreateNextBuildWorkOrderHeader'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_WorkOrders_CreateNextBuildWorkOrderHeader
end
go

create procedure dbo.usp_WorkOrders_CreateNextBuildWorkOrderHeader
	@WorkOrderNumber varchar(50) out
,	@User varchar(5)
,	@MachineCode varchar(15)
,	@ToolCode varchar(60)
,	@ProcessCode varchar(25) = null
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
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Create work order header. */
--- <Insert rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

insert
	dbo.WorkOrderHeaders
(
	WorkOrderNumber
,	Status
,	Type
,	MachineCode
,	ToolCode
,	Sequence
)
select
	WorkOrderNumber = coalesce(@WorkOrderNumber, 0)
,	Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'New')
,	Type = dbo.udf_TypeValue('dbo.WorkOrderHeaders', 'Planning')
,	MachineCode = @MachineCode
,	ToolCode = @ToolCode
,	Sequence = coalesce
	(
		(
			select
				max(Sequence)
			from
				dbo.WorkOrderHeaders
			where
				MachineCode = @MachineCode
		) + 1
	,	1
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
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Get new WorkOrderNumber. */
select
	@WorkOrderNumber = WorkOrderNumber
from
	dbo.WorkOrderHeaders woh
where
	RowID = scope_identity()

--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries {
}

Test syntax {

declare
	@WorkOrderNumber varchar(50)
,	@User varchar(5)
,	@MachineCode varchar(15)
,	@ToolCode varchar(60)
,	@ProcessCode varchar(25)

set	@User = 'mon'
set	@MachineCode = '3'
set	@ToolCode = null
set	@ProcessCode = null

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_WorkOrders_CreateNextBuildWorkOrderHeader
	@WorkOrderNumber = @WorkOrderNumber out
,	@User = @User
,	@MachineCode = @MachineCode
,	@ToolCode = @ToolCode
,	@ProcessCode = @ProcessCode
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@WorkOrderNumber, @Error, @ProcReturn, @TranDT, @ProcResult
select
	*
from
	dbo.WorkOrderHeaders woh
where
	woh.WorkOrderNumber = @WorkOrderNumber
go

rollback
go

}

Results {
}
*/
go

