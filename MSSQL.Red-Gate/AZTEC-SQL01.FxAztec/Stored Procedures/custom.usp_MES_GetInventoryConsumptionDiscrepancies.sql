SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [custom].[usp_MES_GetInventoryConsumptionDiscrepancies]
	@FromDT datetime = null
,	@ToDT datetime = null
,	@TranDT datetime = null out
,	@Result integer = null out
,	@DBMail tinyint = 1
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. custom.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran #ProcName
end
else begin
	save tran #ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
create table
	#produced
(	PartCode varchar(25) primary key
,	QtyProduced numeric(10,2)
,	Notes varchar(255)
)

insert
	#produced
select
	PartCode = at.part
,	QtyProducted = sum(at.std_quantity)
,	Notes = convert(varchar, convert(numeric(10,2), sum(at.std_quantity))) + ' of part ' + at.part + ' was reported as production.'
from
	dbo.audit_trail at
where
	at.type in ('J', 'R')
	and at.date_stamp between @FromDT and coalesce(@ToDT, @FromDT + 1)
	and exists
		(	select
				*
			from
				FT.BOM b
			where
				b.ParentPart = at.part
		)
group by
	at.part

create table
	#consumed
(	ParentPart varchar(25)
,	ChildPart varchar(25)
,	QtyConsumed numeric(10,2)
,	Notes varchar(255)
,	primary key
		(	ParentPart
		,	ChildPart
		)
)

insert
	#consumed
select
	b.ParentPart
,	b.ChildPart
,	QtyConsumed = sum(p.QtyProduced * b.StdQty * b.ScrapFactor)
,	Notes = convert(varchar, convert(numeric(10,2), sum(p.QtyProduced * b.StdQty * b.ScrapFactor))) + ' of part ' + b.ChildPart + ' was consumed to produce ' + convert(varchar, sum(p.QtyProduced)) + ' of part ' + b.ParentPart + '.'
from
	#produced p
	join FT.BOM b
		on b.ParentPart = p.PartCode
group by
	b.ParentPart
,	b.ChildPart

create table
	#issued
(	PartCode varchar(25) primary key
,	QtyIssued numeric(10,2)
)
insert
	#issued
select
	PartCode = at.part
,	QtyIssued = sum(at.std_quantity)
from
	dbo.audit_trail at
		join dbo.machine m
			on m.machine_no = at.to_loc
where
	at.type = 'M'
	and at.date_stamp between @FromDT and coalesce(@ToDT, @FromDT + 1)
group by
	at.part

create table
	#consumptionReconciliation
(	PartCode varchar(25) primary key
,	QtyUsed numeric(10,2)
,	QtyIssued numeric(20,2)
,	Notes varchar(255)
)

insert
	#consumptionReconciliation
select
	PartCode = coalesce(c.ChildPart, i.PartCode)
,	QtyUsed = coalesce(c.QtyConsumed, 0)
,	QtyIssued = coalesce(i.QtyIssued, 0)
,	Notes =
		case
			when c.ChildPart is null then convert(varchar, i.QtyIssued) + ' of part ' + i.PartCode + ' issued but nothing was produced that used that material.  Check bill of materials for discrepancies.'
			when i.PartCode is null then convert(varchar, c.QtyConsumed) + ' of part ' + c.ChildPart + ' consumed but nothing was issued.  Check inventory of part and verify bill of materials.'
			when i.QtyIssued < c.QtyConsumed then convert(varchar, c.QtyConsumed) + ' of part ' + c.ChildPart + ' consumed but only ' + convert(varchar, i.QtyIssued) + ' was issued.  Check inventory of part and verify bill of materials.'
			when i.QtyIssued > c.QtyConsumed then convert(varchar, c.QtyConsumed) + ' of part ' + c.ChildPart + ' consumed but ' + convert(varchar, i.QtyIssued) + ' was issued.  Check inventory of part and verify bill of materials.'
			else 'Consumption of part ' + c.ChildPart + ' matches the amount that was issued.'
		end
from

	(	select
			c.ChildPart
		,	QtyConsumed = sum(c.QtyConsumed)
		from
			#consumed c
		group by
			c.ChildPart
	) c
	full join #issued i
		on i.PartCode = c.ChildPart
order by
	c.ChildPart
if	@DBMail != 1 begin
	select
		*
	from
		#produced p

	select
		*
	from
		#consumed c

	select
		*
	from
		#consumptionReconciliation
end
else begin
	declare @htmlProduced nvarchar(max)

	--- <Call>	
	set	@CallProcName = 'FT.usp_TableToHTML'
	execute
		@ProcReturn = FT.usp_TableToHTML
			@tableName = '#produced'
		,	@html = @htmlProduced out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
	
	declare @htmlConsumed nvarchar(max)

	--- <Call>	
	set	@CallProcName = 'FT.usp_TableToHTML'
	execute
		@ProcReturn = FT.usp_TableToHTML
			@tableName = '#consumed'
		,	@html = @htmlConsumed out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>

	declare @htmlConsumptionReconciliation nvarchar(max)

	--- <Call>	
	set	@CallProcName = 'FT.usp_TableToHTML'
	execute
		@ProcReturn = FT.usp_TableToHTML
			@tableName = '#consumptionReconciliation'
		,	@html = @htmlConsumptionReconciliation out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>

	--- <Call>
	declare
		@mailItemID int
	,	@emailSubject nvarchar(255) = N'Material Consumption Variance'
	,	@emailBody nvarchar(max) = N'<H1>Material Consumption Variance - From ' + convert(varchar, @FromDT) + ' to ' + convert(varchar, coalesce(@ToDT, @FromDT + 1)) + '</H1><br><H2>Production</H2><br>' + @htmlProduced + '<br><H2>Consumed</H2><br>' + @htmlConsumed + '<br><H2>Reconciliation</H2><br>' + @htmlConsumptionReconciliation
	  
	set	@CallProcName = 'dbo.usp_Notification_SendEmail'
	execute
		@ProcReturn = msdb.dbo.sp_send_dbmail
			@recipients = 'Rick Johnson <rjohnson@aztecmfgcorp.com>'
		,	@copy_recipients = null
		,	@subject = @emailSubject
		,	@body = @emailBody
		,	@body_format = 'HTML'
		,	@mailitem_id = @mailItemID out
		,	@from_address = 'estimpson@fore-thought.com'
		,	@reply_to = 'estimpson@fore-thought.com'

	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>

	print @emailBody
end
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran #ProcName
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
	@FromDT datetime = FT.fn_TruncDate('week', getdate()) - 8
,	@ToDT datetime = FT.fn_TruncDate('week', getdate()) - 1
,	@DBMail tinyint = 1

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_MES_GetInventoryConsumptionDiscrepancies
	@FromDT = @FromDT
,	@ToDT = @ToDT
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

commit
--if	@@trancount > 0 begin
--	rollback
--end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
