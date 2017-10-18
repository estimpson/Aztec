SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create procedure [FT].[ftsp_NewReleasePlanSummary]
as
declare	@ShipTos table
(	ShipToID varchar(20) primary key)

insert	@ShipTos
select
	shipto_id
from
	dbo.m_in_release_plan mirp
group by
	shipto_id

declare @ShipToData table
(	ShipToID varchar(20)
,	CustomerPart varchar(35)
,	ModelYear varchar(10)
,	CustomerPO varchar(30)
,	NewCustomerPart varchar(35)
,	ActiveOrderNo int
,	MultipleActiveException bit
,	BlanketPart varchar(25)
,	EDIQuantity numeric (20,6)
,	TotalSalesQty numeric (20,6)
,	TotalQuantity numeric (20,6)
,	TotalInventoryQty numeric (20,6))

insert
	@ShipToData
select
	ShipToID
,	CustomerPart
,	ModelYear
,	CustomerPO
,	NewCustomerPart
,	ActiveSalesOrder
,	MultipleActiveException
,	BlanketPart
,	EDIQuantity
,	TotalSalesQty =
	(	select
			sum(order_detail.std_qty)
		from
			dbo.order_detail
			join dbo.edi_setups on
				EDIData.ShipToID = edi_setups.destination
			join dbo.order_header on
				order_detail.order_no = order_header.order_no
			and
				order_header.customer_part = EDIData.CustomerPart
			and
				order_header.destination = EDIData.ShipToID
			and
				coalesce (case when coalesce(edi_setups.check_model_year, 'N') = 'Y' then EDIData.ModelYear end, order_header.model_year, '') = coalesce (order_header.model_year, '')
			and
				coalesce (case when coalesce(edi_setups.check_po, 'N') = 'Y' then EDIData.CustomerPO end, order_header.customer_po, '') = coalesce (order_header.customer_po, '')
		where
			order_detail.part_number not like '%-PT%')
,	TotalQuantity =
	(	select
			sum(order_detail.Quantity)
		from
			dbo.order_detail
			join dbo.edi_setups on
				EDIData.ShipToID = edi_setups.destination
			join dbo.order_header on
				order_detail.order_no = order_header.order_no
			and
				order_header.customer_part = EDIData.CustomerPart
			and
				order_header.destination = EDIData.ShipToID
			and
				coalesce (case when coalesce(edi_setups.check_model_year, 'N') = 'Y' then EDIData.ModelYear end, order_header.model_year, '') = coalesce (order_header.model_year, '')
			and
				coalesce (case when coalesce(edi_setups.check_po, 'N') = 'Y' then EDIData.CustomerPO end, order_header.customer_po, '') = coalesce (order_header.customer_po, '')
		where
			order_detail.part_number not like '%-PT%')
,	TotalInventoryQty =
	(	select
			sum(object.std_quantity)
		from
			dbo.object
			join dbo.edi_setups on
				EDIData.ShipToID = edi_setups.destination
			join dbo.order_header on
				part = order_header.blanket_part
			and
				order_header.customer_part = EDIData.CustomerPart
			and
				order_header.destination = EDIData.ShipToID
			and
				coalesce (case when coalesce(edi_setups.check_model_year, 'N') = 'Y' then EDIData.ModelYear end, order_header.model_year, '') = coalesce (order_header.model_year, '')
			and
				coalesce (case when coalesce(edi_setups.check_po, 'N') = 'Y' then EDIData.CustomerPO end, order_header.customer_po, '') = coalesce (order_header.customer_po, '')
			left join location on
				object.location = location.code
		where
			coalesce (location.secured_location, 'N') != 'Y'
		and
			object.part not like '%-PT%')
