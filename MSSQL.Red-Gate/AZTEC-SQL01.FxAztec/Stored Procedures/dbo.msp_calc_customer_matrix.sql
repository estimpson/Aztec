SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_customer_matrix] ( 	@part varchar(25), 
														@customer varchar(10), 
														@qty_break decimal(20,6), 
														@currency_unit varchar(3) )
as
begin
	-- declare local variables
	declare	@customer_currency	varchar(3),
			@base_currency		varchar(3)

	-- get the base currency from parameters table
	select	@base_currency = base_currency
	from	parameters

	if isnull(@currency_unit,'') > ''
		update 	part_customer_price_matrix set
				price = ( part_customer_price_matrix.alternate_price * isnull(( 	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = @currency_unit ) and
							currency_code = @currency_unit ),1) / isnull((
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = @base_currency ) and
							currency_code = @base_currency ),1))
		from	part_customer_price_matrix,
				customer
		where	part_customer_price_matrix.customer = customer.customer and
				customer.default_currency_unit = @currency_unit

	else
	begin
		-- get customer's default currency
		select	@customer_currency = default_currency_unit
		from	customer
		where	customer = @customer
		
		if isnull(@part,'') > ''
			update 	part_customer_price_matrix set
					price = ( part_customer_price_matrix.alternate_price * isnull(( 	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @customer_currency ) and
								currency_code = @customer_currency ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	part_customer_price_matrix
			where	part = @part and
					customer = @customer and
					qty_break = @qty_break 
		else
			update 	part_customer_price_matrix set
					price = ( part_customer_price_matrix.alternate_price * isnull(( 	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @customer_currency ) and
								currency_code = @customer_currency ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	part_customer_price_matrix
			where	customer = @customer
	end	
end
GO
