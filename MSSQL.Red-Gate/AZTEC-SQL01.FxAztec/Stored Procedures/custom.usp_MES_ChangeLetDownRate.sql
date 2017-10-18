SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [custom].[usp_MES_ChangeLetDownRate]
	@Operator varchar (10)
,	@WODID int
,	@NewLetDownRate numeric(20,6)
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. custom.usp_Test
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
/*	Adujst the BOM consumption of the base material and colorant based on the new let down rate. */
--- <Update rows="2">
set	@TableName = 'dbo.WorkOrderDetailBillOfMaterials'

update
	wodbom
set
	XQty =
		case wodbom.BillOfMaterialID
			when mmjcld.BaseMaterialBOMID then mmjcld.PieceWeight * (1 - @NewLetDownRate)
			when mmjcld.ColorantMaterialBOMID then mmjcld.PieceWeight * @NewLetDownRate
		end
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = wodbom.WorkOrderNumber
		and wod.Line = wodbom.WorkOrderDetailLine
	join custom.MES_MoldingJobColorLetDown mmjcld
		on mmjcld.WODID = wod.RowID
		and wodbom.BillOfMaterialID in
			(	mmjcld.BaseMaterialBOMID
			,	mmjcld.ColorantMaterialBOMID
			)
where
	wod.RowID = @WODID

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 2 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 2.', 16, 1, @TableName, @ProcName, @RowCount)
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
	@Operator varchar (10)
,	@WODID int
,	@NewLetDownRate numeric(20,6)

set	@Operator = '01956'
set	@WODID = 28
set	@NewLetDownRate = .03

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_MES_ChangeLetDownRate
	@Operator = @Operator
,	@WODID = @WODID
,	@NewLetDownRate = @NewLetDownRate
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
