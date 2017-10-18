
/*
Create procedure fx21st.dbo.usp_WorkOrders_DeleteSubstituteMaterial
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_WorkOrders_DeleteSubstituteMaterial'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_WorkOrders_DeleteSubstituteMaterial
end
go

create procedure dbo.usp_WorkOrders_DeleteSubstituteMaterial
	@Operator varchar(5)
,	@PrimaryBOMID int
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

--- <Tran Required=Yes AutoDelete=Yes TranDTParm=Yes>
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
/*	Delete substitution. */
/*		Delete substitute material record. */			
declare
	@substituteSequence table
(	Sequence int
)

--- <Delete rows="1">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

delete
	wodbom
output
	deleted.ChildPartSequence into @substituteSequence
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.SubForRowID = @PrimaryBOMID
	and wodbom.Status >= 0
	

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Delete>

/*		Set status of primary to "Used." */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	RowID = @PrimaryBOMID

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

/*	Move sequence of BOMs to remove room reserved for substitute. */
--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	ChildPartSequence = wodbom.ChildPartSequence - 1
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
	join dbo.WorkOrderDetailBillOfMaterials wodbom2 on
		wodbom.WorkOrderNumber = wodbom2.WorkOrderNumber
		and wodbom.WorkOrderDetailLine = wodbom2.WorkOrderDetailLine
		and wodbom.ChildPartSequence > wodbom2.ChildPartSequence
where
	wodbom2.RowID = @PrimaryBOMID

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
	@ProcReturn = dbo.usp_WorkOrders_DeleteSubstituteMaterial
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
go

