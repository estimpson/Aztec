SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_vendor_matrix] ( 	@part varchar(25), 
														@vendor varchar(10), 
														@qty_break decimal(20,6), 
														@currency_unit varchar(3) )
as
begin
	-- declare local variables
	declare	@vendor_currency	varchar(3),
			@base_currency		varchar(3)

	-- get the base currency from parameters table
	select	@base_currency = base_currency
	from	parameters

	if isnull(@currency_unit,'') > ''
		update 	part_vendor_price_matrix set
				price = ( part_vendor_price_matrix.alternate_price * isnull(( 	
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
		from	part_vendor_price_matrix,
				vendor
		where	part_vendor_price_matrix.vendor = vendor.code and
				vendor.default_currency_unit = @currency_unit
	else
	begin
		-- get vendor's default currency
		select	@vendor_currency = default_currency_unit
		from	vendor
		where	code = @vendor
		
		if isnull(@part,'') > ''
			update 	part_vendor_price_matrix set
					price = ( part_vendor_price_matrix.alternate_price * isnull(( 	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @vendor_currency ) and
								currency_code = @vendor_currency ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	part_vendor_price_matrix
			where	part = @part and
					vendor = @vendor and
					break_qty = @qty_break 
		else
			update 	part_vendor_price_matrix set
					price = ( part_vendor_price_matrix.alternate_price * isnull(( 	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @vendor_currency ) and
								currency_code = @vendor_currency ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	part_vendor_price_matrix
			where	vendor = @vendor
	end	
end
GO
