SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_GetReceiverObjects_forLines]
	@ReceiverNumber varchar(50) = null
,	@ReceiverLineIDList varchar(max) = null
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
	ro.ReceiverObjectID
,	ro.ReceiverLineID
,	ObjectNo = ro.[LineNo]
,	ro.Status
,	ro.PONumber
,	ro.POLineNo
,	ro.POLineDueDate
,	ro.Serial
,	ro.PartCode
,	ro.PartDescription
,	ro.EngineeringLevel
,	ro.QtyObject
,	ro.PackageType
,	ro.Location
,	ro.Plant
,	ro.ParentSerial
,	ro.DrAccount
,	ro.CrAccount
,	ro.Lot
,	ro.Note
,	QualityAlertFlag = p.quality_alert
,	ro.UserDefinedStatus
,	ro.ReceiveDT
,	ro.SupplierLicensePlate
from
	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl
		on rl.ReceiverLineID = ro.ReceiverLineID
	join dbo.ReceiverHeaders rh
		on rh.ReceiverID = rl.ReceiverID
	left join dbo.part p
		on p.part = ro.PartCode
where
	rh.ReceiverNumber = isnull(@ReceiverNumber, rh.ReceiverNumber)
	and
	(	rl.ReceiverLineID in
			(	select
					fsstr.Value
				from
					dbo.fn_SplitStringToRows(@ReceiverLineIDList, ',') fsstr
			)
		or @ReceiverLineIDList is null
	)
order by
	2, 3
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

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
	@ProcReturn = dbo.usp_ReceivingDock_GetReceiverObjects_forLines
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
