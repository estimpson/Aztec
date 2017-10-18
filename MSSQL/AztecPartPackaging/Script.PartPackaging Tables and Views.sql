
/*
Create table FxClientModel.dbo.PartPackaging_BillTo
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_BillTo
if	objectproperty(object_id('dbo.PartPackaging_BillTo'), 'IsTable') is null begin

	create table dbo.PartPackaging_BillTo
	(	BillToCode varchar(10) references dbo.customer (customer) on delete cascade on update cascade
	,	PartCode varchar(25) references dbo.part (part) on delete cascade on update cascade
	,	PackagingCode varchar(20) references dbo.package_materials (code) on delete cascade on update cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PackDisabled tinyint default(0)
	,	PackEnabled tinyint default(0)
	,	PackDefault tinyint default(0)
	,	PackWarn tinyint default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	BillToCode
		,	PartCode
		,	PackagingCode
		)
	)
end
go


/*
Create table FxClientModel.dbo.PartPackaging_ShipTo
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_ShipTo
if	objectproperty(object_id('dbo.PartPackaging_ShipTo'), 'IsTable') is null begin

	create table dbo.PartPackaging_ShipTo
	(	ShipToCode varchar(20) references dbo.destination (destination) on delete cascade on update cascade
	,	PartCode varchar(25) references dbo.part (part) on delete cascade on update cascade
	,	PackagingCode varchar(20) references dbo.package_materials (code) on delete cascade on update cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PackDisabled tinyint default(0)
	,	PackEnabled tinyint default(0)
	,	PackDefault tinyint default(0)
	,	PackWarn tinyint default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	ShipToCode
		,	PartCode
		,	PackagingCode
		)
	)
end
go


/*
Create table FxClientModel.dbo.PartPackaging_OrderHeader
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_OrderHeader
if	objectproperty(object_id('dbo.PartPackaging_OrderHeader'), 'IsTable') is null begin

	create table dbo.PartPackaging_OrderHeader
	(	OrderNo numeric(8,0) references dbo.order_header (order_no) on delete cascade on update cascade
	,	PartCode varchar(25) references dbo.part (part) on delete cascade on update cascade
	,	PackagingCode varchar(20) references dbo.package_materials (code) on delete cascade on update cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PackDisabled tinyint default(0)
	,	PackEnabled tinyint default(0)
	,	PackDefault tinyint default(0)
	,	PackWarn tinyint default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	OrderNo
		,	PartCode
		,	PackagingCode
		)
	)
end
go


/*
Create table FxClientModel.dbo.PartPackaging_OrderDetail
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_OrderDetail
if	objectproperty(object_id('dbo.PartPackaging_OrderDetail'), 'IsTable') is null begin

	create table dbo.PartPackaging_OrderDetail
	(	ReleaseID int references dbo.order_detail (id) on delete cascade on update cascade
	,	PartCode varchar(25) references dbo.part (part) on delete cascade on update cascade
	,	PackagingCode varchar(20) references dbo.package_materials (code) on delete cascade on update cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PackDisabled tinyint default(0)
	,	PackEnabled tinyint default(0)
	,	PackDefault tinyint default(0)
	,	PackWarn tinyint default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	ReleaseID
		,	PartCode
		,	PackagingCode
		)
	)
end
go


/*
Create table FxClientModel.dbo.PartPackaging_ShipperDetail
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_ShipperDetail
if	objectproperty(object_id('dbo.PartPackaging_ShipperDetail'), 'IsTable') is null begin

	create table dbo.PartPackaging_ShipperDetail
	(	ShipperID int
	,	ShipperPart varchar(35)
	,	PartCode varchar(25) references dbo.part (part) on delete cascade on update cascade
	,	PackagingCode varchar(20) references dbo.package_materials (code) on delete cascade on update cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PackDisabled tinyint default(0)
	,	PackEnabled tinyint default(0)
	,	PackDefault tinyint default(0)
	,	PackWarn tinyint default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	ShipperID
		,	PartCode
		,	PackagingCode
		)
	,	foreign key
		(	ShipperID
		,	ShipperPart
		) references dbo.shipper_detail
		(	shipper
		,	part
		) on delete cascade on update cascade
	)
end
go


/*
Create view FxClientModel.dbo.PartPackaging_Setup
*/

