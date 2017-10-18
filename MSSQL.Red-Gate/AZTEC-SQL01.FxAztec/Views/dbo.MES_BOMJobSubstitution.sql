SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_BOMJobSubstitution]
as
select
	mjbomPri.WorkOrderNumber
,	mjbomPri.WODID
,	mjbomPri.WorkOrderDetailLine
,	mjbomPri.WODBOMID
,	ParentPartCode = bomPri.parent_part
,	PrimaryPartCode = bomPri.part
,	PrimaryCommodity = pPri.commodity
,	PrimaryDescription = pPri.name
,	PrimaryXQty = mjbomPri.XQty
,	PrimaryXScrap = mjbomPri.XScrap
,	PrimaryBOMID = bomPri.ID
,	SubstitutePartCode = coalesce(mjbomSub.ChildPart, bomSub.part)
,	SubstituteCommodity = pSub.commodity
,	SubstituteDescription = pSub.name
,	SubstituteXQty = coalesce(mjbomSub.XQty, mjbomPri.XQty)
,	SubstituteXScrap = coalesce(mjbomSub.XScrap, mjbomPri.XScrap)
,	SubstituteBOMID = bomSub.ID
,	SubstitutionType =
		case
			when mjbomSub.SubPercentage = 100 then 1
			when mjbomSub.SubPercentage = 0 then 2
			when mjbomSub.SubPercentage between 0 and 100 then 3
		end
,	SubstitutionRate = mjbomSub.SubPercentage
from
	dbo.MES_JobBillOfMaterials mjbomPri
		join dbo.part pPri
			on pPri.part = mjbomPri.ChildPart
		join dbo.bill_of_material bomPri
			on bomPri.ID = mjbomPri.BillOfMaterialID
	left join dbo.MES_JobBillOfMaterials mjbomSub
		on mjbomSub.WODID = mjbomPri.WODID
		and mjbomSub.SubForRowID = mjbomPri.WODBOMID
	left join dbo.bill_of_material bomSub
		left join dbo.part pSubCom
			on pSubCom.part = bomSub.part
		on bomSub.parent_part = bomPri.parent_part
		and pSubCom.commodity = pPri.commodity
		and coalesce(bomSub.substitute_part, 'N') = 'Y'
	left join dbo.part pSub
		on pSub.part = coalesce(mjbomSub.ChildPart, bomSub.part)
where
	coalesce(bomPri.substitute_part, 'N') != 'Y'
GO
