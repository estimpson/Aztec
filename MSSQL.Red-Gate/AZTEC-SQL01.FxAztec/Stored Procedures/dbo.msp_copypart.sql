SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_copypart] (
@oldpart varchar(25), 
@newpart varchar(25), 
@returnvalue integer OUTPUT)
as
---------------------------------------------------------------------------------------------
--	Procedure	msp_copypart

--	Purpose		to copy an existing part to a new part

--	Arguments	Old part and new part

--	Returns		0 -	Success
--			-1 -	Invalid arguments
--			-2 - 	Duplicate part

--	Process		Check arguments for validity
--			Check whether the new part already exists
--			Insert row into part table
--				Part table insert trigger inserts row into part_standard
--			Insert row into part_inventory table
--			Insert row into part_online table
--			Insert row into part_purchasing table
--			Insert row(s) into part_packaging table

--	Development	Developer	Date	Details
--			GPH		4/14/01	Created the procedure
---------------------------------------------------------------------------------------------
--	Check the arguments, if null return unsuccessful state
if isnull(@oldpart,'') = '' or isnull(@newpart,'')=''
	select	-1	-- return invalid
else if (select isnull(count(1),0) from part where part = @newpart) > 0 
--	Check whether the part already exists, if so return unsuccessful
	select	-2	-- return duplicate
else
begin
--	Insert a row in part table
	insert	into part (
		part,
		name,
		cross_ref,
		class,
		type,
		commodity,
		group_technology,
		quality_alert,
		description_short,
		description_long,
		serial_type,
		product_line,
		configuration,
		standard_cost,
		user_defined_1,
		user_defined_2,
		flag,
		engineering_level,
		drawing_number,
		gl_account_code,
		eng_effective_date,
		low_level_code )
	select	@newpart,
		name,
		cross_ref,
		class,
		type,
		commodity,
		group_technology,
		quality_alert,
		description_short,
		description_long,
		serial_type,
		product_line,
		configuration,
		standard_cost,
		user_defined_1,
		user_defined_2,
		flag,
		engineering_level,
		drawing_number,
		gl_account_code,
		eng_effective_date,
		low_level_code
	from	part
	where	part = @oldpart

--	Part_standard gets inserted through the insert trigger on part table

--	Insert into part_inventory
	insert	into part_inventory (
		part,
		standard_pack,
		unit_weight,
		standard_unit,
		cycle,
		abc,
		saftey_stock_qty,
		primary_location,
		location_group,
		ipa,
		label_format,
		shelf_life_days,
		material_issue_type,
		safety_part,
		upc_code,
		dim_code,
		configurable,
		next_suffix,
		drop_ship_part)
	select	@newpart,
		standard_pack,
		unit_weight,
		standard_unit,
		cycle,
		abc,
		saftey_stock_qty,
		primary_location,
		location_group,
		ipa,
		label_format,
		shelf_life_days,
		material_issue_type,
		safety_part,
		upc_code,
		dim_code,
		configurable,
		next_suffix,
		drop_ship_part		
	from	part_inventory
	where	part = @oldpart

--	insert into part_online
	insert	into part_online (
		part,
		on_hand,
		on_demand,
		on_schedule,
		bom_net_out,
		min_onhand,
		max_onhand,
		default_vendor,
		default_po_number,
		kanban_po_requisition,
		kanban_required)
	select	@newpart,
		0,
		0,
		0,
		0,
		min_onhand,
		max_onhand,
		default_vendor,
		default_po_number,
		kanban_po_requisition,
		kanban_required			
	from	part_online
	where	part = @oldpart

--	insert into part_purchasing
	insert	into part_purchasing (
		part,
		buyer,
		min_order_qty,
		reorder_trigger_qty,
		min_on_hand_qty,
		primary_vendor,
		gl_account_code)
	select	@newpart,
		buyer,
		min_order_qty,
		reorder_trigger_qty,
		min_on_hand_qty,
		primary_vendor,
		gl_account_code
	from	part_purchasing
	where	part = @oldpart
		
--	insert into part_packaging
	insert	into part_packaging (
		part,
		code,
		quantity,
		manual_tare,
		label_format,
		round_to_whole_number,
		package_is_object,
		inactivity_time,
		threshold_upper,
		threshold_lower,
		unit,
		stage_using_weight,
		inactivity_amount,
		threshold_upper_type,
		threshold_lower_type,
		serial_type )
	select	@newpart,
		code,
		quantity,
		manual_tare,
		label_format,
		round_to_whole_number,
		package_is_object,
		inactivity_time,
		threshold_upper,
		threshold_lower,
		unit,
		stage_using_weight,
		inactivity_amount,
		threshold_upper_type,
		threshold_lower_type,
		serial_type
	from	part_packaging
	where	part = @oldpart

	select	0 -- return successful
end
GO
