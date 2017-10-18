use FxAztec
go

update
	es
set	es.IConnectID = '381'
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'FD%'
