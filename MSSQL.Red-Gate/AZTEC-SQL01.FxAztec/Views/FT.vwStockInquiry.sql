SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwStockInquiry]
as
select
	Part = part.part,
	PartName = part.name,
	GroupTechnology = part.group_technology,
	CrossRef = part.cross_ref,
	PartClass = part.class,
	PartType = part.type,
	PackageType = coalesce(Stock.PackType, Orders.PackType, 'N/A'),
	PackSize = coalesce(Stock.PackSize, Orders.PackSize),
	Stock = coalesce(Stock.Containers, 0),
	HoldStock = coalesce(Stock.HoldContainers, 0),
	Orders = coalesce(Orders.Containers, 0)
from
	dbo.part_class_type_cross_ref
	join dbo.part on
		part_class_type_cross_ref.class = part.class and
		part_class_type_cross_ref.type = part.type
	join dbo.part_inventory on
		part.part = part_inventory.part
	join
	(	select
			Part = object.part
		,	PackType = object.package_type
		,	Packsize = object.std_quantity
		from
			dbo.object
		where
			package_type is not null
			or
				part in
				(	select
						part
					from
						dbo.part
					where
						type = 'R')
		group by
			object.part
		,	object.package_type
		,	object.std_quantity
		union
		select
			Part = order_detail.part_number
		,	PackType = order_detail.packaging_type
		,	PackSize = min(part_packaging.quantity)
		from
			dbo.order_detail
			left outer join dbo.part_packaging on
				order_detail.part_number = part_packaging.part
				and
					order_detail.packaging_type = part_packaging.code
		where
			convert(int, order_detail.std_qty / part_packaging.quantity) > 0
		group by
			order_detail.part_number
		,	order_detail.packaging_type
	) StockInquiry on part.part = StockInquiry.Part
	left outer join
	(	select
			Part = object.part
		,	PackType = object.package_type
		,	Packsize = object.std_quantity
		,	Containers = Sum(case status when 'A' then 1 else 0 end)
		,	HoldContainers = Sum(case status when 'A' then 0 else 1 end)
		from
			dbo.object
		where
			package_type is not null or
			part in
			(	select
					part
				from
					dbo.part
				where
					type = 'R')
		group by
			object.part
		,	object.package_type
		,	object.std_quantity
	) as Stock on
		StockInquiry.Part = Stock.Part
		and
			coalesce(StockInquiry.PackType, 'N/A') = coalesce(Stock.PackType, 'N/A')
		and
			StockInquiry.PackSize = coalesce(Stock.PackSize, StockInquiry.PackSize)
	left outer join
	(	select
			Part = order_detail.part_number
		,	PackType = order_detail.packaging_type
		,	PackSize = min(part_packaging.quantity)
		,	Containers = sum(convert(int, order_detail.std_qty / part_packaging.quantity))
		from
			dbo.order_detail
			left outer join dbo.part_packaging on
				order_detail.part_number = part_packaging.part
				and
					order_detail.packaging_type = part_packaging.code
		where
			convert(int, order_detail.std_qty / part_packaging.quantity) > 0
		group by
			order_detail.part_number
		,	order_detail.packaging_type
	) as Orders on
		StockInquiry.Part = Orders.Part
		and
			coalesce(StockInquiry.PackType, 'N/A') = coalesce(Orders.PackType, 'N/A')
		and
			StockInquiry.PackSize = coalesce(Orders.PackSize, StockInquiry.PackSize)
GO
