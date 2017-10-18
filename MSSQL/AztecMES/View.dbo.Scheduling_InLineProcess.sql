
/*
Create view fx21st.dbo.Scheduling_InLineProcess
*/

--use fx21st
--go

--drop table dbo.Scheduling_InLineProcess
if	objectproperty(object_id('dbo.Scheduling_InLineProcess'), 'IsView') = 1 begin
	drop view dbo.Scheduling_InLineProcess
end
go

create view dbo.Scheduling_InLineProcess
as
with 
	xr
	(	TopMachineCode, MachineCode, BOMStructure, XRtID, TopPartCode, ChildPartCode, BOMID, Sequence, BOMLevel, XQty, XScrap, Hierarchy
	)
as
	(	select
				TopMachineCode = pmTopPrimary.machine
			,	MachineCode = pmPrimary.machine
			,	BOMStructure = space(xr.BOMLevel * 3) + xr.ChildPart
			,	XRtID = xr.ID
			,   TopPartCode = xr.TopPart
			,   ChildPartCode = xr.ChildPart
			,   xr.BOMID
			,   xr.Sequence
			,   xr.BOMLevel
			,   xr.XQty
			,   xr.XScrap
			,	xr.Hierarchy
		from
			FT.XRt xr
			left join dbo.part_machine pmTopPrimary
				on pmTopPrimary.part = xr.TopPart
				and pmTopPrimary.sequence = 1
			left join dbo.part_machine pmPrimary
				on pmPrimary.part = xr.ChildPart
				and pmPrimary.sequence = 1
	)
,	inlineXR
	(	TopMachineCode, BOMStructure, TopPartCode, ChildPartCode, MachineCode, BOMID, XQty, XScrap, BOMLevel, LowLevel, Sequence, Hierarchy
	)
	as
	(	select
			xr.TopMachineCode
		,	xr.BOMStructure
		,	xr.TopPartCode
		,	xr.ChildPartCode
		,	xr.MachineCode
		,	xr.BOMID
		,	xr.XQty
		,	xr.XScrap
		,	xr.BOMLevel
		,	LowLevel = (select max(xr1.BOMLevel) from xr xr1 where xr1.TopPartCode = xr.TopPartCode and xr1.ChildPartCode = xr.ChildPartCode)
		,	xr.Sequence
		,	xr.Hierarchy
		from
			xr xr
		where
			not exists
			(	select
	 				*
	 			from
	 				xr xr1
	 				join xr xr2
	 					on xr2.ChildPartCode = xr1.TopPartCode
	 					and xr2.TopPartCode = xr.TopPartCode
	 			where
	 				xr.Sequence = xr1.Sequence + xr2.Sequence
	 				and coalesce(xr2.MachineCode, '') != coalesce(xr.TopMachineCode, '')
			 )
	)
select
	inlineXR.TopMachineCode
,   inlineXR.BOMStructure
,   inlineXR.TopPartCode
,   inlineXR.ChildPartCode
,   inlineXR.MachineCode
,   inlineXR.BOMID
,   inlineXR.XQty
,   inlineXR.XScrap
,   inlineXR.BOMLevel
,   inlineXR.LowLevel
,   inlineXR.Sequence
,	inlineXR.Hierarchy
,	InLineTemp = case
		when
			(	select
					count(*)
				from
					xr xr1
					join xr xr2
						on xr2.ChildPartCode = xr1.TopPartCode
						and xr2.TopPartCode = inlineXR.TopPartCode
				where
					xr2.Sequence > 0
					and xr1.Sequence > 0
					and xr1.Sequence = inlineXR.Sequence + xr2.Sequence
			 ) > 0 then 1
		else 0
	end
from
	inlineXR
where
	MachineCode is not null
go


select
	silp.*
from
	dbo.Scheduling_InLineProcess silp
where
	silp.TopPartCode = '1217SWR20B'
order by
	silp.Sequence

select
	silp.Sequence + xr.Sequence
,	coalesce
	(	(	select
				dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
			from
				dbo.Scheduling_InLineProcess
			where
				TopPartCode = '1217SWR20B'
				and ChildPartCode = xr.ChildPart
		)
	,	dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
	)
,	xr.*, silp.*
from
	dbo.Scheduling_InLineProcess silp
	join FT.XRt xr
		on xr.TopPart = silp.ChildPartCode
		and xr.BOMLevel = 1
where
	silp.TopPartCode = '1217SWR20B'
order by
	silp.Sequence + xr.Sequence

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
	xr.TopPart = '1217SWR20B'
order by
	xr.Sequence
go