--use FxClientModel
--go

--drop table dbo.PartPackaging_Setup
if	objectproperty(object_id('dbo.PartPackaging_Setup'), 'IsView') = 1 begin
	drop view dbo.PartPackaging_Setup
end
go

create view dbo.PartPackaging_Setup
as
/*	Customer Part Packaging*/
select
	Type = 1
,	ID = null
,	PartCode = null
,	PackagingCode = null
,	Code = 'Customer Part Packaging'
,	Description = ''
,	PackDisabled = null
,	PackEnabled = null
,	PackDefault = null
,	PackWarn = null
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
union all
select
	Type = 1
,	ID = pc.customer
,	PartCode = pc.part
,	PackagingCode = pp.code
,	Code = 'Customer Part Packaging:  ' + pc.customer + '-' + pc.part + ',' + pp.code
,	Description = 'Customer Part Packaging:  ' + pc.customer + '-' + pc.part + ',' + pp.code
,	PackDisabled = coalesce(ppbt.PackDisabled, 0)
,	PackEnabled = coalesce(ppbt.PackEnabled, 0)
,	PackDefault = coalesce(ppbt.PackDefault, 0)
,	PackWarn = coalesce(ppbt.PackWarn, 0)
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
from
	dbo.part_packaging pp
	join dbo.part_customer pc
		on pc.part = pp.part
	left join dbo.PartPackaging_BillTo ppbt
		on ppbt.BillToCode = pc.customer
		and ppbt.PartCode = pc.part
		and ppbt.PackagingCode = pp.code

/*	Destination Part Packaging*/
union all
select
	Type = 2
,	ID = null
,	PartCode = null
,	PackagingCode = null
,	Code = 'Destination Part Packaging'
,	Description = ''
,	PackDisabled = null
,	PackEnabled = null
,	PackDefault = null
,	PackWarn = null
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
union all
select
	Type = 2
,	ID = d.destination
,	PartCode = pc.part
,	PackagingCode = pp.code
,	Code = 'Destination Part Packaging:  ' + pc.customer + ':' + d.destination + '-' + pc.part + ',' + pp.code
,	Description = 'Destination Part Packaging:  ' + pc.customer + ':' + d.destination + '-' + pc.part + ',' + pp.code
,	PackDisabled = coalesce(ppbt.PackDisabled, ppst.PackDisabled, 0)
,	PackEnabled = coalesce(ppbt.PackEnabled, ppst.PackEnabled, 0)
,	PackDefault = coalesce(ppbt.PackDefault, ppst.PackDefault, 0)
,	PackWarn = coalesce(ppbt.PackWarn, ppst.PackWarn, 0)
,	DefaultPackDisabled = ppbt.PackDisabled
,	DefaultPackEnabled = ppbt.PackEnabled
,	DefaultPackDefault = ppbt.PackDefault
,	DefaultPackWarn = ppbt.PackWarn
from
	dbo.part_packaging pp
	join dbo.part_customer pc
		on pc.part = pp.part
	join dbo.destination d
		on d.customer = pc.customer
	left join dbo.PartPackaging_BillTo ppbt
		on ppbt.BillToCode = pc.customer
		and ppbt.PartCode = pc.part
		and ppbt.PackagingCode = pp.code
	left join dbo.PartPackaging_ShipTo ppst
		on ppst.ShipToCode = d.destination
		and ppst.PartCode = pc.part
		and ppst.PackagingCode = pp.code

/*	Order Header Part Packaging*/
union all
select
	Type = 3
,	ID = null
,	PartCode = null
,	PackagingCode = null
,	Code = 'Order Header Part Packaging'
,	Description = ''
,	PackDisabled = null
,	PackEnabled = null
,	PackDefault = null
,	PackWarn = null
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
union all
select
	Type = 3
