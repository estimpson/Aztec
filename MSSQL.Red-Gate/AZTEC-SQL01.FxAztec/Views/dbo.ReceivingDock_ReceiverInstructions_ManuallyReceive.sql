SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReceivingDock_ReceiverInstructions_ManuallyReceive]
as
select
	rhs.ReceiverID
,	StepPrecedence = 1.0
,	rhs.ReceiverNumber
,	rhs.Type
,	rhs.TypeName
,	rhs.Status
,	rhs.StatusName
,	rhs.OriginType
,	rhs.OriginTypeName
,	rhs.SupplierLabelComplianceStatus
,	rhs.SupplierLabelComplianceStatusName
,	StepType = 1
,	StepTypeName = 'Manually Receive'
,	StepTypeDescription = 'Manually receive inventory from the packing slip.'
,	StepStatus =
		case
			when rhs.Status = 5 then 1
			when rhs.Status = 3 then 2
			else 0
		end
,	StepStatusName =
		case
			when rhs.Status = 5 then 'Completed'
			when rhs.Status = 3 then 'Inprocess'
			else 'Ready to begin'
		end
from
	dbo.ReceivingDock_ReceiverHeaderStatus rhs
where
	rhs.OriginType = 1
	and rhs.SupplierLabelComplianceStatus in (-1, 0)
GO
