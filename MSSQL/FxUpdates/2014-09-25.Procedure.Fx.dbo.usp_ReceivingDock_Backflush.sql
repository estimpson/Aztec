
/*
Create Procedure.Fx.dbo.usp_ReceivingDock_Backflush.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_ReceivingDock_Backflush'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_ReceivingDock_Backflush
end
go

create procedure dbo.usp_ReceivingDock_Backflush
	@Operator varchar(5)
,	@BackflushNumber varchar(50)
,	@ReceiverObjectID int
,	@TranDT datetime out
,	@Result integer out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
    @CallProcName sysname
,	@TableName sysname
,	@ProcName sysname
,	@ProcReturn integer
,	@ProcResult integer
,	@Error integer
,	@RowCount integer

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
/*	Calculate quantity to issue. */
declare
	@WODID int
,	@workOrderNumber varchar(50)
,	@workOrderDetailLine float
,	@qtyRequested numeric(20,6)

select
	@WODID = wod.RowID
,	@workOrderNumber = bh.WorkOrderNumber
,	@workOrderDetailLine = bh.WorkOrderDetailLine
,	@qtyRequested = bh.QtyProduced
from
	dbo.BackflushHeaders bh
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = bh.WorkOrderNumber
		and wod.Line = bh.WorkOrderDetailLine
where
	BackflushNumber = @BackflushNumber

declare
	@InventoryConsumption table
(
	Serial int
,	PartCode varchar(25)
,	BOMLevel tinyint
,	Sequence tinyint
,	Suffix int
,	ChildPartSequence int
,	ChildPartBOMLevel int
,	BillOfMaterialID int
,	AllocationDT datetime
,	QtyPer float
,	QtyAvailable float
,	QtyRequired float
,	QtyIssue float
,	QtyOverage float
)

insert
	@InventoryConsumption
(	Serial
,	PartCode
,	BOMLevel
,	Sequence
,	Suffix
,	ChildPartSequence
,	ChildPartBOMLevel
,	BillOfMaterialID
,	AllocationDT
,	QtyPer
,	QtyAvailable
,	QtyRequired
,	QtyIssue
,	QtyOverage
)
select
	Serial
,	PartCode
,	BOMLevel
,	Sequence
,	Suffix
,	ChildPartSequence
,	ChildPartBOMLevel
,	BillOfMaterialID
,	AllocationDT
,	QtyPer
,	QtyAvailable
,	QtyRequired
,	QtyIssue
,	QtyOverage
from
	dbo.fn_ReceivingDock_GetBackflushDetails(@BackflushNumber) ugbd

/*	Loop through overages. */
--- <DefineCursor curosrName="overages">
declare
	@overageSerial int
,	@qtyOverage numeric(20,6)

declare overages cursor local for
select
	Serial
,	QtyOverage = sum(QtyOverage)
from
	@InventoryConsumption ic
where
	Serial > 0
	and QtyOverage > 0
group by
	Serial

open
	overages

fetch
	overages
into
	@overageSerial
,	@qtyOverage

while
	@@fetch_status = 0 begin

	--- <LoopBody>
/*		Record quantity discrepancy for overage (dbo.usp_ReceivingDock_NewExcessQty) */
	--- <Call procName="dbo.usp_ReceivingDock_NewExcessQty" >	
	set	@CallProcName = 'dbo.usp_ReceivingDock_NewExcessQty'
	execute
		@ProcReturn = dbo.usp_ReceivingDock_NewExcessQty
		@Operator = @Operator
	,	@ReceiverObjectID = @ReceiverObjectID
	,	@Serial = @overageSerial
	,	@QtyExcess = @qtyOverage
	,	@ExcessReason = 'Excess due to receiving backflush.'
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
	
	--- </LoopBody>
	fetch
		overages
	into
		@overageSerial
	,	@qtyOverage
end

close
	overages

deallocate
	overages
--- </DefineCursor>

/*	Loop through material issues. */
--- <DefineCursor curosrName="materialIssues">
declare
	@issueSerial int
,	@qtyIssue numeric(20,6)

declare materialIssues cursor local for
select
	Serial
,	QtyIssue = sum(QtyIssue)
from
	@InventoryConsumption ic
where
	Serial > 0
	and
		QtyIssue > 0
group by
	Serial

open
	materialIssues

fetch
	materialIssues
into
	@issueSerial
,	@qtyIssue

while
	@@fetch_status = 0 begin

	--- <LoopBody>
/*		Write material issues. (dbo.usp_InventoryControl_MaterialIssue) */
	--- <Call procName"dbo.usp_InventoryControl_MaterialIssue" >	
	set	@CallProcName = 'dbo.usp_InventoryControl_MaterialIssue'
	execute
		@ProcReturn = dbo.usp_InventoryControl_MaterialIssue
		@Operator = @Operator
	,	@Serial = @issueSerial
	,	@QtyIssue = @qtyIssue
	,	@WorkOrderNumber = @workOrderNumber
	,	@Notes = 'Material issue by backflush.'
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
	
	--- </LoopBody>
	fetch
		materialIssues
	into
		@issueSerial
	,	@qtyIssue
end

close
	materialIssues

deallocate
	materialIssues
--- </DefineCursor>

/*	Record back flush details. (i*) */
--- <Insert rows="*">
set	@TableName = 'dbo.BackflushDetails'

insert
	dbo.BackflushDetails
(	BackflushNumber
,	Line
,	Status
,	Type
,	ChildPartSequence
,	ChildPartBOMLevel
,	BillOfMaterialID
,	PartConsumed
,	SerialConsumed
,	QtyAvailable
,	QtyRequired
,	QtyIssue
,	QtyOverage
)
select
	BackflushNumber = @BackflushNumber
,	Line = row_number() over (order by ic.Sequence, ic.AllocationDT)
,	Status = dbo.udf_StatusValue('dbo.BackflushDetails', 'New')
,	Type =
	case
		when ic.QtyOverage > 0 then dbo.udf_TypeValue('dbo.BackflushDetails', 'Overage Consumption')
		else dbo.udf_TypeValue('dbo.BackflushDetails', 'Consumption')
	end
,	ChildPartSequence = ic.Sequence
,	ChildPartBOMLevel = ic.BOMLevel
,	BillOfMaterialID = ic.BillOfMaterialID
,	PartConsumed = ic.PartCode
,	SerialConsumed = ic.Serial
,	QtyAvailable = ic.QtyAvailable
,	QtyRequired = ic.QtyRequired
,	QtyIssue = ic.QtyIssue
,	QtyOverage = ic.QtyOverage
from
	@InventoryConsumption ic
where
	ic.Serial > 0
	and ic.QtyIssue > 0
order by
	ic.Sequence
,	ic.AllocationDT

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
	@Operator varchar(5)
,	@BackflushNumber varchar(50)

set	@Operator = '619'
set @BackflushNumber = 'BF_0000000014'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ReceivingDock_Backflush
	@Operator = @Operator
,	@BackflushNumber = @BackflushNumber
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.BackflushHeaders bh
where
	bh.BackflushNumber = @BackflushNumber

select
	*
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = @BackflushNumber
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
GO