,	ID = convert(varchar, oh.order_no)
,	PartCode = pp.part
,	PackagingCode = pp.code
,	Code = 'Order Header Part Packaging:  ' + convert(varchar, oh.order_no) + '(' + oh.customer + ':' + oh.destination + ')-' + pp.part + ',' + pp.code
,	Description = 'Order Header Part Packaging:  ' + convert(varchar, oh.order_no) + '(' + oh.customer + ':' + oh.destination + ')-' + pp.part + ',' + pp.code
,	PackDisabled = coalesce(ppoh.PackDisabled, ppbt.PackDisabled, ppst.PackDisabled, 0)
,	PackEnabled = coalesce(ppoh.PackEnabled, ppbt.PackEnabled, ppst.PackEnabled, 0)
,	PackDefault = coalesce(ppoh.PackDefault, ppbt.PackDefault, ppst.PackDefault, 0)
,	PackWarn = coalesce(ppoh.PackWarn, ppbt.PackWarn, ppst.PackWarn, 0)
,	DefaultPackDisabled = coalesce(ppbt.PackDisabled, ppst.PackDisabled)
,	DefaultPackEnabled = coalesce(ppbt.PackEnabled, ppst.PackEnabled)
,	DefaultPackDefault = coalesce(ppbt.PackDefault, ppst.PackDefault)
,	DefaultPackWarn = coalesce(ppbt.PackWarn, ppst.PackWarn)
from
	dbo.part_packaging pp
	join dbo.order_header oh
		on oh.blanket_part = pp.part
	left join dbo.PartPackaging_BillTo ppbt
		on ppbt.BillToCode = oh.customer
		and ppbt.PartCode = oh.blanket_part
		and ppbt.PackagingCode = pp.code
	left join dbo.PartPackaging_ShipTo ppst
		on ppst.ShipToCode = oh.destination
		and ppst.PartCode = oh.blanket_part
		and ppst.PackagingCode = pp.code
	left join dbo.PartPackaging_OrderHeader ppoh
		on ppoh.OrderNo = oh.order_no
		and ppoh.PartCode = pp.part
		and ppoh.PackagingCode = pp.code

/*	Order Detail Part Packaging*/
union all
select
	Type = 4
,	ID = null
,	PartCode = null
,	PackagingCode = null
,	Code = 'Order Detail Part Packaging'
,	Description = ''
,	PackDisabled = null
,	PackEnabled = null
,	PackDefault = null
,	PackWarn = null
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
union all
select
	Type = 4
,	ID = convert(varchar, od.order_no) + ':' + convert(varchar, od.id)
,	PartCode = pp.part
,	PackagingCode = pp.code
,	Code = 'Order Detail Part Packaging:  ' + convert(varchar, od.id) + '(' + convert(varchar, oh.order_no) + ':' + oh.customer + ':' + oh.destination + ')-' + pp.part + ',' + pp.code
,	Description = 'Order Detail Part Packaging:  ' + convert(varchar, od.id) + '(' + convert(varchar, oh.order_no) + ':' + oh.customer + ':' + oh.destination + ')-' + pp.part + ',' + pp.code
,	PackDisabled = coalesce(ppod.PackDisabled, ppoh.PackDisabled, ppbt.PackDisabled, ppst.PackDisabled, 0)
,	PackEnabled = coalesce(ppod.PackEnabled, ppoh.PackEnabled, ppbt.PackEnabled, ppst.PackEnabled, 0)
,	PackDefault = coalesce(ppod.PackDefault, ppoh.PackDefault, ppbt.PackDefault, ppst.PackDefault, 0)
,	PackWarn = coalesce(ppod.PackWarn, ppoh.PackWarn, ppbt.PackWarn, ppst.PackWarn, 0)
,	DefaultPackDisabled = coalesce(ppoh.PackDisabled, ppbt.PackDisabled, ppst.PackDisabled)
,	DefaultPackEnabled = coalesce(ppoh.PackEnabled, ppbt.PackEnabled, ppst.PackEnabled)
,	DefaultPackDefault = coalesce(ppoh.PackDefault, ppbt.PackDefault, ppst.PackDefault)
,	DefaultPackWarn = coalesce(ppoh.PackWarn, ppbt.PackWarn, ppst.PackWarn)
from
	dbo.part_packaging pp
	join dbo.order_detail od
		join dbo.order_header oh
			on oh.order_no = od.order_no
		on od.part_number = pp.part
	left join dbo.PartPackaging_BillTo ppbt
		on ppbt.BillToCode = oh.customer
		and ppbt.PartCode = od.part_number
		and ppbt.PackagingCode = pp.code
	left join dbo.PartPackaging_ShipTo ppst
		on ppst.ShipToCode = oh.destination
		and ppst.PartCode = od.part_number
		and ppst.PackagingCode = pp.code
	left join dbo.PartPackaging_OrderHeader ppoh
		on ppoh.OrderNo = oh.order_no
		and ppoh.PartCode = oh.blanket_part
		and ppoh.PackagingCode = pp.code
	left join dbo.PartPackaging_OrderDetail ppod
		on ppod.ReleaseID = od.id
		and ppod.PartCode = pp.part
		and ppod.PackagingCode = pp.code

