SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create view [EDICHRY].[LastAuthAccumPlanning]
as
Select  cpa.RowCreateDT as DateProcessed,
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
 join
		EDIChry.PlanningAuthAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
		



GO
