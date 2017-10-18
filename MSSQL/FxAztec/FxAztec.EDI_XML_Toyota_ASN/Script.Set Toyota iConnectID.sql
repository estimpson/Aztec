use FxAztec
go

update
	es
set	IConnectID =
		case
			when es.trading_partner_code = 'TMMI' then '2233'
			when es.trading_partner_code = 'TMMK' then '1407'
			when es.trading_partner_code = 'TMMWV' then '2315'
			when es.trading_partner_code = 'TMMC' then '2232'
		end
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'T%'
	and es.destination != ''
