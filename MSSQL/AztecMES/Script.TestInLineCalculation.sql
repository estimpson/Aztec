
use tempdb
go

begin transaction
go

create table PartMFG
(	TopPart varchar(25), ChildPart varchar(25), Sequence int, TopMachineCode varchar(10), MachineCode varchar(10), Hierarchy varchar(1000)
,	primary key
	(	TopPart
	,	Sequence
	,	TopMachineCode
	,	MachineCode
	)
)
go

insert
	PartMFG
values
(	'A1', 'A1', 0, 'X', 'X', '/A1'
)

insert
	PartMFG
values
(	'A2', 'A2', 0, 'Z', 'Z', '/A2'
)

insert
	PartMFG
values
(	'A3', 'A3', 0, 'X', 'X', '/A3'
)

insert
	PartMFG
values
(	'A3', 'A3', 0, 'Z', 'Z', '/A3'
)

insert
	PartMFG
values
(	'A4', 'A4', 0, 'X', 'X', '/A4'
)

insert
	PartMFG
values
(	'A4', 'A4', 0, 'M', 'M', '/A4'
)

insert
	PartMFG
values
(	'B', 'B', 0, 'X', 'X', '/B'
)

insert
	PartMFG
values
(	'B', 'B', 0, 'M', 'M', '/B'
)

insert
	PartMFG
values
(	'C', 'C', 0, 'Y', 'Y', '/C'
)

insert
	PartMFG
values
(	'D', 'D', 0, 'X', 'X', '/D'
)

insert
	PartMFG
values
(	'E', 'E', 0, 'X', 'X', '/E'
)

insert
	PartMFG
select
	pm.TopPart, pm2.ChildPart, pm2.Sequence + 1, pm.MachineCode, pm2.MachineCode, pm.Hierarchy + pm2.Hierarchy
from
	PartMFG pm
	join PartMFG pm2
		on pm2.TopPart = 'E'
where
	pm.TopPart like 'D'

insert
	PartMFG
select
	pm.TopPart, pm2.ChildPart, pm2.Sequence + 1, pm.MachineCode, pm2.MachineCode, pm.Hierarchy + pm2.Hierarchy
from
	PartMFG pm
	join PartMFG pm2
		on pm2.TopPart = 'D'
where
	pm.TopPart like 'C'

insert
	PartMFG
select
	pm.TopPart, pm2.ChildPart, pm2.Sequence + 1, pm.MachineCode, pm2.MachineCode, pm.Hierarchy + pm2.Hierarchy
from
	PartMFG pm
	join PartMFG pm2
		on pm2.TopPart = 'C'
where
	pm.TopPart like 'B'

insert
	PartMFG
select
	pm.TopPart, pm2.ChildPart, pm2.Sequence + 1, pm.MachineCode, pm2.MachineCode, pm.Hierarchy + pm2.Hierarchy
from
	PartMFG pm
	join PartMFG pm2
		on pm2.TopPart = 'B'
where
	pm.TopPart like 'A%'
group by
	pm.TopPart, pm2.ChildPart, pm2.Sequence + 1, pm.MachineCode, pm2.MachineCode, pm.Hierarchy + pm2.Hierarchy
go










select
	TopPart
,	coalesce
	(	(	select
				min(pm1.ChildPart)
			from
				PartMFG pm1
			where
				pm1.TopPart = pm.TopPart
				and pm1.Sequence =
				(	select
						max(pm2.Sequence)
					from
						PartMFG pm2
					where
						pm2.TopPart = pm.TopPart
						and pm.MachineCode in (pm2.MachineCode)
						and pm.Sequence > pm2.Sequence
						and pm.Hierarchy like pm2.Hierarchy + '%'
				)
				and not exists
				(	select
						*
					from
						PartMFG pm3
					where
						pm3.TopPart = pm.TopPart
						and pm3.Hierarchy like pm1.Hierarchy + '%'
						and pm.Hierarchy like pm3.Hierarchy + '%'
						and pm3.Sequence > pm1.Sequence
						and pm3.Sequence < pm.Sequence
						and not exists
						(	select
								*
							from
								PartMFG pm4
							where
								pm4.TopPart = pm.TopPart
								and pm4.Sequence = pm3.Sequence
								and pm4.MachineCode = pm.MachineCode
						)
				)
		)
	,	ChildPart
	)
,	ChildPart
,	Sequence
,	TopMachineCode
,	MachineCode
,	Hierarchy
from
	PartMFG pm

go








rollback
go

