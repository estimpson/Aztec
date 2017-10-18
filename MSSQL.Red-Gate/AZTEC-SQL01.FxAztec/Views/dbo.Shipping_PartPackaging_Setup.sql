SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[Shipping_PartPackaging_Setup]
as
select
	pps.Type
,   pps.ID
,   ShipperID = sd.shipper
,	ShipperPart = sd.part
,	pps.PartCode
,	PartName = p.name
,   pps.PackagingCode
,	PackageName = pm.name
,   pps.Code
,   pps.Description
,	OrderNo = sd.order_no
,	ShipTo = s.destination
,	ShipToName = d.name
,	BillTo = s.customer
,	BillToName = c.name
,   pps.PackDisabled
,   pps.PackEnabled
,   pps.PackDefault
,   pps.PackWarn
,   pps.DefaultPackDisabled
,   pps.DefaultPackEnabled
,   pps.DefaultPackDefault
,   pps.DefaultPackWarn
from
	dbo.PartPackaging_Setup pps
	join dbo.shipper s
		join dbo.shipper_detail sd
			on sd.shipper = s.id
		on pps.id = convert(varchar, sd.shipper) + ':' + sd.part
		and s.status in ('O', 'S')
		and s.type is null
	join dbo.part p
		on p.part = pps.PartCode
	join dbo.package_materials pm
		on pm.code = pps.PackagingCode
	join dbo.destination d
		on d.destination = s.destination
	join dbo.customer c
		on c.customer = s.customer
where
	pps.Type = 5
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[trShipping_PartPackaging_Setup] on [dbo].[Shipping_PartPackaging_Setup] instead of insert, update, delete
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
