SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_po_currency] (	@po_no integer, 
												@vendor varchar(10), 
												@destination varchar(10), 
												@row_id integer, 
												@part varchar(25), 
												@date_due datetime, 
												@currency varchar(3) )
as
begin

	-- declare local variables
	declare	@base_currency	varchar(3)

	-- get the base currency from parameters table
	select	@base_currency = base_currency
	from	parameters

	-- if po_no was sent update only that purchase order
	if isnull(@po_no,0) > 0
	begin

		if 	isnull(@row_id,0) > 0 and
			isnull(@part,'') > '' and
			isnull(@date_due,convert(datetime,'1990/01/01')) > convert(datetime,'1990/01/01')

			update 	po_detail set
					price = ( alternate_price * isnull((	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = po_header.currency_unit ) and
								currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	po_header
			where	po_detail.po_number = @po_no and
					po_detail.row_id = @row_id and
					po_detail.date_due = @date_due and
					po_detail.part_number = @part and
					po_header.po_number = po_detail.po_number
		else

			update 	po_detail set
					price = ( alternate_price * isnull((	
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = po_header.currency_unit ) and
								currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
			from	po_header
			where	po_detail.po_number = @po_no and
					po_header.po_number = po_detail.po_number


	end	
	-- if vendor is sent, update all purchase orders for that vendor 
	else if isnull(@vendor,'') > ''
		update 	po_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = po_header.currency_unit ) and
							currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	po_header
		where	po_header.vendor_code = @vendor and
				po_header.po_number = po_detail.po_number

	-- if destination is sent, update all purchase orders for that destination 
	else if isnull(@destination,'') > ''
		update 	po_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = po_header.currency_unit ) and
							currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	po_header
		where	po_header.ship_to_destination = @destination and
				po_header.po_number = po_detail.po_number

	-- if currency is sent, update all purchase orders with that currency
	else if isnull(@currency,'') > ''
		update 	po_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = po_header.currency_unit ) and
							currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	po_header
		where	po_header.currency_unit = @currency and
				po_header.po_number = po_detail.po_number

	-- otherwise update all orders
	else
		update 	po_detail set
				price = ( alternate_price * isnull((	
					select	rate
					from	currency_conversion 
					where 	effective_date = (	select	max (effective_date)
												from	currency_conversion cc
												where	effective_date <= GetDate ( ) and
														currency_code = po_header.currency_unit ) and
							currency_code = po_header.currency_unit ),1) / isnull((
						select	rate
						from	currency_conversion 
						where 	effective_date = (	select	max (effective_date)
													from	currency_conversion cc
													where	effective_date <= GetDate ( ) and
															currency_code = @base_currency ) and
								currency_code = @base_currency ),1) )
		from	po_header
		where	po_header.po_number = po_detail.po_number

end
GO
