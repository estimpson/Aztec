SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_BOMDiscrepancies]
	@TranDT datetime = null out
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

execute
	dbo.usp_Scheduling_BuildXRt 

select
	Part = od.part_number
,	ShipTo = od.destination
,	PrimaryMachine = pm.machine
,	BOMCount = count(distinct xr.Sequence)
,	DueDT = min(od.due_date)
into ##Temp
from
	dbo.order_detail od
	left join dbo.part_machine pm
		on pm.part = od.part_number
		and pm.sequence = 1
	left join FT.XRt xr
		on xr.TopPart = od.part_number
		and xr.Sequence > 0
where
	od.due_date > getdate() - 7
group by
	od.part_number
,	pm.machine
,	od.destination
having
	pm.machine is null
	or count(distinct xr.Sequence) = 0

if	@Email = 1 begin
	declare
		@html nvarchar(max)

	if	not exists
	  	(	select
	  			*
	  		from
	  			##Temp
	  	) begin
		select
			@html = '<br/>No missing BOM''s.'
	end
	else begin
		select
			@tableName = N'##Temp'

		execute
			FT.usp_TableToHTML
			@tableName = @tableName
		,	@html = @html out
		,	@orderBy = 'Part'
	end
	
	declare
		@EmailBody nvarchar(max)
	,	@EmailHeader nvarchar(max)

	select
		@EmailHeader = 'Jobs with missing BOM''s'

	select
		@EmailBody =
			N'<H1>' + @EmailHeader + ' - ' + convert(varchar, getdate()) + N'</H1>' +
			@html

	exec msdb.dbo.sp_send_dbmail
		@profile_name = 'DBMail'
	,	@recipients = 'estimpson@fore-thought.com; aboulanger@fore-thought.com; jmclean@21stcpc.com; munderwood@21stcpc.com; tBursley@21stcpc.com; jhinkson@21stcpc.com; cwright@21stcpc.com'
	, 	@subject = @EmailHeader
	,	@body = @EmailBody
	,	@body_format = 'HTML'
end
else begin
	select
		*
	from
		##Temp t
	order by
		t.Part
end
--- </Body>

if	@TranCount = 0 begin
	commit tran @ProcName
end

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
	@ProcReturn = dbo.usp_MES_BOMDiscrepancies
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
