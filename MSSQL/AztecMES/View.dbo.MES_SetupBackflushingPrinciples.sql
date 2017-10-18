

/*
Create view fx21st.dbo.MES_SetupBackflushingPrinciples
*/

--use fx21st
--go

--drop table dbo.MES_SetupBackflushingPrinciples
if	objectproperty(object_id('dbo.MES_SetupBackflushingPrinciples'), 'IsView') = 1 begin
	drop view dbo.MES_SetupBackflushingPrinciples
end
go

create view dbo.MES_SetupBackflushingPrinciples
as
select
	Type = 0
,	ID = null
,	Code = 'Group Technologies'
,	Description = ''
,	BackflushingPrinciple = null
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
union all
select
	Type = 0
,	ID = gt.id
,	Code = 'Group Technology:  ' + gt.id
,	Description = gt.notes
,	mgtbp.BackflushingPrinciple
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
from
	dbo.group_technology gt
	left join dbo.MES_GroupTechnologyBackflushingPrinciples mgtbp
		on mgtbp.GroupTechnology = gt.id
union all
select
	Type = 1
,	ID = null
,	Code = 'Product Lines'
,	Description = ''
,	BackflushingPrinciple = null
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
union all
select
	Type = 1
,	ID = pl.id
,	'Product Line:  ' + pl.id
,	pl.notes
,	mplbp.BackflushingPrinciple
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
from
	dbo.product_line pl
	left join dbo.MES_ProductLineBackflushingPrinciples mplbp
		on mplbp.ProductLine = pl.id
union all
select
	Type = 2
,	ID = null
,	Code = 'Commodities'
,	Description = ''
,	BackflushingPrinciple = null
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
union all
select
	Type = 2
,	ID = c.id
,	'Commodity:  ' + c.id
,	c.notes
,	mcbp.BackflushingPrinciple
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
from
	dbo.commodity c
	left join dbo.MES_CommodityBackflushingPrinciples mcbp
		on mcbp.Commodity = c.id
union all
select
	Type = 3
,	ID = null
,	Code = 'Parts'
,	Description = ''
,	BackflushingPrinciple = null
,	DefaultType = null
,	DefaultBackflushingPrinciple = null
union all
select
	Type = 3
,	ID = p.part
,	'Part:  ' + p.part
,	p.name
,	BackflushingPrinciple = coalesce(mpbp.BackflushingPrinciple, mgtbp.BackflushingPrinciple, mplbp.BackflushingPrinciple, mcbp.BackflushingPrinciple)
,	DefaultType =
	case
		when mgtbp.BackflushingPrinciple > 0 then 0
		when mplbp.BackflushingPrinciple > 0 then 1
		when mcbp.BackflushingPrinciple > 0 then 2
		when mpbp.BackflushingPrinciple > 0 then 3
	end
,	DefaultBackflushingPrinciple = coalesce(mgtbp.BackflushingPrinciple, mplbp.BackflushingPrinciple, mcbp.BackflushingPrinciple)
from
	dbo.part p
	left join dbo.MES_PartBackflushingPrinciples mpbp
		on mpbp.Part = p.part
	left join dbo.MES_CommodityBackflushingPrinciples mcbp
		on mcbp.Commodity = p.commodity
	left join dbo.MES_ProductLineBackflushingPrinciples mplbp
		on mplbp.ProductLine = p.product_line
	left join dbo.MES_GroupTechnologyBackflushingPrinciples mgtbp
		on mgtbp.GroupTechnology = p.group_technology
go

create trigger trMES_SetupBackflushingPrinciples on dbo.MES_SetupBackflushingPrinciples instead of insert, update, delete
as
declare
	@Result int

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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. <schema_name, sysname, dbo>.usp_Test
--- </Error Handling>

--- <Delete rows="*">
set	@TableName = 'dbo.MES_GroupTechnologyBackflushingPrinciples'

delete
	mgtbp
from
	dbo.MES_GroupTechnologyBackflushingPrinciples mgtbp
	join deleted d
		on d.ID = mgtbp.GroupTechnology
		and d.Type = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

--- <Insert rows="*">
set	@TableName = 'dbo.MES_GroupTechnologyBackflushingPrinciples'

insert
	dbo.MES_GroupTechnologyBackflushingPrinciples
(	GroupTechnology
,	BackflushingPrinciple
)
select
	i.ID
,	i.BackflushingPrinciple
from
	inserted i
where
	i.BackflushingPrinciple is not null
	and i.type = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Delete rows="*">
set	@TableName = 'dbo.MES_ProductLineBackflushingPrinciples'

delete
	mplbp
from
	dbo.MES_ProductLineBackflushingPrinciples mplbp
	join deleted d
		on d.ID = mplbp.ProductLine
		and d.Type = 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

--- <Insert rows="*">
set	@TableName = 'dbo.MES_ProductLineBackflushingPrinciples'

insert
	dbo.MES_ProductLineBackflushingPrinciples
(	ProductLine
,	BackflushingPrinciple
)
select
	i.ID
,	i.BackflushingPrinciple
from
	inserted i
where
	i.BackflushingPrinciple is not null
	and i.type = 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Delete rows="*">
set	@TableName = 'dbo.MES_CommodityBackflushingPrinciples'

delete
	mcbp
from
	dbo.MES_CommodityBackflushingPrinciples mcbp
	join deleted d
		on d.ID = mcbp.Commodity
		and d.Type = 2

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

--- <Insert rows="*">
set	@TableName = 'dbo.MES_CommodityBackflushingPrinciples'

insert
	dbo.MES_CommodityBackflushingPrinciples
(	commodity
,	BackflushingPrinciple
)
select
	i.ID
,	i.BackflushingPrinciple
from
	inserted i
where
	i.BackflushingPrinciple is not null
	and i.type = 2

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Delete rows="*">
set	@TableName = 'dbo.MES_PartBackflushingPrinciples'

delete
	mpbp
from
	dbo.MES_PartBackflushingPrinciples mpbp
	join deleted d
		on d.ID = mpbp.Part
		and d.Type = 3

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

--- <Insert rows="*">
set	@TableName = 'dbo.MES_PartBackflushingPrinciples'

insert
	dbo.MES_PartBackflushingPrinciples
(	Part
,	BackflushingPrinciple
)
select
	i.ID
,	i.BackflushingPrinciple
from
	inserted i
where
	i.BackflushingPrinciple is not null
	and i.type = 3

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>
go

select
	*
from
	MES_SetupBackflushingPrinciples
order by
	Type
,	ID
