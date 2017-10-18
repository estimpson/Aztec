
/*
Create Procedure.Fx.custom.usp_MES_GetInventoryConsumptionDiscrepancies.sql
*/

--use Fx
--go

if	objectproperty(object_id('custom.usp_MES_GetInventoryConsumptionDiscrepancies'), 'IsProcedure') = 1 begin
	drop procedure custom.usp_MES_GetInventoryConsumptionDiscrepancies
end
go

create procedure custom.usp_MES_GetInventoryConsumptionDiscrepancies
	@TranDT datetime = null out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. custom.usp_Test
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
declare
	@produced table
(	PartCode varchar(25) primary key
,	QtyProduced numeric(10,2)
)

insert
	@produced
select
	PartCode = at.part
,	QtyProducted = sum(at.std_quantity)
from
	dbo.audit_trail at
where
	at.type = 'J'
	and datediff(day, at.date_stamp, @tranDT) = 0
group by
	at.part

declare
	@consumed table
(	ParentPart varchar(25)
,	ChildPart varchar(25)
,	QtyConsumed numeric(10,2)
,	primary key
		(	ParentPart
		,	ChildPart
		)
)

insert
	@consumed
select
	b.ParentPart
,	b.ChildPart
,	QtyConsumed = sum(p.QtyProduced * b.StdQty * b.ScrapFactor)
from
	@produced p
	join FT.BOM b
		on b.ParentPart = p.PartCode
group by
	b.ParentPart
,	b.ChildPart

declare
	@issued table
(	PartCode varchar(25) primary key
,	QtyIssued numeric(10,2)
)
insert
	@issued
select
	PartCode = at.part
,	QtyIssued = sum(at.std_quantity)
from
	dbo.audit_trail at
		join dbo.machine m
			on m.machine_no = at.to_loc
where
	at.type = 'M'
	and datediff(day, at.date_stamp, @tranDT) = 0
group by
	at.part

select
	p.PartCode
,	p.QtyProduced
,	Notes = convert(varchar, p.QtyProduced) + ' of part ' + p.PartCode + ' was reported as production.'
from
	@produced p
order by
	p.PartCode

select
	c.ParentPart
,	c.ChildPart
,	c.QtyConsumed
,	Notes = convert(varchar, c.QtyConsumed) + ' of part ' + c.ChildPart + ' was consumed to produce ' + convert(varchar, p.QtyProduced) + ' of part ' + c.ParentPart + '.'
from
	@consumed c
	join @produced p
		on p.PartCode = c.ParentPart
order by
	c.ChildPart
,	c.ParentPart

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
			@consumed c
		group by
			c.ChildPart
	) c
	full join @issued i
		on i.PartCode = c.ChildPart
order by
	c.ChildPart
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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime = getdate() - 1
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_MES_GetInventoryConsumptionDiscrepancies
	@TranDT = @TranDT out
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
go

