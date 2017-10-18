
/*
Create procedure fx21st.dbo.usp_WorkOrders_ReplaceWODBillOfMaterials
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_WorkOrders_ReplaceWODBillOfMaterials'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_WorkOrders_ReplaceWODBillOfMaterials
end
go

create procedure dbo.usp_WorkOrders_ReplaceWODBillOfMaterials
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
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
/*	Disable triggers to remove rows because triggers aren't working properly. (Refactor)*/
alter table dbo.WorkOrderDetailBillOfMaterials disable trigger all

--- <Delete rows="*">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

delete
	wodbom
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.WorkOrderNumber = @WorkOrderNumber
	and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

/*	Insert WOD BOM.*/
--- <Insert rows="*">
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
)
select
	wod.WorkOrderNumber
,	wod.Line
,	Line = row_number() over (partition by wod.WorkOrderNumber order by xr.Sequence)
,	Status =
		case
			when silp2.InLineTemp = 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Temporary WIP')
			else dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
		end
,	Type = dbo.udf_TypeValue('dbo.WorkOrderDetailBillOfMaterials', 'Material')
,	ChildPart = xr.ChildPart
,	ChildPartSequence = xr.Sequence
,	ChildPartBOMLevel = xr.BOMLevel
,	BillOfMaterialID = xr.BOMID
,	Suffix = null
,	QtyPer = null
,	xr.XQty
,	xr.XScrap
from
	FT.XRt xr
	join dbo.Scheduling_InLineProcess silp
		on silp.TopPartCode = xr.TopPart
		and xr.Hierarchy like silp.Hierarchy + '/%'
		and xr.BOMLevel = silp.BOMLevel + 1
	left join dbo.Scheduling_InLineProcess silp2
		 on silp2.TopPartCode = xr.TopPart
		 and silp2.Sequence = xr.Sequence
	join dbo.WorkOrderDetails wod
		on wod.PartCode = xr.TopPart
where
	WorkOrderNumber = @WorkOrderNumber
	and	Line = @WorkOrderDetailLine
order by
	wod.WorkOrderNumber
,	wod.Line
,	xr.Sequence

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

alter table dbo.WorkOrderDetailBillOfMaterials enable trigger all
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
	@ProcReturn = dbo.usp_WorkOrders_ReplaceWODBillOfMaterials
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

