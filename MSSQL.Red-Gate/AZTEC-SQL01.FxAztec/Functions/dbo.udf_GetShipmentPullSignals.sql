SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[udf_GetShipmentPullSignals]
(	@ShipTo varchar(10),
	@ShipFrom varchar(10),
	@ShipmentType char(1))
returns @OrderQuantities table
(	OrderNo numeric(8,0),
	PartNumber varchar(25),
	CustomerPart varchar(30),
	Suffix integer,
	DueDT datetime,
	HorizonType integer,
	Sequence integer,
	OrderQty numeric(20,6),
	ScheduledQty numeric(20,6),
	TransitInvQty numeric(20,6))
as
begin
	if	@ShipmentType = 'N' begin

		insert	@OrderQuantities
		select	od.order_no,
			od.part_number,
			od.customer_part,
			od.suffix,
			od.due_date,
			type =(case od.type when 'F' then 0 when 'P' then 1 when 'O' then 2 end),
			od.sequence,
			od.quantity,
			CommittedQty =
			(	case	when Coalesce(Previous.Accum, 0) + Coalesce(quantity, 0) < Coalesce(Scheduled.Qty, 0)
						then Coalesce(quantity, 0)
					when Coalesce(Previous.Accum, 0) < Coalesce(Scheduled.Qty, 0)
						then Coalesce(Scheduled.Qty, 0) - Coalesce(Previous.Accum, 0)
					else 0
					end),
			0
		from
			dbo.order_detail od
			join dbo.order_header oh on oh.order_no = od.order_no
			join
			(	select	od.id, Accum = Coalesce(sum(od2.quantity), 0)
				from	order_detail od
					left outer join order_detail od2 on od.order_no = od2.order_no and
						od.part_number = od2.part_number and
						coalesce(od.suffix, od2.suffix, -1) = Coalesce(od2.suffix, -1) and
						(	od.due_date > od2.due_date or
							od.due_date = od2.due_date and
							od.id < od2.id)
				group by od.id) as Previous on od.id = Previous.id
			left outer join
			(	select		type = Coalesce('N', shipper.type),
						order_no, 
						part_original, 
						suffix, 
						Qty = sum(qty_required)
				from	shipper_detail
					join shipper on shipper_detail.shipper = shipper.id
				where	shipper.status in('O', 'S') 
				group by shipper.type, order_no, part_original, suffix) as Scheduled 
					on od.order_no = Scheduled.order_no and
					part_number = Scheduled.part_original and
					Coalesce(od.suffix, -1) = Coalesce(Scheduled.suffix, -1) and
					Scheduled.type = @ShipmentType
		where	Coalesce(oh.plant, '') = Coalesce(NullIf(@ShipFrom, ''), Coalesce(oh.plant, '')) and
			od.destination = Coalesce(@ShipTo,od.destination)
	end
	else if
		@ShipmentType = 'T' begin

		insert
			@OrderQuantities
		select
			od.order_no
		,   od.part_number
		,   od.customer_part
		,   od.suffix
		,   od.due_date
		,   type = (case od.type
					  when 'F' then 0
					  when 'P' then 1
					  when 'O' then 2
					end)
		,   od.sequence
		,   od.quantity
		,   CommittedQty = (case when coalesce(Previous.Accum, 0) + coalesce(quantity, 0) < coalesce(Scheduled.Qty, 0)
								 then coalesce(quantity, 0)
								 when coalesce(Previous.Accum, 0) < coalesce(Scheduled.Qty, 0)
								 then coalesce(Scheduled.Qty, 0) - coalesce(Previous.Accum, 0)
								 else 0
							end)
		,   0
		from
			dbo.order_detail od
			join dbo.order_header oh
				on oh.order_no = od.order_no
			join (
				  select
					od.id
				  , Accum = coalesce(sum(od2.quantity), 0)
				  from
					order_detail od
					left outer join order_detail od2
						on od.order_no = od2.order_no
						   and od.part_number = od2.part_number
						   and coalesce(od.suffix, od2.suffix, -1) = coalesce(od2.suffix, -1)
						   and (
								od.due_date > od2.due_date
								or od.due_date = od2.due_date
								and od.id < od2.id
							   )
				  group by
					od.id
				 ) as Previous
				on od.id = Previous.id
			left outer join (
							 select
								type = coalesce('N', shipper.type)
							 ,  order_no
							 ,  part_original
							 ,  suffix
							 ,  Qty = sum(qty_required)
							 from
								shipper_detail
								join shipper
									on shipper_detail.shipper = shipper.id
							 where
								shipper.status in ('O', 'S')
							 group by
								shipper.type
							 ,  order_no
							 ,  part_original
							 ,  suffix
							) as Scheduled
				on od.order_no = Scheduled.order_no
				   and part_number = Scheduled.part_original
				   and coalesce(od.suffix, -1) = coalesce(Scheduled.suffix, -1)
				   and Scheduled.type = 'T'
		where
			coalesce(oh.plant, '') = coalesce(nullif(@ShipFrom, ''), coalesce(oh.plant, ''))
			and od.destination = coalesce(@ShipTo, od.destination)
			and exists
				(	select
						*
					from
						dbo.order_header oh2
					where
						oh2.plant = oh2.destination
				)

	end
	return
end

GO
