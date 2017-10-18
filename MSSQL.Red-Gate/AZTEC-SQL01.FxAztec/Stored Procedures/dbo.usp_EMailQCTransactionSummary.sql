SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[usp_EMailQCTransactionSummary]
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
	@TableName sysname  = N'#AuditTrailQualityTransactions',
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
	
	select @DayTimePrior = dateadd(MINUTE,-15, getdate())
	
	--Get Audit Trail for QC Tranactions
	
		
		select 
		a.part, 
		p.name,
		coalesce(e.name, a.operator) as Employee,
		case a.from_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else a.to_loc
		end as FromStatus,
		case a.to_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else a.to_loc
		end as ToStatus,
		a.user_Defined_status as UserDefinedStatus,
		coalesce(a.notes, '') as Note,
		coalesce(at2.shipper,'') as Vendorshipper,
		sum(a.std_quantity) as Quantity
	into
		#AuditTrailQualityTransactions	
	from
		dbo.audit_trail a
	left join
		dbo.audit_trail at2 on at2.serial = a.serial and at2.type = 'R' 
	left join
		dbo.employee e on e.operator_code = a.operator
	join part p on p.part = a.part
	where
		a.date_stamp > @DayTimePrior and
		a.type = 'Q'
	group by
		a.part, 
		p.name,
		coalesce(e.name, a.operator),
		case a.from_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else a.to_loc
		end,
		case a.to_loc 
		when 'A' then 'Approved'
		when 'H' then 'Hold'
		when 'S' then 'Scrapped'
		when 'O' then 'Obsolete'
		when 'R' then 'Rejected'
		else a.to_loc
		end ,
		a.user_Defined_status,
		coalesce(a.notes,''),
		coalesce(at2.shipper,'')

-- Create HTML and E-Mail
If exists ( Select 1 from #AuditTrailQualityTransactions )	

Begin	
		declare
			@html nvarchar(max)
		
		exec [FT].[usp_TableToHTML]
			@tableName = @tablename
		,	@html = @html out
		
		declare
			@EmailBody nvarchar(max)
		,	@EmailHeader nvarchar(max) = 'Quality Transactions'

		select
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'FxAlerts'
	,  	@recipients = 'qchold@aztecmfgcorp.com;aboulanger@fore-thought.com'
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
	@ProcReturn = dbo.usp_EMailQCTransactionSummary
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
