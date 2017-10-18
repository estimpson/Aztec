SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create view [EDICHRY].[LastAccumReceivedPlanning]
as
Select  cpa.RowCreateDT as DateProcessed,
				cpa.ReleaseNo as ReleaseNumber,
				cpa.ShipToCode as ShipToCode,
				cpa.CustomerPart as CustomerPart,
				cpa.CustomerPO as CustomerPO,
				cpa.CustomerModelYear as ModelYear,
				cpa.LastQtyReceived as LastQtyReceived,
				cpa.LastQtyDT as LastDateReceived,
				cpa.LastAccumQty as AccumQtyReceived
 From 
		EDICHRY.CurrentPlanningReleases() ccpr
 join
		EDIChry.PlanningAccums cpa on cpa.RawDocumentGUID =  ccpr.RawDocumentGUID
 and
		cpa.CustomerPart = ccpr.Customerpart
 and
		coalesce(cpa.CustomerPO, '') = coalesce (ccpr.CustomerPO,'')
and
		coalesce(cpa.CustomerModelYear,'') = coalesce(ccpr.CustomerModelYear,'')
and
		cpa.ShipToCode = ccpr.shipToCode
		



GO
