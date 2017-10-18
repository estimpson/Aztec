SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [custom].[usp_report_ObjectInventory]
as
Select 
	o.serial,
	p.part,
	p.name,
	o.location,
	o.plant,
	o.status,
	o.quantity, 
	e.name,
	o.last_date
From	
	object o
join	
	part p on p.part = o.part
join	
	employee  e on o.operator = e.operator_code
order by 
	location
GO
