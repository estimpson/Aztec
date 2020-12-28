use FxAztec
go
select
	es.destination
,	es.supplier_code
,	es.trading_partner_code
,	es.auto_create_asn
,	es.asn_overlay_group
,	es.material_issuer
,	es.IConnectID
from
	dbo.destination d
	join dbo.edi_setups es
		on es.destination = d.destination
where
	es.asn_overlay_group in ('TMC', 'TMS', 'TOY')

go

return

BEGIN TRANSACTION
update
	oh
set	oh.customer_part = replace(oh.customer_part, '-', '')
from
	dbo.order_header oh
where
	oh.destination in ('082AA','082AB')
go


select
	*
from
	dbo.order_header oh
where
	oh.destination in ('082AA','082AB')

return
commit

select
	*
from
	dbo.order_detail od
where
	od.order_no in
		(	select
				oh.order_no
			from
				dbo.order_header oh
			where
				oh.destination in ('082AA','082AB')
		)

select
	*
from
	EDIToyota.BlanketOrders bo
where
	bo.ShipToCode in ('082AA', '082AB')
go
return

update
	es
set	es.supplier_code = es.destination
,	es.parent_destination = 'KY'
,	es.trading_partner_code = 'Toyota Mot.(Sales)'
,	es.auto_create_asn = 'N'
,	es.asn_overlay_group = 'TMS'
,	es.material_issuer = '009595505'
,	es.IConnectID = '2234'
from
	dbo.destination d
	join dbo.edi_setups es
		on es.destination = d.destination
where
	d.destination in ('082AA', '082AB')
