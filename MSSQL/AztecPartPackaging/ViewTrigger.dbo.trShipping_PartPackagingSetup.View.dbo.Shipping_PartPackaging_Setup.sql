create trigger dbo.trShipping_PartPackaging_Setup on dbo.Shipping_PartPackaging_Setup instead of insert, update, delete
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
	sd.shipper
,	sd.part
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
