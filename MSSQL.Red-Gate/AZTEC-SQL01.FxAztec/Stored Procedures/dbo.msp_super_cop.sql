SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure	[dbo].[msp_super_cop] (
	@regen_all	char (1),
	@order_no	numeric (8,0) = null,
	@row_id		integer = null )
as
-------------------------------------------------------------------------------------------------------------------------------
--	msp_super_cop : 	this procedure calls the explode demand procedure
--
--	parameters:		@regen_all char (1),
--				@order_no  numeric (8,0) null,
--				@row_id	   integer null
--
--	Process :
-- 	1. 	Call msp_explode_demand procedure
--	2. 	Set the flags on the releases
--
--	Development Team - 07/20/1999
--	Development Team - 08/26/1999	Modified update order_detail statement for performance.
--	
--------------------------------------------------------------------------------------------------------------------------------
-- 	1. Call msp_explode_demand procedure
if @regen_all = 'Y' 
begin
	execute msp_explode_demand

	update	order_detail 
	set 	flag = 0
	from 	order_detail 
		join master_prod_sched mps on mps.origin = order_detail.order_no and
			mps.source = order_detail.row_id
	where	order_detail.flag > 0
	
end 	
else 
	if @order_no is null
	begin 
		execute msp_explode_demand_flagged

		update	order_detail 
		set 	flag = 0
		from	order_detail
			join master_prod_sched mps on mps.origin = order_detail.order_no and
    	     			mps.source = order_detail.row_id
		where	order_detail.flag > 0
	end
	else 
	begin		
		execute msp_explode_demand_order @order_no, @row_id
		update	order_detail 
		set 	flag = 0
		where 	order_no= @order_no and 
			row_id 	= @row_id
	end
GO
