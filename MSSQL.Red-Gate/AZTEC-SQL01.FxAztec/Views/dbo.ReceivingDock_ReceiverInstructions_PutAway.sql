SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReceivingDock_ReceiverInstructions_PutAway]
as
select
	rhs.ReceiverID
,	StepPrecedence = 3.0
,	rhs.ReceiverNumber
,	rhs.Type
,	rhs.TypeName
,	rhs.Status
,	rhs.StatusName
,	rhs.OriginType
,	rhs.OriginTypeName
,	rhs.SupplierLabelComplianceStatus
,	rhs.SupplierLabelComplianceStatusName
,	StepType = 3
,	StepTypeName = 'Put Away'
,	StepTypeDescription = 'Transfer inventory to rack or allocate to floor.'
,	StepStatus =
		case
			when rhs.Status = 5 then 1
			when
				rhs.Status = 3
				and exists
					(	select
				    		*
				    	from
				    		dbo.ReceiverObjects ro
							join dbo.ReceiverLines rl
								on rl.ReceiverLineID = ro.ReceiverLineID
							join dbo.object o
								on o.serial = ro.Serial
						where
							rl.ReceiverID = rhs.ReceiverID
							and o.location != ro.Location
				    ) then 2
			else 0
		end
,	StepStatusName =
		case
			when rhs.Status = 5 then 'Completed'
			when
				rhs.Status = 3
				and exists
					(	select
				    		*
				    	from
				    		dbo.ReceiverObjects ro
							join dbo.ReceiverLines rl
								on rl.ReceiverLineID = ro.ReceiverLineID
							join dbo.object o
								on o.serial = ro.Serial
						where
							rl.ReceiverID = rhs.ReceiverID
							and o.location != ro.Location
				    ) then 'In process'
			else 'Ready to begin'
		end
from
	dbo.ReceivingDock_ReceiverHeaderStatus rhs
where
	rhs.SupplierLabelComplianceStatus in (-1, 0)
GO
