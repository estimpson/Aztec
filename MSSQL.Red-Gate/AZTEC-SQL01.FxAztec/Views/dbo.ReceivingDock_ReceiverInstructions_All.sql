SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReceivingDock_ReceiverInstructions_All]
as
select
	rdrimr.ReceiverID
,   rdrimr.StepPrecedence
,   rdrimr.ReceiverNumber
,   rdrimr.Type
,   rdrimr.TypeName
,   rdrimr.Status
,   rdrimr.StatusName
,   rdrimr.OriginType
,   rdrimr.OriginTypeName
,   rdrimr.SupplierLabelComplianceStatus
,   rdrimr.SupplierLabelComplianceStatusName
,   rdrimr.StepType
,   rdrimr.StepTypeName
,   rdrimr.StepTypeDescription
,   rdrimr.StepStatus
,   rdrimr.StepStatusName
from
	dbo.ReceivingDock_ReceiverInstructions_ManuallyReceive rdrimr
union all
select
	rdrimr.ReceiverID
,   rdrimr.StepPrecedence
,   rdrimr.ReceiverNumber
,   rdrimr.Type
,   rdrimr.TypeName
,   rdrimr.Status
,   rdrimr.StatusName
,   rdrimr.OriginType
,   rdrimr.OriginTypeName
,   rdrimr.SupplierLabelComplianceStatus
,   rdrimr.SupplierLabelComplianceStatusName
,   rdrimr.StepType
,   rdrimr.StepTypeName
,   rdrimr.StepTypeDescription
,   rdrimr.StepStatus
,   rdrimr.StepStatusName
from
	dbo.ReceivingDock_ReceiverInstructions_PrintLabelsFromASN rdrimr
union all
select
	rdrimr.ReceiverID
,   rdrimr.StepPrecedence
,   rdrimr.ReceiverNumber
,   rdrimr.Type
,   rdrimr.TypeName
,   rdrimr.Status
,   rdrimr.StatusName
,   rdrimr.OriginType
,   rdrimr.OriginTypeName
,   rdrimr.SupplierLabelComplianceStatus
,   rdrimr.SupplierLabelComplianceStatusName
,   rdrimr.StepType
,   rdrimr.StepTypeName
,   rdrimr.StepTypeDescription
,   rdrimr.StepStatus
,   rdrimr.StepStatusName
from
	dbo.ReceivingDock_ReceiverInstructions_PutAway rdrimr
GO
