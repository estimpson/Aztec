SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[usp_EMailReceiptsCurrentlyOnHoldTransactionSummary]
--	@Param1 [scalar_data_type] ( = [default_value] ) ...
	@TranDT DATETIME OUT
,	@Result INTEGER OUT
AS
set nocount on
set ansi_warnings off
set	@Result = 999999
set	ansi_warnings ON

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname  = N'#ReceiptTransactionsRemainingOnHold',
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. <schema_name, sysname, dbo>.usp_Test
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

declare
	@DayTimePrior datetime
	
	select @DayTimePrior = dateadd(HOUR,-8, getdate())
	
	--Get Audit Trail for Receipt Tranactions
	
		
	select 
		a.serial,
		a.date_stamp as DateReceived,
		CurrentObject.location as FxLocation,
		a.part, 
		p.name,
		coalesce(e.name, a.operator) as Employee,
		case a.from_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else 'On Hold'
		end as FromStatus,
		case a.to_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else 'On Hold'
		end as ToStatus,
		a.user_Defined_status as UserDefinedStatus,
		coalesce(a.notes, '') as Note,
		(a.std_quantity) as Quantity,
		a.shipper as VendorShipper
	into
		#ReceiptTransactionsRemainingOnHold	
	from
		dbo.audit_trail a
	left join
		dbo.employee e on e.operator_code = a.operator
	join part p on p.part = a.part
	cross apply ( select top 1 * from audit_trail a2 where a2.serial = a.serial order by date_stamp desc )  LastReceiptCheck
	cross apply ( Select top 1 * from object o2 where o2.serial =  a.serial )  CurrentObject
	where
		a.date_stamp <= @DayTimePrior and
		a.type = 'R' and
		a.status = 'H'
	and exists ( Select 1 from object o where o.serial = a.serial and o.status != 'A' )
	and LastReceiptCheck.type = 'R'
	order by 2 desc
		
		-- Create HTML and E-Mail
If exists ( Select 1 from #ReceiptTransactionsRemainingOnHold )	

Begin
		
		declare
			@html nvarchar(max)
		
		exec [FT].[usp_TableToHTML]
			@tableName = @tablename
		,	@html = @html out
		
		declare
			@EmailBody nvarchar(max)
		,	@EmailHeader nvarchar(max) = 'Receipt Inventory Remaining On Hold for Receipts Received Prior to ' + convert(varchar(25), @DayTimePrior, 113 )

		select
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'Fxalerts'
	,  	@recipients = 'qchold@aztecmfgcorp.com;aboulanger@fore-thought.com'
	--,  	@recipients = 'aboulanger@fore-thought.com'
	, 	@subject = @EmailHeader
	,  	@body = @EmailBody
	,  	@body_format = 'HTML'
					
END
--- </Body>

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


begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_EMailReceiptOnHoldTransactionSummary
	--@Param1 = @Param1
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	commit
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
