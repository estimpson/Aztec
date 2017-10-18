SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cdivw_partlist] 
(	part,   
	name,   
	cross_ref,   
	class,   
	type,   
	commodity,   
	group_technology,   
	product_line,   
	drawing_number,
	user_defined_1,
	user_defined_2,
	pc_user_defined_1,   
	standard_unit,   
	primary_location,   
	label_format,   
	unit_weight,   
	standard_pack,
	PMUD1,
	PMUD2,
	PMUD3,
	company_name,
	logo)
as	
SELECT	part.part,   
	part.name,   
	part.cross_ref,   
	part.class,   
	part.type,   
	part.commodity,   
	part.group_technology,   
	part.product_line,   
	part.drawing_number,
	part.user_defined_1,
	part.user_defined_2,
	part_characteristics.user_defined_1,   
	part_inventory.standard_unit,   
	part_inventory.primary_location,   
	part_inventory.label_format,   
	part_inventory.unit_weight,   
	part_inventory.standard_pack,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 1 and
	module = 'PM') as PMUD1,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 2 and
	module = 'PM') as PMUD2,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 3 and
	module = 'PM') as PMUD3,
	pmt.company_name company_name,
	pmt.company_logo logo
FROM	part
	join part_inventory on part_inventory.part = part.part
	left outer join part_characteristics on part_characteristics.part = part.part
	cross join parameters pmt
GO
