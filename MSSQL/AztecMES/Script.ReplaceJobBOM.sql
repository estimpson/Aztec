
select
	*
from
	FT.XRt xr
where
	xr.TopPart = '1254R21UVB'
order by
	xr.Sequence

select
	*
from
	dbo.part_machine pm
where
	part in ('1254R21UVB', '1200R21UVB', '120021UVB')

select
	*
from
	dbo.order_detail od
where
	od.part_number = '1254R20UVGB'

select
	*
from
	dbo.object o
where
	part = '1254R20UVGB'

select
	*
from
	dbo.WorkOrderDetails wod
where
	wod.PartCode like '1254R21UVB'
	and wod.Status in (0,1)
go

declare
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float

set	@WorkOrderNumber = ''
set	@WorkOrderDetailLine = 1

begin transaction

alter table dbo.WorkOrderDetailBillOfMaterials disable trigger all

delete
	wodbom
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.WorkOrderNumber = @WorkOrderNumber
	and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine

alter table dbo.WorkOrderDetailBillOfMaterials enable trigger all

insert
	dbo.WorkOrderDetailBillOfMaterials
(
	WorkOrderNumber
,	WorkOrderDetailLine
,	Line
,	Status
,	Type
,	ChildPart
,	ChildPartSequence
,	ChildPartBOMLevel
,	BillOfMaterialID
,	Suffix
,	QtyPer
,	XQty
,	XScrap
)
select
	wod.WorkOrderNumber
,	wod.Line
,	Line = row_number() over (partition by wod.WorkOrderNumber order by xr.Sequence)
,	Status =
		case
			when silp2.InLineTemp = 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Temporary WIP')
			else dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
		end
,	Type = dbo.udf_TypeValue('dbo.WorkOrderDetailBillOfMaterials', 'Material')
,	ChildPart = xr.ChildPart
,	ChildPartSequence = xr.Sequence
,	ChildPartBOMLevel = xr.BOMLevel
,	BillOfMaterialID = xr.BOMID
,	Suffix = null
,	QtyPer = null
,	xr.XQty
,	xr.XScrap
from
	FT.XRt xr
	join dbo.Scheduling_InLineProcess silp
		on silp.TopPartCode = xr.TopPart
		and xr.Hierarchy like silp.Hierarchy + '/%'
		and xr.BOMLevel = silp.BOMLevel + 1
	left join dbo.Scheduling_InLineProcess silp2
		 on silp2.TopPartCode = xr.TopPart
		 and silp2.Sequence = xr.Sequence
	join dbo.WorkOrderDetails wod
		on wod.PartCode = xr.TopPart
where
	WorkOrderNumber = @WorkOrderNumber
	and	Line = @WorkOrderDetailLine
order by
	wod.WorkOrderNumber
,	wod.Line
,	xr.Sequence

select
	*
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.WorkOrderNumber = @WorkOrderNumber
	and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
go
rollback
go

update
	dbo.WorkOrderHeaders
set
	status = 2
where
	WorkOrderNumber = 'WO_0000000208'
