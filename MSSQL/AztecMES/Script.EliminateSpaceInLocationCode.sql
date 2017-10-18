begin transaction
go

update
	l
set
	code = Replace(l.code, ' ', '')
from
	dbo.location l
where
	l.code like '% %'
	and not exists (select
	                	*
	                from
	                	dbo.location l2
	                where
						l2.code = Replace(l.code, ' ', '')
					)

update
	o
set
	location = Replace(o.location, ' ', '')
from
	dbo.object o
where
	o.location like '% %'

update
	msl
set
	StagingLocationCode = Replace(msl.StagingLocationCode, ' ', '')
from
	dbo.MES_StagingLocations msl
where
	msl.StagingLocationCode like '% %'


update
	m
set
	machine_no = Replace(m.machine_no, ' ', '')
from
	dbo.machine m
where
	m.machine_no like '% %'

update
	pm
set
	machine = Replace(pm.machine, ' ', '')
from
	dbo.part_machine pm
where
	pm.machine like '% %'
go

commit
go
