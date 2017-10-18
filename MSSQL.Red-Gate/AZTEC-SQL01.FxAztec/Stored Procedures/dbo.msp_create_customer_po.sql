SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_create_customer_po] (
	@shipto varchar(20),
	@customerpo varchar(30),
	@orderno decimal(8) output,
	@customer varchar(10) output )
as
-------------------------------------------------------------------------------------
--	This procedure creates a normal order header from customer po and shipto id
--	data.
--
--	Modifications:	02 JAN 1999, Eric E. Stimpson	Original
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--
--	Paramters:	@shipto		mandatory
--			@customerpo	mandatory
--			@orderno	output
--			@customer	output
--
--	Returns:	  0	success
--			 -2	ship to not World Group, do not process.
--			100	ship to not found or not billable.
--
--	Process:
--	1. Declarations.
--	2. Inititialize all variables from customer and destination tables.
--	3. Check if customer found and return ship to not found or not billable if not.
--	4. Get the next available order number from parameters.
--	5. Create order header and return success.
-------------------------------------------------------------------------------------

--	1. Declarations.
declare	@orderdate	datetime,
	@ordertype	char(1),
	@salesrep	varchar(10),
	@terms		varchar(20),
	@currency	varchar(3),
	@csstatus	varchar(20)

--	2. Inititialize all variables from customer and destination tables.
select	@customer = destination.customer,
	@orderdate = GetDate(),
	@ordertype = 'N',
	@salesrep = salesrep,
	@terms = terms,
	@currency = destination.default_currency_unit,
	@csstatus = destination.cs_status
  from	destination
  	join customer on destination.customer = customer.customer
 where	destination = @shipto

--	3. Check if customer found and return ship to not found or not billable if not.
if IsNull ( @customer, '' ) = ''
	Return 100

--	4. Get the next available order number from parameters.
select	@orderno = sales_order
  from	parameters

while (	select	order_no
	  from	order_header
	  	cross join parameters
	 where	order_no=sales_order ) > 0
begin -- (1bB)
	update	parameters
	   set	sales_order = sales_order + 1

	select	@orderno = sales_order
	  from	parameters
end -- (1bB)

update	parameters
   set	sales_order = sales_order + 1

--	6. Create order header and return success.
insert	order_header (
		order_no,
		customer,
		order_date,
		destination,
		order_type,
		customer_po,
		salesman,
		term,
		currency_unit,
		cs_status )
select	@orderno,
	@customer,
	@orderdate,
	@shipto,
	@ordertype,
	@customerpo,
	@salesrep,
	@terms,
	@currency,
	@csstatus

return 0
GO
