
/*
Create procedure fx21st.dbo.usp_WorkOrders_EditSubstituteMaterial
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_WorkOrders_EditSubstituteMaterial'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_WorkOrders_EditSubstituteMaterial
end
go

create procedure dbo.usp_WorkOrders_EditSubstituteMaterial
	@Operator varchar(5)
,	@PrimaryBOMID int
,	@SubstitutePart varchar(25)
,	@SubstitutionRate numeric(20,6)
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

--- <Tran Required=Yes AutoEdit=Yes TranDTParm=Yes>
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
/*	Move sequence of BOMs to make room for substitute. */
/*		Edit substitute material record. */			
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	Status =
		case coalesce(@SubstitutionRate, 0)
			when 0 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use Last')
			when 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use First')
			else dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Split')
		end
,	ChildPart = @SubstitutePart
,	SubPercentage = @SubstitutionRate
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	SubForRowID = @PrimaryBOMID
	and Status >= 0

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
	RAISERROR ('Error updating table %s in procedure %s.  Rows updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

/*		Set status of primary to "User First", "Use Last", or "Split". */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	Status = 
		case coalesce(@SubstitutionRate, 0)
			when 0 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use First')
			when 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use Last')
			else dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Split')
		end
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	RowID = @PrimaryBOMID
	and Status >= 0

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
	@ProcReturn = dbo.usp_WorkOrders_EditSubstituteMaterial
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

