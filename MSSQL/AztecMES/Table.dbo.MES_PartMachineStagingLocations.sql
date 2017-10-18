
/*
Create table fx21st.dbo.MES_PartMachineStagingLocations
*/

--use fx21st
--go

--drop table dbo.MES_GroupTechnologyStagingLocations
if	objectproperty(object_id('dbo.MES_GroupTechnologyStagingLocations'), 'IsTable') is null begin

	create table dbo.MES_GroupTechnologyStagingLocations
	(	Part varchar(25) not null references dbo.part on update cascade on delete cascade unique
	,	Machine varchar(10) not null references dbo.machine(machine_no) on update cascade on delete cascade unique
	,	Status int not null default(0)
	,	StagingLocation varchar(10) not null references dbo.location(code) on update cascade on delete cascade unique
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique
		(	Part
		,	Machine
		)
	)
end
go

insert
	dbo.MES_GroupTechnologyStagingLocations
(	Part
,	Machine
,	StagingLocation
)
select
	Part = '1201B'
,	Machine = '4'
,	StagingLocation = 'TL 1 STAGE'

select
	*
from
	dbo.MES_GroupTechnologyStagingLocations
