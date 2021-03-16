SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [custom].[usp_AccumRollback]
as
select
	LastShipper = max(sd.shipper)
,	sd.order_no
,	DateTimeDT = getdate()
,	Accum = 0
,	Accumpart = 'ROLLBK ' + convert(varchar(25), sd.order_no) + '-' + convert(varchar(25), getdate(), 104)
,	Notes = ' AccumRollback  Jan 1, ' + convert(char(4), year(getdate())) + ' - Performed by SQL job'
into
	#ShipperAccums
from
	dbo.shipper s
	join dbo.shipper_detail sd
		on sd.shipper = s.id
where
	sd.part not like '%CUM%'
	-- All customers per Rob
	--and destination in
	--	(
	--		select destination from		dbo.edi_setups where asn_overlay_group like 'FD%'
	--	)
	and s.date_shipped >= dateadd(year, -1, getdate())
group by
	sd.order_no

insert
	dbo.shipper_detail
(	shipper
,	order_no
,	date_shipped
,	accum_shipped
,	part
,	note
)
select
	*
from
	#ShipperAccums

update
	oh
set
	oh.our_cum = 0
from
	dbo.order_header oh
where
	oh.order_no in
	(	select
			sa.order_no
		from
			#ShipperAccums sa
	)

update
	od
set
	od.our_cum = coalesce(
		(	select
				sum(od2.quantity)
			from
				dbo.order_detail od2
			where
				od2.order_no = od.order_no
				and od2.sequence < od.sequence
		)
	,	0
	)
,	the_cum = coalesce(
	(	select
			sum(od2.quantity)
		from
			dbo.order_detail od2
		where
			od2.order_no = od.order_no
			and od2.sequence <= od.sequence
		)
	,	0
	)
from
	dbo.order_detail od
where
	od.order_no in
	(
		select
			sa.order_no
		from
			#ShipperAccums sa
	)
GO
