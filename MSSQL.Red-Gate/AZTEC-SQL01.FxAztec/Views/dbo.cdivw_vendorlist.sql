SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cdivw_vendorlist]
(	code,   
	name,   
	contact,   
	phone,   
	terms,   
	ytd_sales,   
	balance,   
	frieght_type,   
	fob,   
	buyer,   
	plant,   
	ship_via,   
	address_1,   
	address_2,   
	address_3,   
	fax,   
	outside_processor,   
	address_4,   
	address_5,   
	address_6,
	kanban,
	status,
	custom1,
	custom2,
	custom3,
	custom4,
	custom5,
	VNDUD1,
	VNDUD2,
	VNDUD3,
	VNDUD4,
	VNDUD5,
	company_name, 
	logo 
) as
SELECT	vendor.code,   
	vendor.name,   
	vendor.contact,   
	vendor.phone,   
	vendor.terms,   
	vendor.ytd_sales,   
	vendor.balance,   
	vendor.frieght_type,   
	vendor.fob,   
	vendor.buyer,   
	vendor.plant,   
	vendor.ship_via,   
	vendor.address_1,   
	vendor.address_2,   
	vendor.address_3,   
	vendor.fax,   
	vendor.outside_processor,   
	vendor.address_4,   
	vendor.address_5,   
	vendor.address_6,
	vendor.kanban,
	vendor.status,
	vendor_custom.custom1,
	vendor_custom.custom2,
	vendor_custom.custom3,
	vendor_custom.custom4,
	vendor_custom.custom5,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 1 and
	module = 'VM') as VNDUD1,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 2 and
	module = 'VM') as VNDUD2,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 3 and
	module = 'VM') as VNDUD3,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 4 and
	module = 'VM') as VNDUD4,
	( Select	label
	from	user_definable_module_labels
	where	sequence = 5 and
	module = 'VM') as VNDUD5,
	pmt.company_name company_name, 
	pmt.company_logo logo
FROM	vendor
	left outer join vendor_custom on vendor_custom.code = vendor.code
	cross join parameters pmt
GO