/*	Shipper Detail Part Packaging*/
union all
select
	Type = 5
,	ID = null
,	PartCode = null
,	PackagingCode = null
,	Code = 'Shipper Detail Part Packaging'
,	Description = ''
,	PackDisabled = null
,	PackEnabled = null
,	PackDefault = null
,	PackWarn = null
,	DefaultPackDisabled = null
,	DefaultPackEnabled = null
,	DefaultPackDefault = null
,	DefaultPackWarn = null
union all
select
	Type = 5
,	ID = convert(varchar, sd.shipper) + ':' + convert(varchar, sd.part)
,	PartCode = sd.part_original
,	PackagingCode = pp.code
,	Code = 'Shipper Detail Part Packaging{' + convert(varchar, sd.shipper) + ',' + sd.part + ',' + ',' + pp.part + ',' + pp.code + '}'
,	Description = 'Shipper Detail Part Packaging{ShipperID:' + convert(varchar, sd.shipper) + ', ShipperPart:' + sd.part + ', OrderNo:' + convert(varchar, sd.order_no) + ', BillTo:' + sOpen.customer + ', ShipTo:' + sOpen.destination + ', PartCode:' + pp.part + ', PackagingCode:' + pp.code + '}'
,	PackDisabled = coalesce(ppsd.PackDisabled, ppod.PackDisabled, ppoh.PackDisabled, ppbt.PackDisabled, ppst.PackDisabled, 0)
,	PackEnabled = coalesce(ppsd.PackEnabled, ppod.PackEnabled, ppoh.PackEnabled, case when coalesce(ohBlanket.package_type, oh.package_type) = pp.code then 1 end, ppbt.PackEnabled, ppst.PackEnabled, 0)
,	PackDefault = coalesce(ppsd.PackDefault, ppod.PackDefault, ppoh.PackDefault, case when coalesce(ohBlanket.package_type, oh.package_type) = pp.code then 1 end, ppbt.PackDefault, ppst.PackDefault, 0)
,	PackWarn = coalesce(ppsd.PackWarn, ppod.PackWarn, ppoh.PackWarn, ppbt.PackWarn, ppst.PackWarn, 0)
,	PackDisabled = coalesce(ppod.PackDisabled, ppoh.PackDisabled, ppbt.PackDisabled, ppst.PackDisabled)
,	PackEnabled = coalesce(ppod.PackEnabled, ppoh.PackEnabled, case when coalesce(ohBlanket.package_type, oh.package_type) = pp.code then 1 end, ppbt.PackEnabled, ppst.PackEnabled)
,	PackDefault = coalesce(ppod.PackDefault, ppoh.PackDefault, case when coalesce(ohBlanket.package_type, oh.package_type) = pp.code then 1 end, ppbt.PackDefault, ppst.PackDefault)
,	PackWarn = coalesce(ppod.PackWarn, ppoh.PackWarn, ppbt.PackWarn, ppst.PackWarn)
from
	--Shipper is anchor
	dbo.shipper_detail sd
		join dbo.shipper sOpen
			on sOpen.id = sd.shipper
			and sOpen.status in ('O', 'S')
	--Part packaging relationships for shipper's parts
	join dbo.part_packaging pp
		on pp.part = sd.part_original
	--Part customer relationships for shipper's parts
	left join dbo.part_customer pc
		on pc.part = sd.part_original
	--First release for each of shipper's lines
	left join dbo.order_detail od
		join dbo.order_header oh
			on oh.order_no = od.order_no
		on od.part_number = sd.part_original
		and oh.destination = sOpen.destination
		and od.id =
		(	select
				min(id)
			from
				dbo.order_detail
			where
				order_no = oh.order_no
		)
	--Blanket order for each of shipper's lines
	left join dbo.order_header ohBlanket
		on ohBlanket.blanket_part = sd.part_original
		and ohBlanket.destination = sOpen.destination
	--	Bill to part packaging.
	left join dbo.PartPackaging_BillTo ppbt
		on ppbt.BillToCode = sOPen.customer
		and ppbt.PartCode = sd.part_original
		and ppbt.PackagingCode = pp.code
	--	Ship to part packaging
	left join dbo.PartPackaging_ShipTo ppst
		on ppst.ShipToCode = sOpen.destination
		and ppst.PartCode = sd.part_original
		and ppst.PackagingCode = pp.code
	--	Order header part packaging
	left join dbo.PartPackaging_OrderHeader ppoh
		on ppoh.OrderNo = coalesce(ohBlanket.order_no, oh.order_no)
		and ppoh.PartCode = sd.part_original
		and ppoh.PackagingCode = pp.code
	--	Order detail part packaging
	left join dbo.PartPackaging_OrderDetail ppod
		on ppod.ReleaseID = od.id
		and ppod.PartCode = sd.part_original
		and ppod.PackagingCode = pp.code
	--	Shipper detail part packaging
	left join dbo.PartPackaging_ShipperDetail ppsd
		on ppsd.ShipperID = sd.shipper
		and ppsd.PartCode = pp.part
		and ppsd.PackagingCode = pp.code
