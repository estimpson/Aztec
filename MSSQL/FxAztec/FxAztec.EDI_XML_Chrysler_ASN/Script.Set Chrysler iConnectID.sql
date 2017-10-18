update
	es
set	es.IConnectID = '136'
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'CH1%'
