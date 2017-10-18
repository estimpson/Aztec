SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_resource_shift_list] (
	resource_name,
	shift_Id,
	shift_start,
	shift_end,
	shift_labor,
	shift_crew,
	shift_length)
as select machine,
	ai_id,	
	begin_datetime,
	end_datetime,
	labor_code,
	crew_size,
	convert ( numeric, datediff ( hour, begin_datetime, end_datetime) ) 
from	shop_floor_calendar 
	join mvw_pb_resource_list on machine=resource_name
	and resource_type=1 
where	begin_datetime >= dateadd(dd,-1,getdate())
GO
