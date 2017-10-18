
/*
Create view fx21st.dbo.Scheduling_NetRequirementsSummary
*/

--use fx21st
--go

--drop table dbo.Scheduling_NetRequirementsSummary
if	objectproperty(object_id('dbo.Scheduling_NetRequirementsSummary'), 'IsView') = 1 begin
	drop view dbo.Scheduling_NetRequirementsSummary
end
go

create view dbo.Scheduling_NetRequirementsSummary
as
select
	snrd.PrimaryMachineCode
,	snrd.BuildPartCode
,	snrd.OrderNo
,	snrd.BillToCode
,	snrd.ShipToCode
,	snrd.LowLevel
,	DueDT = min(case when snrd.QtyNetDue > 0 then snrd.RequiredDT end)
,	DaysOnHand = datediff(day, getdate(), min(case when snrd.QtyNetDue > 0 then snrd.RequiredDT end))
,	QtyTotalDue = sum(snrd.QtyTotalDue)
,	QtyAvailable = sum(snrd.QtyAvailable)
,	QtyAlreadyProduced = sum(snrd.QtyAlreadyProduced)
,	QtyNetDue = sum(snrd.QtyNetDue)
,	QtyBuildable = sum(snrd.QtyBuildable)
,	RunningWODID = min(snrd.RunningWODID)
,	QtyRunningBuild = sum(snrd.QtyRunningBuild)
,	NextWODID = min(snrd.NextWODID)
,	QtyNextBuild = sum(snrd.QtyNextBuild)
,	BoxLabel = max(snrd.BoxLabel)
,	PalletLabel = max(snrd.PalletLabel)
,	PackageType = max(snrd.PackageType)
,	snrd.TopPartCode
from
	dbo.Scheduling_NetRequirementsDetails snrd
group by
	snrd.PrimaryMachineCode
,	snrd.BuildPartCode
,	snrd.OrderNo
,	snrd.BillToCode
,	snrd.ShipToCode
,	snrd.LowLevel
,	snrd.TopPartCode
go


select
	*
from
	dbo.Scheduling_NetRequirementsSummary
go

select
	snrd.PrimaryMachineCode
,   snrd.BuildPartCode
,   snrd.OrderNo
,   snrd.BillToCode
,	DueDT = min(case when snrd.QtyNetDue > 0 then snrd.RequiredDT end)
,	DaysOnHand = datediff(day, getdate(), min(case when snrd.QtyNetDue > 0 then snrd.RequiredDT end))
,   QtyTotalDue = sum(snrd.QtyTotalDue)
,   QtyAvailable = sum(snrd.QtyAvailable)
,   QtyAlreadyProduced = sum(snrd.QtyAlreadyProduced)
,   QtyNetDue = sum(snrd.QtyNetDue)
,   QtyBuildable = sum(snrd.QtyBuildable)
,   RunningWODID = min(snrd.RunningWODID)
,   QtyRunningBuild = sum(snrd.QtyRunningBuild)
,   NextWODID = min(snrd.NextWODID)
,   QtyNextBuild = sum(snrd.QtyNextBuild)
,   BoxLabel = min(snrd.BoxLabel)
,   PalletLabel = min(snrd.PalletLabel)
,   PackageType = min(snrd.PackageType)
from
	dbo.Scheduling_NetRequirementsDetails snrd
where
	snrd.QtyNetDue > 0
group by
	snrd.PrimaryMachineCode
,   snrd.BuildPartCode
,   snrd.OrderNo
,   snrd.BillToCode
,   snrd.RunningWODID
,   snrd.NextWODID
go

