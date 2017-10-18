SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_WorkOrders_CreateFirmWorkOrderHeader]
	@WorkOrderNumber varchar(50) out
,	@Operator varchar(5)
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
,	Type = dbo.udf_TypeValue('dbo.WorkOrderHeaders', 'Firm')
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_WorkOrders_CreateFirmWorkOrderHeader
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
