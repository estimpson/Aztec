SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SHIP].[DepartedShipperList]
as
select
	sed.ShipperNumber
,	CustomerCode = coalesce(sD.customer, v.code)
,	CustomerName = coalesce(c.name, v.name)
,	ShipToCode = sD.destination
,	ShipToName = d.name
,	TruckNumber = sD.truck_number
,	PRONumber = sD.pro_number
,	sed.LegacyShipperID
,	sed.ShipDT
,	sed.ShipperType
,	sed.DocumentType
,	sed.OverlayGroup
,	sed.LegacyGenerator
,	sed.FunctionName
,	sed.ExceptionHandler
,	sed.FileGenerationDT
,	sed.FileSendDT
,	sed.FileStatus
,	EDIStatus =
		case
			when
				coalesce(sed.FileStatus, 0) < 1
				and coalesce(ceglrLast.LastEDIDT, sed.ShipDT) < getdate() - (0.16 / 24.0) then -1
			else ceglrLast.EDIStatus
		end
,	EDIStatusCode =
		case
			when
				coalesce(sed.FileStatus, 0) = 0
				and coalesce(ceglrLast.LastEDIDT, sed.ShipDT) < getdate() - (0.16 / 24.0) then 'Late'
			when ceglrLast.EDIStatus is null then 'Pending'
			when ceglrLast.EDIStatus < 0 then 'Rejected'
			when ceglrLast.EDIStatus > 0 then 'Accepted'
		end
,	ceglr.EDIDeliveredDT
,	ceglrLastRejection.EDIRejectedDT
,	RejectionReason = coalesce
		(	case
				when
					coalesce(sed.FileStatus, 0) = 0
					and coalesce(ceglrLast.LastEDIDT, sed.ShipDT) < getdate() - (0.16 / 24.0) then 'Late'
			end
		,	ceglrLastRejection.RejectionReason
		)
,	ceglr.EDIResubmittedDT
from
	SHIP.EDIDocuments sed
	join dbo.shipper sD
		join dbo.destination d
			left join dbo.vendor v
				on v.code = d.vendor
			on d.destination = sD.destination
		left join dbo.customer c
			on c.customer = sD.customer
		on sD.id = sed.LegacyShipperID
	outer apply
		(	select top 1
				EDIStatus = ceglr.Status
			,	LastEDIDT = ceglr.RowCreateDT
			from
				dbo.CustomerEDI_GenerationLog_Responses ceglr
			where
				ceglr.ParentGenerationLogRowID = sed.RowID
			order by
				ceglr.RowID desc
		) ceglrLast
	outer apply
		(	select top 1
				EDIStatus = ceglr.Status
			,	EDIRejectedDT = ceglr.RowCreateDT
			,	RejectionReason = ceglr.MessageInfo
			,	ceglr.UserNotes
			from
				dbo.CustomerEDI_GenerationLog_Responses ceglr
			where
				ceglr.ParentGenerationLogRowID = sed.RowID
				and ceglr.Status < 0
			order by
				ceglr.RowID desc
		) ceglrLastRejection
	outer apply
		(	select
				EDIDeliveredDT =
					min
					(	case
							when ceglr.Type = 1 then ceglr.RowCreateDT
						end
					)
			,	EDIResubmittedDT =
					case
						when count(case when ceglr.Type = 1 then 1 end) > 1 then
							max
							(	case
									when ceglr.Type = 1 then ceglr.RowCreateDT
								end
							)
					end
			from
				dbo.CustomerEDI_GenerationLog_Responses ceglr
			where
				ceglr.ParentGenerationLogRowID = sed.RowID
				and ceglr.Status > 0
			group by
				ceglr.ParentGenerationLogRowID
		) ceglr
where
	(	sd.date_shipped > getdate() - (24.0 /24.0)
		and
		(	coalesce(sed.FileStatus, 0) < 1
			or coalesce(ceglrLast.LastEDIDT, sed.ShipDT) > getdate() - (0.50 / 24.0)
		)
	)
GO
