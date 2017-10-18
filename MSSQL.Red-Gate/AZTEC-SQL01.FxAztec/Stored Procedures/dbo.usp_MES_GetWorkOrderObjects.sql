SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_MES_GetWorkOrderObjects]
	@WODID int = null
,	@Serial int = null
,	@Status int = null
,	@TranDT datetime = null out
,	@Result integer = null out
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
declare	@WorkOrderNumber varchar(50)
	
if (@WODID is not null) begin
	set @WorkOrderNumber =	
	(	select	WorkOrderNumber 
		from	dbo.WorkOrderDetails
		where	RowID = @WODID)
	
	if (@Status is null) begin
		select
			Serial
		,	WorkOrderNumber
		,	WorkOrderDetailLine
		,	Status
		,	Type
		,	PartCode
		,	PackageType
		,	OperatorCode
		,	Quantity
		,	CompletionDT
		,	BackflushNumber
		,	UndoBackflushNumber
		,	wodid = @WODID
		from
			dbo.WorkOrderObjects
		where
			WorkOrderNumber = @WorkOrderNumber
	end
	else if (@Status = 0) begin
		select
			Serial
		,	WorkOrderNumber
		,	WorkOrderDetailLine
		,	Status
		,	Type
		,	PartCode
		,	PackageType
		,	OperatorCode
		,	Quantity
		,	CompletionDT
		,	BackflushNumber
		,	UndoBackflushNumber
		,	wodid = @WODID
		from
			dbo.WorkOrderObjects
		where
			WorkOrderNumber = @WorkOrderNumber
			and Status = 0
	end
end
else if (@Serial is not null) begin
	select
		woo.Serial
	,	woo.WorkOrderNumber
	,	woo.WorkOrderDetailLine
	,	woo.Status
	,	woo.Type
	,	woo.PartCode
	,	woo.PackageType
	,	woo.OperatorCode
	,	woo.Quantity
	,	woo.CompletionDT
	,	woo.BackflushNumber
	,	woo.UndoBackflushNumber
	,	wodid = wod.RowID
	from
		dbo.WorkOrderObjects woo join
		dbo.WorkOrderDetails wod on
			 woo.WorkOrderNumber = wod.WorkOrderNumber
			 and woo.WorkOrderDetailLine = wod.Line
	where
		Serial = @Serial
end
--- </Body>

---	<Return>
if	@TranCount = 0 begin
	commit tran @ProcName
end
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
	@ProcReturn = dbo.usp_MES_GetJobDetails
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
