SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ShopFloor_Production]
	@Operator varchar(5)
,	@WorkOrderNumber varchar(25)
,	@WorkOrderDetailLine float
,	@QtyProduced numeric(20,6)
,	@NewSerial int out
,	@TranDT datetime out
,	@Result int out
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

/*	Record job completion. (dbo.usp_InventoryControl_JobComplete) */
declare
	@ProductionPartCode varchar(25)

set	@ProductionPartCode =
	(
		select
			PartCode
		from
			dbo.WorkOrderDetails
		where
			WorkOrderNumber = @WorkOrderNumber
			and
				Line = @WorkOrderDetailLine
	)

--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_JobComplete'
execute
	@ProcReturn = dbo.usp_InventoryControl_JobComplete
	@Operator = @Operator
,	@WorkOrderNumber = @WorkOrderNumber
,	@WorkOrderDetailLine = @WorkOrderDetailLine
,	@PartCode = @ProductionPartCode
,	@QtyProduced = @QtyProduced
,	@NewSerial = @NewSerial out
,	@TranDT = @TranDT out
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

/*	Create backflush header record. (i1) */
--- <Insert rows="1">
set	@TableName = 'dbo.BackflushHeaders'

insert
	dbo.BackflushHeaders
(
	WorkOrderNumber
,	WorkOrderDetailLine
,	Status
,	Type
,	MachineCode
,	ToolCode
,	PartProduced
,	SerialProduced
,	QtyProduced
,	TranDT
)
select
	WorkOrderNumber = @WorkOrderNumber
,	WorkOrderDetailLine = @WorkOrderDetailLine
,	Status = dbo.udf_StatusValue('dbo.BackflushHeaders', 'New')
,	Type = dbo.udf_TypeValue('dbo.BackflushHeaders', 'Production')
,	MachineCode = woh.MachineCode
,	ToolCode = woh.ToolCode
,	PartProduced = @ProductionPartCode
,	SerialProduced = @NewSerial
,	QtyProduced = @QtyProduced
,	TranDT = @TranDT
from
	dbo.WorkOrderHeaders woh
	join dbo.WorkOrderDetails wod on
		woh.WorkOrderNumber = wod.WorkOrderNumber
where
	woh.WorkOrderNumber = @WorkOrderNumber
	and
		wod.Line = @WorkOrderDetailLine

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

declare
	@BackflushNumber varchar(50)

set	@BackflushNumber =
	(
		select
			BackflushNumber
		from
			dbo.BackflushHeaders
		where
			RowID = scope_identity()
	)
	
--- </Insert>

/*	Perform backflushing of production materials. (dbo.usp_InventoryControl_Backflush) */
--- <Call procName"dbo.usp_InventoryControl_Backflush" >	
set	@CallProcName = 'dbo.usp_InventoryControl_Backflush'
execute
	@ProcReturn = dbo.usp_InventoryControl_Backflush
	@Operator = @Operator
,	@BackflushNumber = @BackflushNumber
,	@TranDT = @TranDT out
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

/*		Add to material allocations' issued quantity and overage quantity. (u*) */
--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderDetailMaterialAllocations'

update
	wodma
set
	QtyIssued =	coalesce(wodma.QtyIssued, 0) + bfd.QtyIssue
,	QtyOverage = coalesce(wodma.QtyOverage, 0) + bfd.QtyOverage
from
	dbo.WorkOrderDetailMaterialAllocations wodma
	join dbo.WorkOrderDetailBillOfMaterials wodbom on
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and
			wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
		and
			wodma.WorkOrderDetailBillOfMaterialLine = wodbom.Line
	join
	(
		select
			ChildPartSequence
		,	QtyIssue = sum(QtyIssue)
		,	QtyOverage = sum(QtyOverage)
		from
			dbo.BackflushDetails bd
		where
			BackflushNumber = @BackflushNumber
		group by
			ChildPartSequence
	) bfd on
		wodbom.ChildPartSequence = bfd.ChildPartSequence
where
	wodma.WorkOrderNumber = @WorkOrderNumber

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

/*	Add to work order's produced quantity. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set
	QtyCompleted = QtyCompleted + @QtyProduced
from
	dbo.WorkOrderDetails wod
where
	WorkOrderNumber = @WorkOrderNumber
	and
		Line = @WorkOrderDetailLine

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

--- </Body>

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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ShopFloor_Production
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
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
