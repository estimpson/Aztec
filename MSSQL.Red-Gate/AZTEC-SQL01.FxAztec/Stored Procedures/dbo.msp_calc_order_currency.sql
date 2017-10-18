SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_order_currency] (	@order_no numeric(8,0),
						@customer varchar(10),
						@destination varchar(10),
						@sequence numeric(5,0),
						@currency varchar(3) )
as
begin

	-- declare local variables
	declare	@base_currency	varchar(3)

	-- get the base currency from parameters table
	select	@base_currency = base_currency
	from	parameters

	-- if order_no was sent update only that order
	if isnull(@order_no,0) > 0
	begin

		if isnull(@sequence,0) > 0
		begin
			update 	order_detail set
				price = ( order_detail.alternate_price * isnull(( 	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	order_header
			where	order_detail.order_no = @order_no and
				order_detail.sequence = @sequence and
				order_header.order_no = order_detail.order_no and
				order_header.order_type = 'N'

			update 	order_detail set
				order_detail.alternate_price = order_header.alternate_price,
				price = ( order_header.alternate_price * isnull(( 	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	order_header
			where	order_detail.order_no = @order_no and
				order_detail.sequence = @sequence and
				order_header.order_no = order_detail.order_no and
				order_header.order_type = 'B'
		end
		else
		begin

			update 	order_header set
				price = ( alternate_price * isnull(( 	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			where	order_no = @order_no and
				order_type = 'B'

			update 	order_detail set
				price = ( order_detail.alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1))
			from	order_header
			where	order_detail.order_no = @order_no and
				order_header.order_no = order_detail.order_no and
				order_header.order_type = 'N'

		end

	end	
	-- if customer is sent, update all orders for that customer
	else if isnull(@customer,'') > ''
	begin
			update 	order_header set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			where	customer = @customer and
				order_type = 'B'

			update 	order_detail set
				price = ( order_detail.alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	order_header
			where	order_header.customer = @customer and
				order_header.order_type = 'N' and
				order_header.order_no = order_detail.order_no
	end
	-- if destination is sent, update all orders for that destination
	else if isnull(@destination,'') > ''
	begin
			update 	order_header set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			where	destination = @destination and
				order_type = 'B'

			update 	order_detail set
				price = ( order_detail.alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	order_header
			where	order_header.destination = @destination and
				order_header.order_type = 'N' and
				order_header.order_no = order_detail.order_no
	end
	-- if currency is sent, update all orders with that currency
	else if isnull(@currency,'') > ''
	begin
			update 	order_header set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			where	currency_unit = @currency and
				order_type = 'B'

			update 	order_detail set
				price = ( order_detail.alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	order_header
			where	order_header.currency_unit = @currency and
				order_header.order_type = 'N' and
				order_header.order_no = order_detail.order_no
	end
	-- otherwise update all orders
	else
	begin
			update 	order_header set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			where	order_type = 'B'

			update 	order_detail set
				price = ( order_detail.alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
									from	currency_conversion cc
									where	effective_date <= GetDate ( ) and
										currency_code = order_header.currency_unit ) and
						currency_code = order_header.currency_unit ),1) / isnull((
							select	rate
							from	currency_conversion 
							where 	effective_date = (	select	max (effective_date)
											from	currency_conversion cc
											where	effective_date <= GetDate ( ) and
												currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	order_header
			where	order_header.order_type = 'N' and
				order_header.order_no = order_detail.order_no
	end
end
GO
