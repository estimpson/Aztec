SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [custom].[MagnaLabel]
as
select
	Serial = o.serial
,	Part = o.part
,	PartDescription = p.name
,	Quantity = convert (int, o.quantity)
,	CustomerPart = left(sd.customer_part, 5)
,	LineFeed = left(oh.line_feed_code, 4)
,	Lot = o.lot
,	DateMFG = replace(convert(char(8), o.last_date, 10), '-', '')
,	GrossWeight = convert(int, o.weight)
,	DestinationCode = d.destination
,	Destination = d.name
,	DestinationAdd1 = coalesce(d.address_1, '')
,	DestinationAdd2 = coalesce(d.address_2, '')
,	DestinationAdd3 = coalesce(d.address_3, '')
,	SupplierCode = es.supplier_code
,	Company = upper(parm.company_name)
,	CompanyAdd1 = upper(coalesce(dPlant.address_1, parm.address_1))
,	CompanyAdd2 = upper(coalesce(dPlant.address_2, parm.address_2))
,	CompanyAdd3 = upper(coalesce(dPlant.address_3, parm.address_3))
,	CustomerCode = d.customer
from
	dbo.object o
	join dbo.shipper s
		on s.id = o.shipper
	join dbo.shipper_detail sd
		on sd.shipper = o.shipper
		and sd.part_original = o.part
	join dbo.order_header oh
		left join dbo.destination dPlant
			on dPlant.plant = oh.plant
		on oh.order_no = sd.order_no
	join dbo.edi_setups es
		on es.destination = s.destination
	join dbo.destination d
		on d.destination = s.destination
	join dbo.part p
		on p.part = o.part
	cross join dbo.parameters parm
union
select
	Serial = o.serial
,	Part = o.part
,	PartDescription = p.name
,	Quantity = convert (int, o.quantity)
,	CustomerPart = left(sd.customer_part, 5)
,	LineFeed = left(oh.line_feed_code, 4)
,	Lot = o.lot
,	DateMFG = replace(convert(char(8), o.date_stamp, 10), '-', '')
,	GrossWeight = convert(int, o.weight)
,	DestinationCode = d.destination
,	Destination = d.name
,	DestinationAdd1 = coalesce(d.address_1, '')
,	DestinationAdd2 = coalesce(d.address_2, '')
,	DestinationAdd3 = coalesce(d.address_3, '')
,	SupplierCode = es.supplier_code
,	Company = upper(parm.company_name)
,	CompanyAdd1 = upper(coalesce(dPlant.address_1, parm.address_1))
,	CompanyAdd2 = upper(coalesce(dPlant.address_2, parm.address_2))
,	CompanyAdd3 = upper(coalesce(dPlant.address_3, parm.address_3))
,	CustomerCode = d.customer
from
	dbo.audit_trail o
	join dbo.shipper s
		on s.id = o.shipper
	join dbo.shipper_detail sd
		on sd.shipper = o.shipper
		and sd.part_original = o.part
	join dbo.order_header oh
		left join dbo.destination dPlant
			on dPlant.plant = oh.plant
		on oh.order_no = sd.order_no
	join dbo.edi_setups es
		on es.destination = s.destination
	join dbo.destination d
		on d.destination = s.destination
	join dbo.part p
		on p.part = o.part
	cross join dbo.parameters parm
where
	o.type = 'S'
GO
