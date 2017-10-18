SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_GetReceiverInstructions]
	@ReceiverID int = null
,	@ReceiverNumber varchar(50) = null
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
	rdria.ReceiverID
,	StepPrecedence = row_number() over (partition by rdria.ReceiverID order by rdria.StepPrecedence)
,	rdria.ReceiverNumber
,	rdria.Type
,	rdria.TypeName
,	rdria.Status
,	rdria.StatusName
,	rdria.OriginType
,	rdria.OriginTypeName
,	rdria.SupplierLabelComplianceStatus
,	rdria.SupplierLabelComplianceStatusName
,	rdria.StepType
,	rdria.StepTypeName
,	rdria.StepTypeDescription
,	rdria.StepStatus
,	rdria.StepStatusName
from
	dbo.ReceivingDock_ReceiverInstructions_All rdria
where
	rdria.ReceiverID = @ReceiverID
	or rdria.ReceiverNumber = @ReceiverNumber
order by
	rdria.ReceiverID desc
,	rdria.StepPrecedence
--- </Body>

---	<CloGetRan AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloGetRan AutoCommit=Yes>

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
	@ReceiverID int

set	@ReceiverID = 5875

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ReceivingDock_GetReceiverInstructions
	@ReceiverID = @ReceiverID
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
