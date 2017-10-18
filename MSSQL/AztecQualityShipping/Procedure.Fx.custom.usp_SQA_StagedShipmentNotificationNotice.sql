
/*
Create Procedure.Fx.custom.usp_SQA_StagedShipmentNotificationNotice.sql
*/

--use Fx
--go

if	objectproperty(object_id('custom.usp_SQA_StagedShipmentNotificationNotice'), 'IsProcedure') = 1 begin
	drop procedure custom.usp_SQA_StagedShipmentNotificationNotice
end
go

create procedure custom.usp_SQA_StagedShipmentNotificationNotice
	@ShipperQualityBatchNumber varchar(50)
,	@NotificationPart varchar(25)
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Email bit = 1
as
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
else begin
	save tran @ProcName
end
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
	and icqbo.CurrentStatus = ''--SQA Hold'
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
	
	exec msdb.dbo.sp_send_dbmail
		@profile_name = 'DoNotReply'
	,	@recipients = 'estimpson@fore-thought.com'
	, 	@subject = @EmailHeader
	,	@body = @EmailBody
	,	@body_format = 'HTML'

end
else begin
	select
		*
	from
		##Temp t

	select
		'Shipping Quality Alert - Staged Shipment Notice'
end
--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

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
go

