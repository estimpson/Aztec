SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwStockInquiryLocations]
as
select
	Stock.Part,
	Stock.Location,
	Stock.PackType,
	Stock.PackSize,
	Stock.Containers,
	Stock.HoldContainers,
	PreAlloc = coalesce(
	(	select
			count(1)
		from
			dbo.object obj2
		where
			obj2.status = 'A'
			and
				obj2.part = Stock.Part
			and
				obj2.location < Stock.Location
			and
				obj2.package_type = Stock.PackType
			and
				obj2.std_quantity = Stock.PackSize), 0),
	PostAlloc = coalesce(
	(	select
			count(1)
		from
			dbo.object obj2
		where
			obj2.status = 'A'
			and
				obj2.part = Stock.Part
			and
				obj2.location <= Stock.Location
			and
				obj2.package_type = Stock.PackType
			and
				obj2.std_quantity = Stock.PackSize), 0),
	Orders = coalesce(Orders.Containers, 0)
from
	(	select
			Part = object.part
		,	Location = object.location
		,	PackType = object.package_type
		,	PackSize = object.std_quantity
		,	Containers = Sum(case status when 'A' then 1 else 0 end)
		,	HoldContainers = Sum(case status when 'A' then 0 else 1 end)
		from
			dbo.object
		group by
			object.part
		,	object.location
		,	object.package_type
		,	object.std_quantity) as Stock
	left outer join
	(	select
			Part = order_detail.part_number
		,	PackType = order_detail.packaging_type
		,	PackSize = min(part_packaging.quantity)
		,	Containers = sum(convert(integer, order_detail.std_qty / part_packaging.quantity))
		from
			dbo.order_detail
			left outer join dbo.part_packaging on order_detail.part_number = part_packaging.part
			and
				order_detail.packaging_type = part_packaging.code
		where
			convert(integer, order_detail.std_qty / part_packaging.quantity)> 0
		group by
			order_detail.part_number
		,	order_detail.packaging_type
	) as Orders on
		Orders.Part = Stock.Part
		and
			Orders.PackType = Stock.PackType
		and
			Orders.PackSize = Stock.PackSize
GO
