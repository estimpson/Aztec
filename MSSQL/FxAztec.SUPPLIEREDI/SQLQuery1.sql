select top 100
	*
from
	dbo.ReceiverHeaders rh
	join dbo.ReceiverLines rl
		on rl.ReceiverID = rh.ReceiverID
	join dbo.ReceiverObjects ro
		on ro.ReceiverLineID = rl.ReceiverLineID
where
	rh.Plant not like 'AZTEC _'
	and rh.ReceiverID = 16894
order by
	rh.ReceiverID desc

--	dbo.usp_Purchasing_Receive