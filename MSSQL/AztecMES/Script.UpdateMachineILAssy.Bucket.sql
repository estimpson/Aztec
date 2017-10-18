
update
	pm
set
	machine = pm2.machine
from
	dbo.part_machine pm
	join FT.XRt xr
		on xr.TopPart = pm.part
		and xr.ChildPart like '1200[12][901]%'
	join dbo.part_machine pm2
		on pm2.part = xr.ChildPart
		and pm2.sequence = 1
where
	pm.part in (select part from part where type = 'F')
	and pm.part not in (select ChildPart from FT.XRt xr1 where xr1.Sequence > 1)
	and pm.sequence = 1
