SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_resource_task_list] (
	resource_name,
	resource_type,
	task_id,
	task_type,
	task_sequence,
	task_start,
	task_end,
	task_duration,
	task_description,
	task_due,
	task_balance,
	task_yield)
as select resource_name,
	resource_type,
	Convert ( integer, work_order ),
	1,
	sequence,
	convert(datetime,IsNull(convert(varchar,start_date,111),'0001-01-01')+substring(convert(varchar,start_time,109),12,15)),
	convert(datetime,IsNull(convert(varchar,end_date,111),'0001-01-01')+substring(convert(varchar,end_time,109),12,15)),
	DateDiff ( second, start_date, end_date ) runtime,
	(select min(part)
	from workorder_detail
	where workorder=work_order),
	work_order.due_date,
	IsNull (
	(	select	Min ( balance )
		from	workorder_detail
		where	workorder_detail.workorder = work_order.work_order ), 0 ),
	IsNull (
	(	select	min ( on_hand / bom.std_qty )
		from	workorder_detail
			join bill_of_material bom on workorder_detail.part = bom.parent_part
			join part_online on bom.part = part_online.part
		where	workorder_detail.workorder = work_order.work_order and
			bom.std_qty > 0 ), 0 )
from work_order 
     join mvw_pb_resource_list on machine_no=resource_name and resource_type=1
GO
