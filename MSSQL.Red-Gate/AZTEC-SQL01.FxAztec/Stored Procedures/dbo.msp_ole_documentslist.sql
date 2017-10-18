SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure 	[dbo].[msp_ole_documentslist] (@machineno varchar(10), @part varchar(25), @workorder varchar(10)) as
select	distinct wod.part,
	ole.id
from	work_order wo
	left outer join	workorder_detail wod on wod.workorder = wo.work_order
	left outer join	issues iss on iss.product_code = wod.part or product_component = wod.part and iss.status = 'Assigned'
	join	ole_objects ole on ole.parent_id = convert(varchar, iss.issue_number)
where 	wo.machine_no = @machineno and
	wod.part = @part and 
	wo.work_order = @workorder
GO
