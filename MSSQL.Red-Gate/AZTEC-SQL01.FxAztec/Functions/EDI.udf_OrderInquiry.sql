SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [EDI].[udf_OrderInquiry]
()
returns @OrderInquiry table
(
	ID int
,   OrderNo int
,   Destination varchar(20)
,   DestinationName varchar(50)
,   DueDT datetime
,   Part varchar(25)
,   CrossRef varchar(50)
,   QtyRequired numeric(20,6)
,   PreAccum numeric(20,6)
,   PostAccum numeric(20,6)
,   QtyOnHand numeric(20,6)
,   Packed bit)
as
begin
--- <Body>

	declare
		@Orders table
	(
		ID int
	,	OrderNo int
	,	Part varchar(25)
	,	DueDT datetime
	,	QtyRequired numeric(20,6)
	,	PreAccum numeric(20,6)
	,	primary key
		(
			OrderNo
		,	Part
		,	DueDT
		,	QtyRequired
		,	ID
		)
	,	unique (id)
	)

	insert
		@Orders
	select
		ID = od.id
	,	OrderNo = od.order_no
	,	Part = od.part_number
	,	DueDT = od.due_date
	,	QtyRequired = od.std_qty
	,	PreAccum = coalesce (sum (od2.std_qty), 0)
	from
		dbo.order_detail od
		left join dbo.order_detail od2 on
			od2.order_no = od.order_no
			and
				od2.part_number = od.part_number
			and
				od2.due_date < od.due_date
	where
		od.std_qty > 0
	group by
		od.order_no
	,	od.due_date
	,	od.part_number
	,	od.std_qty
	,	od.id
	order by
		od.id

	declare
		@Stock table
	(
		OrderNo int
	,	Part varchar(25)
	,	QtyOnHand numeric(20,6)
	,	primary key
		(
			OrderNo
		,	Part
		)
	)

	insert
		@Stock
	select
		OrderNo = sd.order_no
	,	Part = o.part
	,	QtyOnhand = sum(std_quantity)
	from
		dbo.object o
		join shipper_detail sd on
			 convert (varchar, sd.shipper) = o.origin
			 and
				sd.part_original = o.part
	where
		o.status = 'A'
	group by
		o.part
	,	sd.order_no

	insert
		@OrderInquiry
	select
		Orders.ID
	,	Orders.OrderNo
	,	Orders.Destination
	,	Orders.DestinationName
	,	Orders.DueDT
	,	Orders.Part
	,	Orders.CrossRef
	,	Orders.QtyRequired
	,	Orders.PreAccum
	,	PostAccum = Orders.PreAccum + Orders.QtyRequired
	,	Stock.QtyOnhand
	,	Packed = case when Stock.QtyOnhand >= Orders.PreAccum + Orders.QtyRequired then 1 else 0 end
	from
		(	
			select
				Orders.OrderNo
			,   Orders.DueDT
			,   Orders.Part
			,   Orders.QtyRequired
			,   Orders.PreAccum
			,   Orders.ID
			,	Destination = oh.destination
			,	DestinationName = d.name
			,	CrossRef = p.cross_ref
			from
				@Orders Orders
				join dbo.order_header oh on
					oh.order_no = Orders.OrderNo
				join dbo.customer c on
					c.customer = oh.customer
				join dbo.destination d on
					d.destination = oh.destination
				join dbo.part p on
					p.part = Orders.Part
		) Orders
		left outer join @Stock Stock on
			Orders.Part = Stock.Part
			and
				Orders.OrderNo = Stock.OrderNo

--- </Body>

---	<Return>
	return
end
GO
