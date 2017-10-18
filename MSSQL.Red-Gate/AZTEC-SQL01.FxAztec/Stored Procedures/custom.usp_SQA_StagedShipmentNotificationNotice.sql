SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [custom].[usp_SQA_StagedShipmentNotificationNotice]
	@ShipperQualityBatchNumber VARCHAR(50)
,	@NotificationPart VARCHAR(25)
,	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
,	@Email BIT = 1
AS
set nocount on
set ansi_warnings on
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
ELSE BEGIN
	SAVE TRAN @ProcName
END
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
if	object_id('tempdb.dbo.##Temp')is not null begin
	drop table ##Temp
end

select
	[Quality Batch Number] = icqbh.QualityBatchNumber
,	[Quality Hold Part] = icqbo.Part
,	[Container Count] = count(*)
into
	##Temp
from
	dbo.InventoryControl_QualityBatch_Headers icqbh
	join dbo.InventoryControl_QualityBatch_Objects icqbo
		join dbo.object o
			on o.serial = icqbo.Serial
		on icqbh.QualityBatchNumber = icqbo.QualityBatchNumber
where
	icqbh.QualityBatchNumber = @ShipperQualityBatchNumber
	and icqbo.CurrentStatus = 'SQA Hold'--SQA Hold'
	and icqbo.Part = @NotificationPart
group by
	icqbh.QualityBatchNumber
,	icqbo.Part
order by
	1, 2

if	@Email = 1 begin
	declare
		@html nvarchar(max)
	
	select
		@tableName = N'##Temp'

	execute
		FT.usp_TableToHTML
		@tableName = @tableName
	,	@html = @html out
	,	@orderBy = ''
	
	declare
		@EmailBody nvarchar(max)
	,	@EmailHeader nvarchar(max)
	
	select
		@EmailHeader = 'Shipping Quality Alert - Staged Shipment Notice'
	
	select
		@EmailBody =
			N'<H1>' + @EmailHeader + ' - ' + left(convert(varchar, getdate(), 120), 10) + N'</H1>' +
			@html
	
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'FxAlerts'
	,	@recipients = 'jholod@aztecmfgcorp.com;kjohnson@aztecmfgcorp.com;rjohson@aztecmfgcorp.com; Mkroll@aztecmfgcorp.com; RRenya@aztecmfgcorp.com;MCox@aztecmfgcorp.com;RHines@aztecmfgcorp.com;TCole@aztecmfgcorp.com;hi-lo@aztecmfgcorp.com;aboulanger@fore-thought.com'
	, 	@subject = @EmailHeader
	,	@body = @EmailBody
	,	@body_format = 'HTML'

END
ELSE BEGIN
	select
		*
	from
		##Temp t

	SELECT
		'Shipping Quality Alert - Staged Shipment Notice'
END
--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

---	<Return>
set	@Result = 0
RETURN
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
	@Email bit

set	@Email = 0

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_SQA_StagedShipmentNotificationNotice
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Email = @Email

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
