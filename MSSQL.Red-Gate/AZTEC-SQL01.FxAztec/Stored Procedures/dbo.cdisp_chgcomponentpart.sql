SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_chgcomponentpart] (@oldpart varchar(25), @newpart varchar(25))
as
begin
--	part,bill_of_material_ec
--	part,activity_router
--	part,part_machine
--	part,part_machine_tool
--	part,part_machine_tool_list
	
	--	Declaration
	declare	@cnt smallint
	
	--	Verify the new part exists
	select	@cnt = count(1)
	from	part
	where	part = @newpart
	
	if isnull(@cnt,0) = 1
	begin
		begin transaction
		--	change part_machine_tool_list
		update	part_machine_tool_list
		set	part = @newpart
		where	part = @oldpart
		
		--	change part_machine_tool
		update	part_machine_tool
		set	part = @newpart,
			tool = @newpart
		where	part = @oldpart

		--	change part_machine
		update	part_machine
		set	part = @newpart
		where	part = @oldpart
		
		--	change activity_router 
		update	activity_router
		set	part = @newpart,
			parent_part = @newpart
		where	part = @oldpart and parent_part = @oldpart 
		
		--	change bill_of_material_ec
		update	bill_of_material_ec
		set	part = @newpart
		where	part = @oldpart and end_datetime is null

		update	bill_of_material_ec
		set	parent_part = @newpart
		where	parent_part = @oldpart and end_datetime is null
		
		commit transaction
	end 	
end
GO
