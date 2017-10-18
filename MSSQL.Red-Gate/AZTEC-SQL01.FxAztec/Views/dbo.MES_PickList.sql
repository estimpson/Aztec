SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MES_PickList]
as
select
	mjl.MachineCode
,	mjl.WODID
,	mjl.WorkOrderNumber
,	mjl.PartCode
,	ChildPart = wodbom.ChildPart
,	QtyRequiredStandardPack = mjl.StandardPack * wodbom.XQty * wodbom.XScrap
,	QtyRequired = (mjl.QtyRequired - mjl.QtyCompleted) * wodbom.XQty * wodbom.XScrap
,	QtyAvailable = mai.QtyAvailable
,	QtyToPull =
		case
			when (mjl.QtyRequired - mjl.QtyCompleted) * wodbom.XQty * wodbom.XScrap > coalesce(mai.QtyAvailable, 0)
				then (mjl.QtyRequired - mjl.QtyCompleted) * wodbom.XQty * wodbom.XScrap - coalesce(mai.QtyAvailable, 0)
			else 0
		end
,	FIFOLocation = dbo.fn_MES_GetFIFOLocation_forPart(wodbom.ChildPart, 'A', null, null, null, 'N')
,	ProductLine = p.product_line
,	Commodity = p.commodity
,	PartName = p.name
from
	dbo.MES_JobList mjl
	left join dbo.WorkOrderDetailBillOfMaterials wodbom
		on	wodbom.WorkOrderNumber = mjl.WorkOrderNumber
			and wodbom.WorkOrderDetailLine = mjl.WorkOrderDetailLine
			and wodbom.Status >= 0
	left join dbo.part p on
		p.part = wodbom.ChildPart
	left join dbo.MES_AllocatedInventory mai on
		mai.PartCode = wodbom.ChildPart
		and
			mai.AvailableToMachine = mjl.MachineCode
GO
