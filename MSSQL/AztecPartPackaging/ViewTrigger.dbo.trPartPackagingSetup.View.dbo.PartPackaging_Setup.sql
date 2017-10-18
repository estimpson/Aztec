create trigger dbo.trPartPackaging_Setup on dbo.PartPackaging_Setup instead of insert, update, delete
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
set	@TableName = 'dbo.PartPackaging_BillTo'

delete
	ppbt
from
	dbo.PartPackaging_BillTo ppbt
	join deleted d
		on d.ID = ppbt.BillToCode
		and d.PartCode = ppbt.PartCode
		and d.PackagingCode = ppbt.PackagingCode
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
set	@TableName = 'dbo.PartPackaging_BillTo'

insert
	dbo.PartPackaging_BillTo
(	BillToCode
,	PartCode
,	PackagingCode
,	PackDisabled
,	PackEnabled
,	PackDefault
,	PackWarn
)
select
	i.ID
,	i.PartCode
,	i.PackagingCode
,	i.PackDisabled
,	i.PackEnabled
,	i.PackDefault
,	i.PackWarn
from
	inserted i
where
	(	i.PackDisabled is not null
		or i.PackEnabled is not null
		or i.PackDefault is not null
		or i.PackWarn is not null
	)
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
set	@TableName = 'dbo.PartPackaging_ShipTo'

delete
	ppst
from
	dbo.PartPackaging_ShipTo ppst
	join deleted d
		on d.ID = ppst.ShipToCode
		and d.PartCode = ppst.PartCode
		and d.PackagingCode = ppst.PackagingCode
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
set	@TableName = 'dbo.PartPackaging_ShipTo'

insert
	dbo.PartPackaging_ShipTo
(	ShipToCode
,	PartCode
,	PackagingCode
,	PackDisabled
,	PackEnabled
,	PackDefault
,	PackWarn
)
select
	i.ID
,	i.PartCode
,	i.PackagingCode
,	i.PackDisabled
,	i.PackEnabled
,	i.PackDefault
,	i.PackWarn
from
	inserted i
where
	(	i.PackDisabled is not null
		or i.PackEnabled is not null
		or i.PackDefault is not null
		or i.PackWarn is not null
	)
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
set	@TableName = 'dbo.PartPackaging_OrderHeader'

delete
	ppoh
from
	dbo.PartPackaging_OrderHeader ppoh
	join deleted d
		on d.ID = convert(varchar, ppoh.OrderNo)
		and d.PartCode = ppoh.PartCode
		and d.PackagingCode = ppoh.PackagingCode
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
set	@TableName = 'dbo.PartPackaging_OrderHeader'

insert
	dbo.PartPackaging_OrderHeader
(	OrderNo
,	PartCode
,	PackagingCode
,	PackDisabled
,	PackEnabled
,	PackDefault
,	PackWarn
)
select
	convert(numeric(8,0), i.ID)
,	i.PartCode
,	i.PackagingCode
,	i.PackDisabled
,	i.PackEnabled
,	i.PackDefault
,	i.PackWarn
from
	inserted i
where
	(	i.PackDisabled is not null
		or i.PackEnabled is not null
		or i.PackDefault is not null
		or i.PackWarn is not null
	)
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

--- <Delete rows="*">
set	@TableName = 'dbo.PartPackaging_OrderDetail'

delete
	ppod
from
	dbo.PartPackaging_OrderDetail ppod
		join dbo.order_detail od
			on od.id = ppod.ReleaseID
	join deleted d
		on d.ID = convert(varchar, od.order_no) + ':' + convert(varchar, od.id)
		and d.PartCode = ppod.PartCode
		and d.PackagingCode = ppod.PackagingCode
		and d.Type = 4

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
set	@TableName = 'dbo.PartPackaging_OrderDetail'

insert
	dbo.PartPackaging_OrderDetail
(	ReleaseID
,	PartCode
,	PackagingCode
,	PackDisabled
,	PackEnabled
,	PackDefault
,	PackWarn
)
select
	od.id
,	i.PartCode
,	i.PackagingCode
,	i.PackDisabled
,	i.PackEnabled
,	i.PackDefault
,	i.PackWarn
from
	inserted i
	join dbo.order_detail od
		on convert(varchar, od.order_no) + ':' + convert(varchar, od.id) = i.ID
where
	(	i.PackDisabled is not null
		or i.PackEnabled is not null
		or i.PackDefault is not null
		or i.PackWarn is not null
	)
	and i.type = 4

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
set	@TableName = 'dbo.PartPackaging_ShipperDetail'

delete
	ppsd
from
	dbo.PartPackaging_ShipperDetail ppsd
		join dbo.shipper_detail sd
			on sd.shipper = ppsd.ShipperID
	join deleted d
		on d.ID = convert(varchar, sd.shipper) + ':' + convert(varchar, sd.part)
		and d.PartCode = ppsd.PartCode
		and d.PackagingCode = ppsd.PackagingCode
		and d.Type = 5

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
set	@TableName = 'dbo.PartPackaging_ShipperDetail'

insert
	dbo.PartPackaging_ShipperDetail
(	ShipperID
,	ShipperPart
,	PartCode
,	PackagingCode
,	PackDisabled
,	PackEnabled
,	PackDefault
,	PackWarn
)
select
	ShipperID = sd.shipper
,	ShipperPart = sd.part
,	i.PartCode
,	i.PackagingCode
,	i.PackDisabled
,	i.PackEnabled
,	i.PackDefault
,	i.PackWarn
from
	inserted i
	join dbo.shipper_detail sd
		on convert(varchar, sd.shipper) + ':' + convert(varchar, sd.part) = i.ID
where
	(	i.PackDisabled is not null
		or i.PackEnabled is not null
		or i.PackDefault is not null
		or i.PackWarn is not null
	)
	and i.type = 5

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
GO

