/*
*/
drop table
	tempdb..NetMPS
go
set nocount on

declare
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
,	@QtyRequested numeric(20,6)

set	@WorkOrderNumber = 'WO_0000000001'
set	@WorkOrderDetailLine = 1
set @QtyRequested = 140

declare
	@PartRequested varchar(25)

select
	@PartRequested = wod.PartCode
from
	dbo.WorkOrderDetails wod
where
	wod.WorkOrderNumber = @WorkOrderNumber
	and wod.Line = @WorkOrderDetailLine

create table tempdb..NetMPS
(	ID int not null IDENTITY(1, 1) primary key
,	Part varchar(25) not null
,	BOMID int not null
,	Suffix int null
,	XQty numeric(30,12)
,	XScrap numeric(30,12)
,	SubForBOMID int null
,	SubDownRate numeric(20,6) null
,	SubRate numeric(20,6) null
,	Balance numeric(20,6) not null
,	QtyAvailable numeric(20,6) default(0) not null
,	QtyWIP numeric(20,6) default(0) not null
,	QtySubAlloc numeric(20,6) default(0) not null
,	QtyBuildable numeric(20,6) default(0) not null
,	BOMLevel tinyint not null
,	LowLevel tinyint not null
,	Sequence integer not null
)

insert
	tempdb..NetMPS
(	Part
,	BOMID
,	Suffix
,	XQty
,	XScrap
,	SubForBOMID
,	SubDownRate
,	SubRate
,	Balance
,	BOMLevel
,	LowLevel
,	Sequence
)
select
	Part = xr.ChildPart
,	BOMID = xr.BOMID
,	Suffix = xr.Suffix
,	XQty = xr.XQty
,	XScrap = xr.XScrap
,	SubForBOMID = xr.SubForBOMID
,	SubDownRate = 1 - (select sum(SubRate) from tempdb..XRt where TopPart = xr.ChildPart and SubForBOMID = xr.BOMID)
,	SubRate = xr.SubRate
,	Balance = @QtyRequested * (xr.XQty * xr.XScrap * xr.XSuffix)
,	BOMLevel = xr.BOMLevel
,	LowLevel = (select max(BOMLevel) from tempdb..XRt where TopPart = @PartRequested and ChildPart = xr.ChildPart)
,	Sequence = xr.Sequence
from
	tempdb..XRt xr
where
	TopPart = @PartRequested
	and BOMLevel >= 1

select
	*
from
	tempdb..NetMPS