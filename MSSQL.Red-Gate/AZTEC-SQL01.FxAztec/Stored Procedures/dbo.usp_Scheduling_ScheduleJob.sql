SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_Scheduling_ScheduleJob]
	@WorkOrderNumber varchar(50) = null out
,	@Operator varchar(5)
,	@MachineCode varchar(15)
,	@ToolCode varchar(60)
,	@ProcessCode varchar(25) = null
,	@PartCode varchar(25)
,	@NewFirmQty numeric(20,6)
,	@DueDT datetime
,	@TopPart varchar(25)
,	@SalesOrderNo int = null
,	@ShipToCode varchar(20) = null
,	@BillToCode varchar(20) = null
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
/*	Validate WorkOrderNumber if specified. */
if	@WorkOrderNumber is not null 
	and
		exists
		(	select
				*
			from
				dbo.WorkOrderHeaders woh
			where
				WorkOrderNumber = @WorkOrderNumber
		) begin
	
/*		Status must not be reconciled or deleted. */
	declare
		@WorkOrderStatusName varchar(25)
	set @WorkOrderStatusName =
		(	select
				dbo.udf_StatusValue('WorkOrderHeaders', Status)
			from
				dbo.WorkOrderHeaders woh
			where
				WorkOrderNumber = @WorkOrderNumber
		)
	
	if	@WorkOrderStatusName in
		(
			'Reconciled'
		,	'Deleted'
		) begin
	
		set	@Result = 999999
		RAISERROR ('Error validing @WorkOrderNumber(%d) in procedure %s.  Work order status is %s', 16, 1, @WorkOrderNumber, @ProcName, @WorkOrderStatusName)
		rollback tran @ProcName
		return @Result
	end
end

---	</ArgumentValidation>

--- <Body>
/*	If WorkOrderNumber not specified or specified WorkOrderNumber does not exist... */
if	@WorkOrderNumber is null
	or
		not exists
		(	select
				*
			from
				dbo.WorkOrderHeaders woh
			where
				WorkOrderNumber = @WorkOrderNumber
		) begin

/*		Create a new work order header. */
	--- <Call>	
	set	@CallProcName = 'dbo.usp_WorkOrders_CreateFirmWorkOrderHeader'
	execute
		@ProcReturn = dbo.usp_WorkOrders_CreateFirmWorkOrderHeader
			@WorkOrderNumber = @WorkOrderNumber out
		,	@Operator = @Operator
		,	@MachineCode = @MachineCode
		,	@ToolCode = @ToolCode
		,	@ProcessCode = @ProcessCode
		,	@TranDT = @TranDT out
		,	@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@WorkOrderNumber is null begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	--- </Call>
end

/*	Create work order details. */
--- <Call>	
set	@CallProcName = 'dbo.usp_WorkOrders_CreateWorkOrderDetails'
execute
	@ProcReturn = dbo.usp_WorkOrders_CreateWorkOrderDetails
		@WorkOrderNumber = @WorkOrderNumber
	,	@Status = null
	,	@Type = null
	,	@User = @Operator
	,	@ProcessCode = @ProcessCode
	,	@PartCode = @PartCode
	,	@NextBuildQty = @NewFirmQty
	,	@DueDT = @DueDT
	,	@TopPart = @TopPart
	,	@SalesOrderNo = @SalesOrderNo
	,	@ShipToCode = @ShipToCode
	,	@BillToCode = @BillToCode
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@WorkOrderNumber is null begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return @Result
end
--- </Call>
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
Test queries
{

select
	*
	,	TopPart = (select max(part_number) from order_detail where part_number in (select TopPart from FT.XRt where ChildPart = wd.part) and order_no = coalesce(wo.order_no, order_no))
from
	dbo.work_order wo
	join dbo.workorder_detail wd on
		wo.work_order = wd.workorder

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@NewWorkOrderNumber varchar(50)
,	@Operator varchar(5)
,	@MachineCode varchar(15)
,	@ToolCode varchar(60)
,	@ProcessCode varchar(25)
,	@PartCode varchar(25)
,	@NewFirmQty numeric(20,6)
,	@DueDT datetime
,	@TopPart varchar(25)
,	@SalesOrderNo int
,	@ShipToCode varchar(20)
,	@BillToCode varchar(20)

set	@NewWorkOrderNumber = null
set	@Operator = 'mon'
set	@MachineCode = 'PRESS 28A'
set	@ToolCode = '1367 CAVITY | 1372 MOLDBASE'
set	@ProcessCode = null
set	@PartCode = '1-534035-6M_1367_1'
set	@NewFirmQty = 1010
set	@DueDT = '2010-05-03 00:00:00.000'
set	@TopPart = '1-534035-6_1367_1'
set	@SalesOrderNo = 10747
set	@ShipToCode = 'AMP'
set	@BillToCode = '909/SC'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_Scheduling_ScheduleJob
	@WorkOrderNumber = @NewWorkOrderNumber out
,	@Operator = @Operator
,	@MachineCode = @MachineCode
,	@ToolCode = @ToolCode
,	@ProcessCode = @ProcessCode
,	@PartCode = @PartCode
,	@NewFirmQty = @NewFirmQty 
,	@DueDT = @DueDT
,	@TopPart = @TopPart
,	@SalesOrderNo = @SalesOrderNo
,	@ShipToCode = @ShipToCode
,	@BillToCode = @BillToCode
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	[@Error] = @Error, [@ProcReturn] = @ProcReturn, [@TranDT] = @TranDT, [@ProcResult] = @ProcResult, [@NewWorkOrderNumber] = @NewWorkOrderNumber

select
	*
from
	dbo.WorkOrderHeaders woh
where
	WorkOrderNumber = @NewWorkOrderNumber

select
	*
from
	dbo.WorkOrderDetails wod
where
	WorkOrderNumber = @NewWorkOrderNumber

select
	*
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	WorkOrderNumber = @NewWorkOrderNumber

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
