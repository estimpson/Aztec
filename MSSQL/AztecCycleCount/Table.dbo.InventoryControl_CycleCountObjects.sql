
/*
Create table Fx.dbo.InventoryControl_CycleCountObjects
*/

--use Fx
--go

--drop table dbo.InventoryControl_CycleCountObjects
if	objectproperty(object_id('dbo.InventoryControl_CycleCountObjects'), 'IsTable') is null begin

	create table dbo.InventoryControl_CycleCountObjects
	(	CycleCountNumber varchar(50) references dbo.InventoryControl_CycleCountHeaders(CycleCountNumber)
	,	Line float
	,	Serial int
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	Part varchar(25) not null
	,	OriginalQuantity numeric(20,6) not null
	,	CorrectedQuantity numeric(20,6) null
	,	Unit char(2) not null
	,	OriginalLocation varchar(10) not null
	,	CorrectedLocation varchar(10) null
	,	RowID int identity(1,1) primary key nonclustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique clustered
		(	CycleCountNumber
		,	Line
		)
	,	unique nonclustered
		(	CycleCountNumber
		,	Serial
		)
	)
end
go

select
	iccco.CycleCountNumber
,	iccco.Line
,	iccco.Serial
,	iccco.Status
,	iccco.Type
,	iccco.Part
,	iccco.OriginalQuantity
,	iccco.CorrectedQuantity
,	iccco.Unit
,	iccco.OriginalLocation
,	iccco.CorrectedLocation
,	iccco.RowID
,	iccco.RowCreateDT
,	iccco.RowCreateUser
,	iccco.RowModifiedDT
,	iccco.RowModifiedUser
from
	dbo.InventoryControl_CycleCountObjects iccco
order by
	iccco.CycleCountNumber
,	iccco.Line
