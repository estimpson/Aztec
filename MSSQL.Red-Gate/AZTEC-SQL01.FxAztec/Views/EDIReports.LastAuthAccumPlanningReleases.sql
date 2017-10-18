SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create view [EDIReports].[LastAuthAccumPlanningReleases]
as
Select  'CHRYSLER' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDICHRY.CurrentPlanningReleases() ccpr
 left join
		EDIChry.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION
Select  'EDI2001' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI2001.CurrentPlanningReleases() ccpr
 left join
		EDI2001.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION
Select  'EDI2002' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI2002.CurrentPlanningReleases() ccpr
 left join
		EDI2002.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION

Select  'EDI2040' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI2040.CurrentPlanningReleases() ccpr
 left join
		EDI2040.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION

Select  'EDI3010' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI3010.CurrentPlanningReleases() ccpr
 left join
		EDI3010.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION
Select  'EDI3020' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI3020.CurrentPlanningReleases() ccpr
 left join
		EDI3020.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
UNION
Select  'EDI3060' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI3060.CurrentPlanningReleases() ccpr
 left join
		EDI3060.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode

UNION

Select  'EDI4010' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDI4010.CurrentPlanningReleases() ccpr
 left join
		EDI4010.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
		
UNION

Select  'EDIEDIFACT96A' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDIEDIFACT96A.CurrentPlanningReleases() ccpr
 left join
		EDIEDIFACT96A.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode

UNION

Select  'EDIEDIFACT97A' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDIEDIFACT97A.CurrentPlanningReleases() ccpr
 left join
		EDIEDIFACT97A.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode

UNION

Select  'EDIFORD' as EDIGroup,
				'AuthAccums in Planning Release' as DocumentType,
				cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.PriorCUM as PriorAccumRequired,
				cpa.PriorCUMEndDT as AccumStartDT,
				cpa.PriorCUMEndDT as AccumEndDT
 From 
		EDIFORD.CurrentPlanningReleases() ccpr
 left join
		EDIFORD.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
		
		
		
		





		
		



GO
