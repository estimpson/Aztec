SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_customers_vw]
as 
select	c.customer,
	c.create_date,
	ca.closure_rate*100 as closure_rate,
	ca.ontime_rate*100 as ontime_rate,
	ca.return_rate*100 as return_rate,
	c.cs_status,
	c.name,
	c.address_1,
	c.address_2,
	c.address_3,
	c.address_4,
	c.address_5,
	c.address_6,
	c.phone,
	c.fax,
	c.modem,
	c.contact,
	c.salesrep,
	c.terms,
	c.notes,
	c.default_currency_unit,
	c.show_euro_amount,
	c.custom1,
	c.custom2,
	c.custom3,
	c.custom4,
	c.custom5,
	c.origin_code,
	c.sales_manager_code,
	c.region_code
from	customer as c,
	customer_additional as ca,
	customer_service_status as css
where	c.customer=ca.customer and
	css.status_name = c.cs_status and
	css.status_type <> 'C'
GO
