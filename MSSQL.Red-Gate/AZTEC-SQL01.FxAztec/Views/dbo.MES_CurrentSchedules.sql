SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_CurrentSchedules]
as
select
	WODID = max(wodActive.RowID)
,	WorkOrderNumber = max(wohActive.WorkOrderNumber)
,   WorkOrderStatus = max(wohActive.Status)
,   WorkOrderType = max(wohActive.Type)
,   MachineCode = max(wohActive.MachineCode)
,   WorkOrderDetailLine = max(wodActive.Line)
,   WorkOrderDetailStatus = max(wodActive.Status)
,   mjl.PartCode
,   WorkOrderDetailSequence = max(wodActive.Sequence)
,   DueDT = max(wodActive.DueDT)
,   QtyRequired = sum(mjl.QtyRequired)
,   QtyLabelled = sum(mjl.QtyLabelled)
,   QtyCompleted = sum(mjl.QtyCompleted)
,   QtyDefect = sum(mjl.QtyDefect)
,	StandardPack = max(mjl.StandardPack)
,	NewBoxesRequired = sum(mjl.NewBoxesRequired)
,	BoxesLabelled = sum(mjl.BoxesLabelled)
,	BoxesCompleted = sum(mjl.BoxesCompleted)
,   StartDT = max(wodActive.StartDT)
,   EndDT = max(wodActive.EndDT)
,   ShipperID = max(wodActive.ShipperID)
,   mjl.BillToCode
from
	dbo.MES_JobList mjl
	join dbo.WorkOrderHeaders wohActive
		join dbo.WorkOrderDetails wodActive
			on wodActive.WorkOrderNumber = wohActive.WorkOrderNumber
		on wodActive.PartCode = mjl.PartCode
		and wodActive.CustomerCode = mjl.BillToCode
		and wodActive.RowID = coalesce
		(	(	select
		 			max(wod.RowID)
		 		from
					dbo.WorkOrderHeaders woh
						join dbo.WorkOrderDetails wod
							on wod.WorkOrderNumber = woh.WorkOrderNumber
				where
					wod.RowID = wodActive.RowID
					and	woh.Status in
					(	select
	 						sd.StatusCode
	 					from
	 						FT.StatusDefn sd
	 					where
	 						sd.StatusTable = 'dbo.WorkOrderHeaders'
	 						and sd.StatusName = 'Running'
					 )
					 and wod.Status in
					 (	select
	  						sd.StatusCode
	  					from
	  						FT.StatusDefn sd
	  					where
	  						sd.StatusTable = 'dbo.WorkOrderDetails'
	 						and sd.StatusName = 'Running'
					 )
			)
		,	(	select
		 			max(wod.RowID)
		 		from
					dbo.WorkOrderHeaders woh
						join dbo.WorkOrderDetails wod
							on wod.WorkOrderNumber = woh.WorkOrderNumber
				where
					wod.RowID = wodActive.RowID
					and	woh.Status in
					(	select
							sd.StatusCode
						from
							FT.StatusDefn sd
						where
							sd.StatusTable = 'dbo.WorkOrderHeaders'
							and sd.StatusName = 'New'
					 )
					 and wod.Status in
					 (	select
							sd.StatusCode
						from
							FT.StatusDefn sd
						where
							sd.StatusTable = 'dbo.WorkOrderDetails'
							and sd.StatusName = 'New'
					 )
			)
		)
group by
	mjl.PartCode
,	mjl.BillToCode
GO
