SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_WorkOrderDetail_WorkOrderID]
(	@WorkOrderDetailID int)
returns	int
as
begin
	declare
		@WorkOrderID int
	
	select
		@WorkOrderID = WorkOrderID
	from
		dbo.WorkOrderDetail wod
	where
		WorkOrderDetailID = @WorkOrderDetailID
	
	return
		@WorkOrderID
end
GO
