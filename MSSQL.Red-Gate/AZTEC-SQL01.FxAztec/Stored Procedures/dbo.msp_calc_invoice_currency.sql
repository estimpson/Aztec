SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_invoice_currency] (	@shipper integer, 
						@customer varchar(10), 
						@destination varchar(10), 
						@part varchar(25), 
						@currency varchar(3) )
as
begin

	-- declare local variables
	declare	@base_currency	varchar(3)

	-- get the base currency from parameters table
	select	@base_currency = base_currency
	from	parameters

	-- if invoice_no was sent update only that invoice
	if isnull(@shipper,0) > 0
	begin

		if 	isnull(@part,'') > ''

			update 	shipper_detail set
					price = ( alternate_price * isnull((	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = shipper.currency_unit ) and
								currency_code = shipper.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	shipper
			where	shipper.id = @shipper and
				shipper_detail.part = @part and
				shipper_detail.shipper = @shipper
		else

			update 	shipper_detail set
					price = ( alternate_price * isnull((	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
										from	currency_conversion cc
										where	effective_date <= GetDate ( ) and
											currency_code = shipper.currency_unit ) and
							currency_code = shipper.currency_unit ),1) / isnull((
										select	rate
										from	currency_conversion 
										where 	effective_date = (	select	max (effective_date)
										from	currency_conversion cc
										where	effective_date <= GetDate ( ) and
											currency_code = @base_currency ) and
							currency_code = @base_currency ),1) )
			from	shipper
			where	shipper.id = @shipper and
				shipper_detail.shipper = @shipper

	end	
	-- if customer is sent, update all invoices for that customer that haven't been printed 
	else if isnull(@customer,'') > ''
		update 	shipper_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = shipper.currency_unit ) and
							currency_code = shipper.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	shipper
		where	shipper.customer = @customer and
				shipper_detail.shipper = shipper.id

	-- if destination is sent, update all invoices for that destination that haven't been printed
	else if isnull(@destination,'') > ''
		update 	shipper_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = shipper.currency_unit ) and
							currency_code = shipper.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	shipper
		where	shipper.destination = @destination and
				shipper_detail.shipper = shipper.id

	-- if currency is sent, update all invoices with that currency
	else if isnull(@currency,'') > ''
		update 	shipper_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = shipper.currency_unit ) and
							currency_code = shipper.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	shipper
		where	shipper.currency_unit = @currency and
				shipper_detail.shipper = shipper.id

	-- otherwise update all invoices 
	else
		update 	shipper_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = shipper.currency_unit ) and
							currency_code = shipper.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	shipper
		where	shipper_detail.shipper = shipper.id

end
GO
