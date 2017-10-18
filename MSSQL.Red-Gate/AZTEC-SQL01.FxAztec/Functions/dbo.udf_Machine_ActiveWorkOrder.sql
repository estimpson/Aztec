SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[udf_Machine_ActiveWorkOrder]
(	@MachineCode varchar (10)
)
returns	int
as
/*
Assertions:
1.	There can only be one work order for a machine that has sequence 1.
	a.	Enforcement - not established

Example:
Test syntax {
select	workorder.udf_ActiveWorkOrder ('10M3000')
}
*/
begin
	declare	@ActiveWorkOrder int
	
	set	@ActiveWorkOrder =
		(	select
				min (WorkOrderID)
			from
				dbo.WorkOrderHeaders
			where
				MachineCode = @MachineCode
				and
					Sequence = 1
				and
					ActualEndDT is null
		)
	
	return	@ActiveWorkOrder
end
GO
