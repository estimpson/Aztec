SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [custom].[usp_report_emailOPHistory] 


--	@Param1 [scalar_data_type] ( = [default_value] ) ...
	@TranDT DATETIME OUT
,	@Result INTEGER OUT
AS
BEGIN
set nocount on
set ansi_warnings off
set	@Result = 999999
set	ansi_warnings ON

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname  = N'#Transactions',
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

--custom.usp_report_emailOPHistory

--Get Outside Processor List

Declare @OutsideProcessors table (

OutsideProcessor varchar(15) Primary Key

)

Insert @OutsideProcessors

Select 
	code
From
	vendor
Where
	coalesce(outside_processor, 'N') = 'Y'


-- Get History of Transactions for Outside Processors

Declare @Transactions table 
(
Part varchar(25),
DayOfTransaction datetime,
TransactionType varchar(25),
Quantity numeric(20,6),
FromLocation varchar(15),
ToLocation varchar(15),
Employee varchar(35)

)

Insert @Transactions 

Select 
	part,
	ft.fn_truncDaTe('dd',date_stamp),		
	case type when 'M' Then 'Material Issue' when 'O' then 'Shipped' when 'R' then 'Received' else type end  ,
	sum(Quantity),
	From_loc FromLocation,
	case when to_loc is null and remarks = 'M' then 'OPMaterialIssue' else to_loc end ToLocation ,	
	e.name
From
	audit_trail at
left join
	employee e on e.operator_code = at.operator
Where
	date_stamp>= dateadd(mi,-1441, getdate()) and
	date_stamp< getdate() and
	
	(	from_loc in ( Select * From @OutsideProcessors) or
		to_loc in ( Select * from @OutsideProcessors )
	)
Group by
	type,
	From_loc,
	case when to_loc is null and remarks = 'M' then 'OPMaterialIssue' else to_loc end ,
	ft.fn_truncDaTe('dd',date_stamp),
	part,
	e.name
order by 1

Select *
Into #Transactions
	From
	@Transactions
	order by 1

If Exists (Select 1 From @Transactions)

Begin
		
		declare
			@html nvarchar(max)
		
		exec [FT].[usp_TableToHTML]
			@tableName = @tablename
		,	@html = @html out
		
		declare
			@EmailBody nvarchar(max)
		,	@EmailHeader nvarchar(max) = 'Outside Process Transactions' 

		select
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html


	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'FxAlerts'
	,  	@recipients = 'rvasquez@aztecmfgcorp.com; rjohnson@aztecmfgcorp.com;aboulanger@fore-thought.com'
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
	@ProcReturn = custom.usp_report_emailOPHistory
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




END




GO
