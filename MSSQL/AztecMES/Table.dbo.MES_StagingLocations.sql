
/*
Create table fx21st.dbo.MES_StagingLocations
*/

--use fx21st
--go

--drop table dbo.MES_StagingLocations
if	objectproperty(object_id('dbo.MES_StagingLocations'), 'IsTable') is null begin

	create table dbo.MES_StagingLocations
	(	StagingLocationCode varchar(10) references dbo.location (code) on update cascade on delete cascade
	,	MachineCode varchar(10) references dbo.machine (machine_no) on update cascade on delete cascade
	,	PartCode varchar(25) references dbo.part (part) on update cascade on delete cascade
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	StagingLocationCode
		,	MachineCode
		,	PartCode
		)
	)
end
go

select
	*
from
	dbo.MES_StagingLocations msl
