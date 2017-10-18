SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwStockInquiryOrders]
as
select
	*,
	PostAlloc = PreAlloc + Containers
from
	(	select
			Orders.OrderNo
		,	Orders.Destination
		,	Orders.DestinationName
		,	Orders.DueDT
		,	Orders.Part
		,	Orders.CrossRef
		,	PackageType = Orders.PackType
		,	Orders.PackSize
		,	Orders.Containers
		,	PreAlloc = coalesce (
			(	select
					sum (convert (integer, od2.std_qty / part_packaging.quantity))
				from
					dbo.order_detail od2
					left outer join dbo.part_packaging on
						od2.part_number = part_packaging.part
						and
							od2.packaging_type = part_packaging.code
				where
					(	od2.due_date < Orders.DueDT
						or
						(	od2.due_date = Orders.DueDT
							and
								od2.order_no < Orders.OrderNo
						)
					)
					and
						od2.part_number = Orders.Part
					and
						od2.packaging_type = Orders.PackType
					and
						part_packaging.quantity = Orders.PackSize
			), 0)
		,	Inventory = coalesce (Stock.Containers, 0)
		,	Orders.Row_id
		from
			(	select
					OrderNo = order_detail.order_no
					,	Destination = order_header.destination
					,	DestinationName = destination.name
					,	DueDT = order_detail.due_date
					,	Part = order_detail.part_number
					,	CrossRef = part.cross_ref
					,	PackType = order_detail.packaging_type
					,	PackSize = part_packaging.quantity
					,	Containers = convert (integer, order_detail.std_qty / part_packaging.quantity)
					,	Row_ID
				from
					dbo.order_detail
					join dbo.order_header on
						order_detail.order_no = order_header.order_no
					join dbo.customer on
						order_header.customer = customer.customer
					join dbo.destination on
						order_header.destination = destination.destination
					join dbo.part on
						order_detail.part_number = part.part
					left outer join dbo.part_packaging on
						order_detail.part_number = part_packaging.part
						and
							order_detail.packaging_type = part_packaging.code
				where
					convert (integer, order_detail.std_qty / part_packaging.quantity) > 0
			) as Orders
			left outer join
			(	select
					Part = object.part
				,	PackType = object.package_type
				,	PackSize = object.std_quantity
				,	Containers = count (1)
				from
					dbo.object
				where
					object.status = 'A'
				group by
					object.part
				,	object.package_type
				,	object.std_quantity
			) as Stock on
				Orders.Part = Stock.Part
				and
					Orders.PackType = Stock.PackType
				and
					Orders.PackSize = Stock.PackSize
	) StockInquiryOrders
GO
