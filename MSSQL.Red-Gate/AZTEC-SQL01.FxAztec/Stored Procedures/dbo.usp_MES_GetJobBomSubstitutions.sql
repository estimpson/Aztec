SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_GetJobBomSubstitutions]
	@WODBOMID int
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
select
	mbjs.WorkOrderNumber
,	mbjs.WODID
,	mbjs.WorkOrderDetailLine
,	mbjs.WODBOMID
,	mbjs.ParentPartCode
,	mbjs.PrimaryPartCode
,	mbjs.PrimaryCommodity
,	mbjs.PrimaryDescription
,	mbjs.PrimaryXQty
,	mbjs.PrimaryXScrap
,	mbjs.PrimaryBOMID
,	mbjs.SubstitutePartCode
,	mbjs.SubstituteCommodity
,	mbjs.SubstituteDescription
,	mbjs.SubstituteXQty
,	mbjs.SubstituteXScrap
,	mbjs.SubstituteBOMID
,	mbjs.SubstitutionType
,	mbjs.SubstitutionRate
from
	dbo.MES_BOMJobSubstitution mbjs
where
	mbjs.WODBOMID = @WODBOMID

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
	@WODID int
,	@WODBOMID int

set	@WODID = 28
set	@WODBOMID = 3

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_GetJobBomSubstitutions
	@WODID = @WODID
,	@WODBOMID = @WODBOMID
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
