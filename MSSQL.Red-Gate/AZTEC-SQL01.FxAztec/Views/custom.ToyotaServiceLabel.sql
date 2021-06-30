SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [custom].[ToyotaServiceLabel]
as
select
	Serial = o.serial
,	Part = o.part
,	PartDescription = p.name
,	Quantity = convert (int, o.quantity)
,	CustomerPart = sd.customer_part
,	DockCode = oh.dock_code
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
,	s2.CaseNumber
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
		and	es.asn_overlay_group = 'TMS'
	join dbo.destination d
		on d.destination = s.destination
	join dbo.part p
		on p.part = o.part
	cross join dbo.parameters parm
	cross apply
		(	select
		 		CaseNumber = '082' + right('00000' + convert(varchar(5), (right(datepart(year, max(s2.date_stamp)), 1) * 10000 + count(*) % 10000)), 5)
		 	from
		 		dbo.shipper s2
			where
				s2.destination = s.destination
				and datepart(year, s2.date_stamp) = datepart(year, s.date_stamp)
				and s2.id <= s.id
		) s2
union
select
	Serial = o.serial
,	Part = o.part
,	PartDescription = p.name
,	Quantity = convert (int, o.quantity)
,	CustomerPart = sd.customer_part
,	DockCode = oh.dock_code
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
,	s2.CaseNumber
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
		and	es.asn_overlay_group = 'TMS'
	join dbo.destination d
		on d.destination = s.destination
	join dbo.part p
		on p.part = o.part
	cross join dbo.parameters parm
	cross apply
		(	select
		 		CaseNumber = '082' + right('00000' + convert(varchar(5), (right(datepart(year, max(s2.date_stamp)), 1) * 10000 + count(*) % 10000)), 5)
		 	from
		 		dbo.shipper s2
			where
				s2.destination = s.destination
				and datepart(year, s2.date_stamp) = datepart(year, s.date_stamp)
				and s2.id <= s.id
		) s2
where
	o.type = 'S'
GO
