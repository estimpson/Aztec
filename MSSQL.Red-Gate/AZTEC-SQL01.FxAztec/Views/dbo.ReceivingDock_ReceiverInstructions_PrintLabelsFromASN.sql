SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReceivingDock_ReceiverInstructions_PrintLabelsFromASN]
as
select
	rhs.ReceiverID
,	StepPrecedence = 2.0
,	rhs.ReceiverNumber
,	rhs.Type
,	rhs.TypeName
,	rhs.Status
,	rhs.StatusName
,	rhs.OriginType
,	rhs.OriginTypeName
,	rhs.SupplierLabelComplianceStatus
,	rhs.SupplierLabelComplianceStatusName
,	StepType = 2
,	StepTypeName = 'Print Labels From ASN'
,	StepTypeDescription = 'Print labels from the ASN for all objects.'
,	StepStatus =
		case
			when rhs.Status = 5 then 1
			when exists
				(	select
						*
					from
						dbo.ReceiverObjects ro
							join dbo.ReceiverLines rl
								on rl.ReceiverLineID = ro.ReceiverLineID
					where
						rl.ReceiverID = rhs.ReceiverID
						and ro.Serial is not null
				) then 2
			else 0
		end
,	StepStatusName =
		case
			when rhs.Status = 5 then 'Completed'
			when exists
				(	select
						*
					from
						dbo.ReceiverObjects ro
							join dbo.ReceiverLines rl
								on rl.ReceiverLineID = ro.ReceiverLineID
					where
						rl.ReceiverID = rhs.ReceiverID
						and ro.Serial is not null
				) then 'Printed'
			else 'Ready to begin'
		end
from
	dbo.ReceivingDock_ReceiverHeaderStatus rhs
where
	rhs.OriginType = 2
	and rhs.SupplierLabelComplianceStatus in (-1, 0)
GO
