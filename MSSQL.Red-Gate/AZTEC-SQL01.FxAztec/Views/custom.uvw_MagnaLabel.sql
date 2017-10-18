SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [custom].[uvw_MagnaLabel]
as

Select
	serial,
	Quantity,
	coalesce(oh2.customer_part, oh1.customer_part, 'No Customer Part Defined') as CustomerPart,
	coalesce(oh2.customer_po, oh1.customer_po, 'No PO Defined') as CustomerPO,
	part.name name,
	coalesce(es2.supplier_code, es1.supplier_code, 'No PO Defined') as SupplierCode
From
	object
left join
	order_header oh1 on object.part = oh1.blanket_part and oh1.status = 'A'
left join
	shipper_detail sd on object.shipper = sd.shipper and object.part =sd.part_original
left join
	order_header oh2 on sd.order_no = oh2.order_no
left join 
	edi_setups es1 on oh1.destination = es1.destination
left join
	edi_setups es2 on oh2.destination = es2.destination
join
	part on object.part = part.part


GO
