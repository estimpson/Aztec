
/*
Create View.Fx.EDIToyota.ShipTos.sql
*/

--use Fx
--go

--drop table EDIToyota.ShipTos
if	objectproperty(object_id('EDIToyota.ShipTos'), 'IsView') = 1 begin
	drop view EDIToyota.ShipTos
end
go

create view EDIToyota.ShipTos
as
select
	ShipToCode = coalesce(ds.destination, es.destination)
,	EDIShipToCode = es.parent_destination
,	FOB = ds.fob
,	Carrier = ds.scac_code
,	TransMode = ds.trans_mode
,	FreightType = ds.freight_type
,	ShipperNote = ds.note_for_shipper
from
	dbo.destination_shipping ds
	join dbo.edi_setups es
		on es.destination = ds.destination
where
	trading_partner_code like '%TMMI%'
go

select
	st.ShipToCode
,   st.EDIShipToCode
,   st.FOB
,   st.Carrier
,   st.TransMode
,   st.FreightType
,   st.ShipperNote
from
	EDIToyota.ShipTos st
order by
	st.ShipToCode
go
