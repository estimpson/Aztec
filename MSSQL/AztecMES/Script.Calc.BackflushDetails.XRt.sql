/*
*/
drop table
	tempdb..XRt
go
set nocount on

declare
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
,	@QtyRequested numeric(20,6)

set	@WorkOrderNumber = 'WO_0000000001'
set	@WorkOrderDetailLine = 1
set @QtyRequested = 140

create table tempdb..XRt
(	TopPart varchar(25)
,	ChildPart varchar(25)
,	BOMID int
,	Sequence tinyint
,	BOMLevel tinyint
,	Suffix int
,	XQty numeric(30,12)
,	XScrap numeric(30,12)
,	XSuffix numeric(30,12)
,	SubForBOMID int
,	SubRate numeric(20,6)
)

insert
	tempdb..XRt
select
	TopPart = wod.PartCode
,	ChildPart = wodbom.ChildPart
,	BOMID = wodbom.RowID
,	Sequence = wodbom.ChildPartSequence --row_number() over (order by wodbom.ChildPartSequence)
,	BOMLevel = wodbom.ChildPartBOMLevel
,	Suffix = wodbom.Suffix
,	XQty = wodbom.XQty
,	XScrap = wodbom.XScrap
,	XSuffix =  1
,	SubForBOMID = wodbom.SubForRowID
,	SubPercentage = case wodbom.SubPercentage when .5 then .6 end
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
	join dbo.WorkOrderDetails wod
		on wodbom.WorkOrderNumber = wod.WorkOrderNumber
		and wodbom.WorkOrderDetailLine = wod.Line
where
	wodbom.WorkOrderNumber = @WorkOrderNumber
	and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
	and wodbom.Status >= 0
order by
	wodbom.ChildPartSequence

insert
	tempdb..XRt
select
	TopPart = xr1.ChildPart
,	xr2.ChildPart
,	xr2.BOMID
,	Sequence = xr2.Sequence - xr1.Sequence
,	BOMLevel = xr2.BOMLevel - xr1.BOMLevel
,	Suffix = xr2.Suffix
,	XQty = xr2.XQty / xr1.XQty
,	XSCrap = xr2.XScrap / xr1.XScrap
,	XSuffix = xr2.XSuffix / xr1.XSuffix
,	SubForBOMID = xr2.SubForBOMID
,	SubRate = xr2.SubRate
from
	tempdb..XRt xr1
	cross join tempdb..XRt xr2
where
	xr2.Sequence > xr1.Sequence
	and xr2.BOMLevel > xr1.BOMLevel
	and xr2.Sequence <
	(	select
			min(xrCheck.Sequence)
		from
			tempdb..XRt xrCheck
		where
			xrCheck.Sequence > xr1.Sequence
			and xrCheck.BOMLevel <= xr1.BOMLevel
	)


select
	*
from
	tempdb..XRt xr
order by
	TopPart
,	Sequence