
/*
Create view fx21st.dbo.Scheduling_NetRequirementsSummary
*/

--use fx21st
--go

--drop table dbo.Scheduling_NetRequirementsDetails
if	objectproperty(object_id('dbo.Scheduling_NetRequirementsDetails'), 'IsView') = 1 begin
	drop view dbo.Scheduling_NetRequirementsDetails
end
go

create view dbo.Scheduling_NetRequirementsDetails
as
select
	PrimaryMachineCode = pm.machine
,	BuildPartCode = fmnm.Part
,	OrderNo = oh.order_no
,	BillToCode = oh.customer
,	ShipToCode = oh.destination
,	fmnm.LowLevel
,	RequiredDT = fmnm.RequiredDT
,	QtyTotalDue = convert(numeric(20,6), fmnm.GrossDemand)
,	QtyAvailable = fmnm.OnHandQty
,	QtyAlreadyProduced = fmnm.WIPQty
,	QtyNetDue = fmnm.Balance
,	QtyBuildable = fmnm.BuildableQty
,	RunningWODID = wodR.RowID
,	QtyRunningBuild =
	case
		when
			(	case
					when wodR.QtyRequired >= wodR.QtyLabelled then wodR.QtyRequired
					else wodR.QtyLabelled
				end - wodR.QtyCompleted
			) > fmnm.AccumBalance
			then
			(	case
					when wodR.QtyRequired >= wodR.QtyLabelled then wodR.QtyRequired
					else wodR.QtyLabelled
				end - wodR.QtyCompleted
			)
		when
			(	case
					when wodR.QtyRequired >= wodR.QtyLabelled then wodR.QtyRequired
					else wodR.QtyLabelled
				end - wodR.QtyCompleted
			) < fmnm.AccumBalance - fmnm.Balance
			then 0
		else
			(	case
					when wodR.QtyRequired >= wodR.QtyLabelled then wodR.QtyRequired
					else wodR.QtyLabelled
				end - wodR.QtyCompleted
			) - (fmnm.AccumBalance - fmnm.Balance)
	end	
,	NextWODID = wodN.RowID
,	QtyNextBuild =
	case
		when
			(	case
					when wodN.QtyRequired >= wodN.QtyLabelled then wodN.QtyRequired
					else wodN.QtyLabelled
				end - wodN.QtyCompleted
			) > fmnm.AccumBalance
			then
			(	case
					when wodN.QtyRequired >= wodN.QtyLabelled then wodN.QtyRequired
					else wodN.QtyLabelled
				end - wodN.QtyCompleted
			)
		when
			(	case
					when wodN.QtyRequired >= wodN.QtyLabelled then wodN.QtyRequired
					else wodN.QtyLabelled
				end - wodN.QtyCompleted
			) < fmnm.AccumBalance - fmnm.Balance
			then 0
		else
			(	case
					when wodN.QtyRequired >= wodN.QtyLabelled then wodN.QtyRequired
					else wodN.QtyLabelled
				end - wodN.QtyCompleted
			) - (fmnm.AccumBalance - fmnm.Balance)
	end
,	BoxLabel = coalesce(oh.box_label, pi.label_format)
,	PalletLabel = oh.pallet_label
,	PackageType = coalesce(oh.package_type, (select max(code) from dbo.part_packaging where part = fmnm.Part))
,	TopPartCode = vs.Part
from
	dbo.fn_MES_NetMPS() fmnm
	join dbo.vwSOD vs
		on vs.LineID = fmnm.LineID
		and vs.OrderNo = fmnm.OrderNo
	left join dbo.order_header oh
		on oh.order_no = fmnm.OrderNo
		and oh.blanket_part = fmnm.Part
	join dbo.part_inventory pi
		on pi.part = fmnm.Part
	join dbo.part_machine pm
		on pm.part = fmnm.Part
		and pm.sequence = 1
	left join dbo.WorkOrderHeaders wohR
		join dbo.WorkOrderDetails wodR
			on wohR.WorkOrderNumber = wodR.WorkOrderNumber
		on wohR.Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'Running')
		and coalesce(wodR.SalesOrderNumber, -1) = coalesce(fmnm.OrderNo, -1)
		and coalesce(wodR.CustomerCode, '~~~~') = coalesce(oh.customer, '~~~~')
		and coalesce(wodR.DestinationCode, '~~~~') = coalesce(oh.destination, '~~~~')
		and coalesce(wodR.TopPartCode, vs.Part) = vs.Part
		and wodR.PartCode = fmnm.Part
	left join dbo.WorkOrderHeaders wohN
		join dbo.WorkOrderDetails wodN
			on wohN.WorkOrderNumber = wodN.WorkOrderNumber
		on wohN.Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'New')
		and coalesce(wodN.SalesOrderNumber, -1) = coalesce(fmnm.OrderNo, -1)
		and coalesce(wodN.CustomerCode, '~~~~') = coalesce(oh.customer, '~~~~')
		and coalesce(wodN.DestinationCode, '~~~~') = coalesce(oh.destination, '~~~~')
		and coalesce(wodN.TopPartCode, vs.Part) = vs.Part
		and wodN.PartCode = fmnm.Part
go

select
	*
from
	dbo.Scheduling_NetRequirementsDetails snrd
go

