SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [custom].[usp_report_OpenPOs]
as
Select
	poh.plant,
	pod.po_number,
	poh.type,
	poh.vendor_code,
	v.name,
	isNull(nullif(v.outside_processor,''),'N') as OutSideProcessor,
	pod.part_number,
	pod.date_due,
	pod.balance,
	pod.description,
	coalesce(piv.default_vendor, piv2.default_vendor) as DefaultVendor,
	coalesce(piv.default_po_number, piv2.default_po_number) as DefaultPONumber
From	
	po_detail pod
join
	po_header poh on poh.po_number = pod.po_number
join
	vendor v on poh.vendor_code = v.code
left join
	part_online piv on piv.part = blanket_part
left join
	part_online piv2 on piv2.part = part_number


GO
