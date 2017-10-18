
/*
Create procedure fx21st.dbo.usp_WorkOrders_CreateSubstituteMaterial
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_WorkOrders_CreateSubstituteMaterial'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_WorkOrders_CreateSubstituteMaterial
end
go

create procedure dbo.usp_WorkOrders_CreateSubstituteMaterial
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
/*	Move sequence of BOMs to make room for substitute. */
--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	ChildPartSequence = wodbom.ChildPartSequence + 1
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

/*	Create substitution. */
/*		Calculate the new line number for substitute material. */
declare
	@NewLine float

set	@NewLine =
	coalesce
	(	(	select
				min(wodbom.Line + wodbom2.Line) / 2
			from
				dbo.WorkOrderDetailBillOfMaterials wodbom
				join dbo.WorkOrderDetailBillOfMaterials wodbom2 on
					wodbom.WorkOrderNumber = wodbom2.WorkOrderNumber
					and
						wodbom.WorkOrderDetailLine = wodbom2.WorkOrderDetailLine
					and
						wodbom.ChildPartSequence > wodbom2.ChildPartSequence
			where
				wodbom2.RowID = @PrimaryBOMID
		)
	,	(
			select
				Line + 1
			from
				dbo.WorkOrderDetailBillOfMaterials
			where
				RowID = @PrimaryBOMID
		)
	)

/*		Create substitute material record. */			
--- <Insert rows="1">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

insert
	dbo.WorkOrderDetailBillOfMaterials
(	WorkOrderNumber
,	WorkOrderDetailLine
,	Line
,	Status
,	Type
,	ChildPart
,	ChildPartSequence
,	ChildPartBOMLevel
,	BillOfMaterialID
,	Suffix
,	QtyPer
,	XQty
,	XScrap
,	SubForRowID
,	SubPercentage
)
select
	WorkOrderNumber
,	WorkOrderDetailLine
,	Line = @NewLine
,	Status =
		case coalesce(@SubstitutionRate, 0)
			when 0 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use Last')
			when 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use First')
			else dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Split')
		end
,	Type
,	ChildPart = @SubstitutePart
,	ChildPartSequence = ChildPartSequence + 1
,	ChildPartBOMLevel = ChildPartBOMLevel + 1
,	BillOfMaterialID = null
,	Suffix
,	QtyPer
,	XQty
,	XScrap
,	SubForRowID = RowID
,	SubPercentage = @SubstitutionRate
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	RowID = @PrimaryBOMID

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
	@Operator varchar(5)
,	@PrimaryBOMID int
,	@SubstitutePart varchar(25)
,	@SubstitutionRate numeric(20,6)

set	@Operator = '01596'
set @PrimaryBOMID = 323
set @SubstitutePart = null
set @SubstitutionRate = null

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_WorkOrders_CreateSubstituteMaterial
	@Operator = @Operator
,	@PrimaryBOMID = @PrimaryBOMID
,	@SubstitutePart = @SubstitutePart
,	@SubstitutionRate = @SubstitutionRate
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

