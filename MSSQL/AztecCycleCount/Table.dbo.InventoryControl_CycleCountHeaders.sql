
/*
Create table Fx.dbo.InventoryControl_CycleCountHeaders
*/

--use Fx
--go

--drop table dbo.InventoryControl_CycleCountObjects
--drop table dbo.InventoryControl_CycleCountHeaders
if	objectproperty(object_id('dbo.InventoryControl_CycleCountHeaders'), 'IsTable') is null begin

	create table dbo.InventoryControl_CycleCountHeaders
	(	CycleCountNumber varchar(50) default ('0') not null
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	Description varchar(255) not null
	,	CountBeginDT datetime null
	,	CountEndDT datetime null
	,	ExpectedCount int null
	,	FoundCount int null
	,	RecoveredCount int null
	,	QtyAdjustedCount int null
	,	LocationChangedCount int null
	,	RowID int identity(1,1) primary key nonclustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique clustered
		(	CycleCountNumber
		)
	)
end
go

select
	iccch.CycleCountNumber
,	iccch.Status
,	iccch.Type
,	iccch.Description
,	iccch.CountBeginDT
,	iccch.CountEndDT
,	iccch.ExpectedCount
,	iccch.FoundCount
,	iccch.RecoveredCount
,	iccch.QtyAdjustedCount
,	iccch.LocationChangedCount
,	iccch.RowID
,	iccch.RowCreateDT
,	iccch.RowCreateUser
,	iccch.RowModifiedDT
,	iccch.RowModifiedUser
from
	dbo.InventoryControl_CycleCountHeaders iccch with (readcommitted)
