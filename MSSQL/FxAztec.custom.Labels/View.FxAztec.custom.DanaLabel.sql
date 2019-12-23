
/*
Create View.FxAztec.custom.DanaLabel.sql
*/

use FxAztec
go

--drop table custom.DanaLabel
if	objectproperty(object_id('custom.DanaLabel'), 'IsView') = 1 begin
	drop view custom.DanaLabel
end
go

create view custom.DanaLabel
as
select
	Serial = o.serial
,	Part = o.part
,	PartDescription = p.name
,	Quantity = convert (int, o.quantity)
,	CustomerPart = sd.customer_part
,	Lot = o.lot
,	DateMFG = right(datepart(year, o.last_date), 1) + right('000' + datepart(dayofyear, o.last_date), 3)
,	DestinationCode = d.destination
,	CustomerCode = d.customer
,	CustomerPO = oh.customer_po
,	RevLevel = coalesce(nullif(rtrim(oh.engineering_level), ''), '--')
,	SupplierCode = es.supplier_code
,	Company = parm.company_name
,	CompanyAdd1 = parm.address_1
,	CompanyAdd2 = parm.address_2
,	CompanyAdd3 = parm.address_3
from
	dbo.object o
	join dbo.shipper s
		on s.id = o.shipper
	join dbo.shipper_detail sd
		on sd.shipper = o.shipper
		and sd.part_original = o.part
	join dbo.order_header oh
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
,	CustomerPart = sd.customer_part
,	Lot = o.lot
,	DateMFG = right(datepart(year, o.date_stamp), 1) + right('000' + datepart(dayofyear, o.date_stamp), 3)
,	DestinationCode = d.destination
,	CustomerCode = d.customer
,	CustomerPO = oh.customer_po
,	RevLevel = coalesce(nullif(rtrim(oh.engineering_level), ''), '--')
,	SupplierCode = es.supplier_code
,	Company = parm.company_name
,	CompanyAdd1 = parm.address_1
,	CompanyAdd2 = parm.address_2
,	CompanyAdd3 = parm.address_3
from
	dbo.audit_trail o
	join dbo.shipper s
		on s.id = o.shipper
	join dbo.shipper_detail sd
		on sd.shipper = o.shipper
		and sd.part_original = o.part
	join dbo.order_header oh
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
go

select top(100)
	dl.Serial
,	dl.Part
,	dl.PartDescription
,	dl.Quantity
,	dl.CustomerPart
,	dl.Lot
,	dl.DateMFG
,	dl.DestinationCode
,	dl.CustomerCode
,	dl.CustomerPO
,	dl.RevLevel
,	dl.SupplierCode
,	dl.Company
,	dl.CompanyAdd1
,	dl.CompanyAdd2
,	dl.CompanyAdd3
from
	custom.DanaLabel dl
where
	dl.CustomerCode like 'DANA%'
order by
	dl.Serial desc