from
	(	select
			ShipToID = mirp.shipto_id
		,	CustomerPart = mirp.customer_part
		,	ModelYear = case when coalesce(es.check_model_year, 'N') = 'Y' then mirp.model_year end
		,	CustomerPO = case when coalesce(es.check_po, 'N') = 'Y' then mirp.customer_po end
		,	NewCustomerPart = max(oh.customer_part)
		,	ActiveSalesOrder = max(oh.order_no)
		,	MultipleActiveException = coalesce (case when max(oh.order_no) != min(oh.order_no) then 1 end, 0)
		,	BlanketPart = max(oh.blanket_part)
		,	EDIQuantity = sum(convert(numeric(20,6), mirp.quantity))
		from
			m_in_release_plan mirp
			left join dbo.edi_setups es on
				mirp.shipto_id = es.destination
			left join dbo.order_header oh on
				coalesce(oh.status, 'O') != 'C'
			and
				mirp.shipto_id = oh.destination
			and
				mirp.customer_part = coalesce (oh.customer_part, oh.customer_part)
			and
				(	coalesce (es.check_model_year, 'N') != 'Y' or
					mirp.model_year = oh.model_year) and
				(	coalesce (es.check_po, 'N') != 'Y' or
					mirp.customer_po = oh.customer_po)
		group by
			mirp.shipto_id
		,	mirp.customer_part
		,	case when coalesce(es.check_model_year, 'N') = 'Y' then mirp.model_year end
		,	case when coalesce(es.check_po, 'N') = 'Y' then mirp.customer_po end) EDIData

insert
	@ShipToData
select
	ShipToID
,	CustomerPart
,	ModelYear
,	CustomerPO
,	NewCustomerPart
,	ActiveSalesOrder
,	MultipleActiveException
,	BlanketPart
,	EDIQuantity
,	TotalSalesQty
,	TotalQuantity
,	TotalInventoryQty =
	(	select
			sum(object.std_quantity)
		from
			dbo.object
			join dbo.edi_setups on
				NoEDIData.ShipToID = edi_setups.destination
			join dbo.order_header on
				part = order_header.blanket_part
			and
				order_header.customer_part = NoEDIData.CustomerPart
			and
				order_header.destination = NoEDIData.ShipToID
			and
				coalesce (case when coalesce(edi_setups.check_model_year, 'N') = 'Y' then NoEDIData.ModelYear end, order_header.model_year, '') = coalesce (order_header.model_year, '')
			and
				coalesce (case when coalesce(edi_setups.check_po, 'N') = 'Y' then NoEDIData.CustomerPO end, order_header.customer_po, '') = coalesce (order_header.customer_po, '')
			left join location on
				object.location = location.code
		where
			coalesce (location.secured_location, 'N') != 'Y'
		and
			object.part not like '%-PT%')
from
	(	select
			ShipToID = oh.destination
		,	CustomerPart = oh.customer_part
		,	ModelYear = case when coalesce(es.check_model_year, 'N') = 'Y' then oh.model_year end
		,	CustomerPO = case when coalesce(es.check_po, 'N') = 'Y' then oh.customer_po end
		,	NewCustomerPart = max(oh.customer_part)
		,	ActiveSalesOrder = max(case when oh.status = 'A' then oh.order_no end)
		,	MultipleActiveException = coalesce(case when max(case when oh.status = 'A' then oh.order_no end) != min(case when oh.status = 'A' then oh.order_no end) then 1 end, 0)
		,	BlanketPart = max (oh.blanket_part)
		,	EDIQuantity = 0
		,	TotalSalesQty = sum(od.std_qty)
		,	TotalQuantity = sum(od.Quantity)
		from
			dbo.order_header oh
			join dbo.edi_setups es on
				oh.destination = es.destination
			join dbo.order_detail od on
				oh.order_no = od.order_no and
				od.part_number not like '%-PT%'
		where
			oh.destination in
			(	select
	 				ShipToID
	 			from
	 				@ShipTos)
		and
			not exists
			(	select
					*
				from
					m_in_release_plan
				where
					shipto_id = oh.destination
				and
					customer_part = oh.customer_part
				and
					coalesce (case when coalesce(es.check_model_year, 'N') = 'Y' then oh.model_year end, model_year, '') = coalesce (model_year, '')
				and
					coalesce (case when coalesce(es.check_po, 'N') = 'Y' then oh.customer_po end, customer_po, '') = coalesce (customer_po, ''))
		group by
			oh.destination
		,	oh.customer_part
		,	case when coalesce(es.check_model_year, 'N') = 'Y' then oh.model_year end
		,	case when coalesce(es.check_po, 'N') = 'Y' then oh.customer_po end
		having
			sum(od.std_qty) > 0 or
			sum(od.Quantity) > 0) NoEDIData
			
--TRUNCATE TABLE dbo.m_in_release_plan

select
	*
from
	@ShipToData
GO