go


/*
Create view FxClientDB.dbo.Shipping_PartPackaging_Setup
*/

--use FxClientDB
--go

--drop table dbo.Shipping_PartPackaging_Setup
if	objectproperty(object_id('dbo.Shipping_PartPackaging_Setup'), 'IsView') = 1 begin
	drop view dbo.Shipping_PartPackaging_Setup
end
go

create view dbo.Shipping_PartPackaging_Setup
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
go

select
	spps.Type
,   spps.ID
,   spps.ShipperID
,   spps.ShipperPart
,   spps.PartCode
,   spps.PartName
,   spps.PackagingCode
,   spps.PackageName
,   spps.Code
,   spps.Description
,   spps.OrderNo
,   spps.ShipTo
,   spps.ShipToName
,   spps.BillTo
,   spps.BillToName
,   spps.PackDisabled
,   spps.PackEnabled
,   spps.PackDefault
,   spps.PackWarn
,   spps.DefaultPackDisabled
,   spps.DefaultPackEnabled
,   spps.DefaultPackDefault
,   spps.DefaultPackWarn
from
	dbo.Shipping_PartPackaging_Setup spps
order by
	spps.Type
,	spps.ID
,	spps.PartCode
,	spps.PackagingCode

declare
	@ShipperID int; set @ShipperID = 66214

select
	pps.Type
,   pps.ID
,	ShipperID = sd.shipper
,	PartOriginal = sd.part_original
,   pps.PartCode
,   pps.PackagingCode
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
	join dbo.shipper_detail sd
		on pps.ID like convert(varchar, sd.shipper) + ':' + sd.part_original
where
	pps.Type = 5
	and sd.shipper = @ShipperID
order by
	pps.Type
,	pps.ID
,	pps.PartCode
,	pps.PackagingCode

select
	*
from
	dbo.PartPackaging_Setup pps
where
	pps.PartCode = '2191'

select
	pps.PartCode
,	count(*)
from
	dbo.PartPackaging_Setup pps
group by
	pps.PartCode
having
	max(pps.Type) = 5
	and min(PPS.Type) < 5
order by
	2 desc
