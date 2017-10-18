SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_WorkOrders_CreateWorkOrderDetails]
	@WorkOrderNumber varchar(50)
,	@Status int = null
,	@Type int = null
,	@User varchar(5)
,	@ProcessCode varchar(25) = null
,	@PartCode varchar(25) = null
,	@NextBuildQty numeric(20,6)
,	@DueDT datetime
,	@TopPart varchar(25)
,	@SalesOrderNo int = null
,	@ShipToCode varchar(20) = null
,	@BillToCode varchar(20) = null
,	@TranDT datetime out
,	@Result integer out
as
/*
Example:
Initial queries {
}

Test syntax {
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
	@ProcReturn = dbo.usp_WorkOrders_CreateWorkOrderDetails
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

rollback
go

}

Results {
}
*/
--SET QUOTED_IDENTIFIER ON|OFF
--SET ANSI_NULLS ON|OFF
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
/*	Get next sequence.  Next sequence depends on whether another line has the same process code. */
declare
	@NextSequence int

set
	@NextSequence = coalesce
	(
		(
			select
				max(Sequence)
			from
				dbo.WorkOrderDetails
			where
				WorkOrderNumber = @WorkOrderNumber
				and
					ProcessCode = @ProcessCode
				and
					PartCode != @PartCode
		)
	,	(
			select
				max(Sequence) + 1
			from
				dbo.WorkOrderDetails
			where
				WorkOrderNumber = @WorkOrderNumber
		)
	,	1
	)

/*	Get next line.  Next line is sequence or a number within a sequence when a process code is use. */
declare
	@NextLine float

set
	@NextLine = coalesce
	(
		(
			select
				max(Line + (floor(Line + 1) - Line) / 2)
			from
				dbo.WorkOrderDetails
			where
				WorkOrderNumber = @WorkOrderNumber
				and
					Sequence = @NextSequence
		)
	,	@NextSequence
	)		

/*	Create work order detail. */
--- <Insert rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

insert
	dbo.WorkOrderDetails
(
	WorkOrderNumber
,	Line
,	Status
,	Type
,	ProcessCode
,	TopPartCode
,	PartCode
,	Sequence
,	DueDT
,	QtyRequired
,	SetupHours
,	PartsPerHour
,	PartsPerCycle
,	CycleSeconds
,	SalesOrderNumber
,	DestinationCode
,	CustomerCode
)
select
	WorkOrderNumber = @WorkOrderNumber
,	Line = @NextLine
,	Status = coalesce(@Status, dbo.udf_StatusValue('dbo.WorkOrderDetails', 'New'))
,	Type = coalesce(@Type, dbo.udf_TypeValue('dbo.WorkOrderDetails', 'Firm'))
,	ProcessCode = @ProcessCode
,	TopPartCode = @TopPart
,	PartCode = @PartCode
,	Sequence = @NextSequence
,	DueDT = @DueDT
,	QtyRequired = @NextBuildQty
,	SetupHours = coalesce
	(
		(select setup_time from dbo.part_machine where part = @PartCode and machine = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber))
	,	0
	)
,	PartsPerHour = coalesce
	(
		(select parts_per_hour from dbo.part_machine where part = @PartCode and machine = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber))
	,	1
	)
,	PartsPerCycle = coalesce
	(
		(select parts_per_cycle from dbo.part_machine where part = @PartCode and machine = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber))
	,	1
	)
,	CycleSeconds = coalesce
	(
		(select 3600.0 * parts_per_cycle / nullif(parts_per_hour, 0) from dbo.part_machine where part = @PartCode and machine = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber))
	,	1
	)
,	SalesOrderNumber = @SalesOrderNo
,	DestinationCode = @ShipToCode
,	CustomerCode = @BillToCode

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

/*	Create BOM for this work order detail. */
--- <Call>	
set	@CallProcName = 'dbo.usp_WorkOrders_CreateWODBillOfMaterials'
execute
	@ProcReturn = dbo.usp_WorkOrders_CreateWODBillOfMaterials
	@WorkOrderNumber = @WorkOrderNumber
,	@WorkOrderDetailLine = @NextLine
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_WorkOrders_CreateWorkOrderDetails
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

rollback
go

}

Results {
}
*/
GO
