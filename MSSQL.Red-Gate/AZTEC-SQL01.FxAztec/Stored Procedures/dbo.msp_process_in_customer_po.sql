SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.msp_process_in_customer_po    Script Date: 4/25/2001 11:11:16 AM ******/

/****** Object:  Stored Procedure dbo.msp_process_in_customer_po    Script Date: 3/15/2000 3:48:57 PM ******/
create procedure [dbo].[msp_process_in_customer_po]
as
---------------------------------------------------------------------------------------
--	This procedure creates normal orders from inbound customer po data.
--
--	Modifications:	30 APR 1999, Eric E. Stimpson	Original
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--							Changed decimal to numeric.
--			29 JUN 1999, Eric E. Stimpson	Removed step #40 which was "Reinitialize order no."
--							Added committed quantity to insert.
--			01 JUL 1999, Eric E. Stimpson	Changed datatype on @rowid to integer.
--
--	Returns:	  0	success
--			100	customer po not found
--
--	Process:
--	1. Declare all the required local variables.
--	2. Inititialize all variables.
--	3. Purge log table.
--	4. Log purged, indicate in log.
--	5. Get the totcount from the m_in_customer_po table
--	6. If there is data to process, proceed...
--	7. Data found, start processing, indicate in log.
--	8. Get the fiscal year begin date.
--	9. Declare the cusror for processing inbound customer po data.
--	10. Open the cursor.
--	11. Fetch a row of data from the cursor.
--	12. Continue processing as long as more inbound customer po data exists.
--	13. If this is a new customer po, calculate committed quantity (unless this is the first) for last order and create new normal order.
--	14. If this isn't the first order to be processed, then calculate the committed quantity of the last order.
--	15. Calculate committed quantity.
--	16. Indicate calculation success in log.
--	17. Calculation was successful, indicate in log.
--	18. Calculation was unsuccessful, indicate in log
--	19. Reset current customer and order number.
--	20. Create order header for new customer po.
--	21. Indicate creation success in log.
--	22. Creation was successful, indicate in log.
--	23. Creation was unsuccessful, indicate in log and set order no to null.
--	24. Assign the previous customer po with the current customer po, previous ship to with the current ship to, and previous order number with the current order number.
--	25. Find the appropriate internal part number for the customer part and customer.
--	26. So long as order no is valid and internal part number was successfully found, create release.
--	27. Get standard unit for part if none was specified.
--	28. Calculate standard quantity for release quantity.
--	29. Indicate unsuccessful calculation in log.
--	30. Calculation was unsuccessful, indicate in log.
--	31. Release is valid, get the next sequence and rowid for the new release.
--	32. Calculate the week number (from fiscalyearbegin).
--	33. Create release.
--	34. Release was created, indicate in log.
--	35. Determine if exception was order header creation.
--	36. Determine if exception was multiple parts found.
--	37. Multiple internal part numbers found, indicate in log.
--	38. No internal part number found, indicate in log.
--	39. Record exception data in customer po exceptions.
--	40. Fetch a row of data from the cursor.
--	41. If previous order was valid, calculate committed quantity for the last order.
--	42. Calculate committed quantity.
--	43. Indicate calculation successful in log.
--	44. Calculation was successful, indicate in log.
--	45. Calculation was unsuccessful, indicate in log
--	46. Close the cursor.
--	47. Done processing, indicate in log.
--	48. Remove processed inbound data.
-------------------------------------------------------------------------------------

--	1. Declare all the required local variables.
declare	@returncode		integer,
	@totcount		integer,
	@fiscalyearbegin	datetime,
	@orderno		numeric (8),
	@prevorderno		numeric (8),
	@customerpart		varchar (35),
	@shipto			varchar (20),
	@customer		varchar (10),
	@customerpo		varchar (30),
	@releaseno		varchar (30),
	@quantity		decimal (20,6),
	@releasedt		datetime,
	@releasedtqualifier	char (1),
	@releasetypequalifier	char (1),
	@part			varchar (25),
	@plant			varchar (10),
	@prevcustomerpo		varchar (30),
	@prevshipto		varchar (20),
	@orderunit		char (2),
	@standardquantity	numeric (20,6),
	@sequence		tinyint,
	@rowid			integer,
	@weekno			integer

--	2. Inititialize all variables.
select	@totcount = 0,
	@fiscalyearbegin = null,
	@orderno = null,
	@prevorderno = 0,
	@customerpart = null,
	@shipto = null,
	@customerpo = null,
	@releaseno = null,
	@quantity = 0,
	@releasedt = null,
	@part = null,
	@plant = null,
	@prevcustomerpo = '',
	@prevshipto = '',
	@standardquantity = 0,
	@sequence = 0,
	@rowid = 0,
	@weekno = 0

--	3. Purge log table.
delete	log
 where	spid = @@spid

--	4. Log purged, indicate in log.
insert	log (
		spid,
		id,
		message )
select	@@spid,
	(	select	isnull ( max ( id ), 0 ) + 1
		  from	log
		 where	spid = @@spid ),
	'Log purged successfully.'

--	5. Get the totcount from the m_in_customer_po table
select	@totcount = count ( 1 )
  from	m_in_customer_po

--	6. If there is data to process, proceed...
if	( @totcount > 0 )
begin -- (1aB)

--	7. Data found, start processing, indicate in log.
	insert	log (
			spid,
			id,
			message )
	select	@@spid,
		(	select	isnull ( max ( id ), 0 ) + 1
			  from	log
			 where	spid = @@spid ),
		'Start processing ' + convert ( varchar ( 20 ), getdate ( ) ) + '.'

--	8. Get the fiscal year begin date.
	select	@fiscalyearbegin = fiscal_year_begin
	  from	parameters

--	9. Declare the cusror for processing inbound customer po data.
	declare	ibcursor cursor for
	select	plant,
		shipto_id,
		customer_po,
		customer_part,
		release_no,
		order_unit,
		quantity,
		release_dt_qualifier,
		release_dt,
		release_type_qualifier
	  from	m_in_customer_po
	order by	1, 2, 3, 4, 9

--	10. Open the cursor.
	  open	ibcursor

--	11. Fetch a row of data from the cursor.
	 fetch	ibcursor
	  into	@plant,
		@shipto,
		@customerpo,
  		@customerpart,
		@releaseno,
		@orderunit,
		@quantity,
		@releasedtqualifier,
		@releasedt,
		@releasetypequalifier

--	12. Continue processing as long as more inbound customer po data exists.
	while	( @@rowcount > 0 )
	begin -- (2aB)

--	13. If this is a new customer po, calculate committed quantity (unless this is the first) for last order and create new normal order.
		if ( @shipto <> @prevshipto ) or ( @customerpo <> @prevcustomerpo )
		begin -- (3aB)

--	14. If this isn't the first order to be processed, then calculate the committed quantity of the last order.
			if @prevorderno > 0
			begin -- (4aB)

--	15. Calculate committed quantity.
				exec	@returncode = msp_calculate_committed_qty
						@prevorderno

--	16. Indicate calculation success in log.
				if @returncode = 0

--	17. Calculation was successful, indicate in log.
					insert	log (
							spid,
							id,
							message )
					select	@@spid,
						(	select	isnull ( max ( id ), 0 ) + 1
							  from	log
							 where	spid = @@spid ),
						'Calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.'
				else

--	18. Calculation was unsuccessful, indicate in log
					insert	log (
							spid,
							id,
							message )
					select	@@spid,
						(	select	isnull ( max ( id ), 0 ) + 1
							  from	log
							 where	spid = @@spid ),
						'Failed to calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.  Order requirements not found.'
			end -- (4aB)

--	19. Reset current customer and order number.
			select	@orderno = null,
				@customer = null

--	20. Create order header for new customer po.
			exec	@returncode = msp_create_customer_po
					@shipto,
					@customerpo,
					@orderno,
					@customer

--	21. Indicate creation success in log.
			if @returncode = 0

--	22. Creation was successful, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Created order number:  ' + convert ( char ( 8 ), @orderno ) + ' for ship to:  ' + @shipto + ' and customer po:  ' + @customerpo + '.'
			else

--	23. Creation was unsuccessful, indicate in log and set order no to null.
			begin -- ( 4bB )

				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					(	case when @returncode = 100
							then 'Failed to create order for ship to:  ' + @shipto + ' and customer po:  ' + @customerpo + '.  Ship to not found or not billable.'
							else 'Manually create order for ship to:  ' + @shipto + ' and customer po:  ' + @customerpo + '.'
					end )
		                select	@orderno = null

			end -- ( 4bB )

--	24. Assign the previous customer po with the current customer po, previous ship to with the current ship to, and previous order number with the current order number.
			select	@prevcustomerpo = @customerpo,
				@prevshipto=@shipto,
				@prevorderno = @orderno

		end -- (3aB)

--	25. Find the appropriate internal part number for the customer part and customer.
		exec	@returncode = msp_find_internal_part
				@customerpart,
				@customer,
				@part

--	26. So long as order no is valid and internal part number was successfully found, create release.
		if @orderno is not null and @part > ''
		begin -- (3bB)

--	27. Get standard unit for part if none was specified.
			select	@orderunit = isnull ( @orderunit, standard_unit )
			  from	part_inventory
			 where	part = @part

--	28. Calculate standard quantity for release quantity.
			select	@standardquantity = @quantity

			exec	@returncode = msp_calculate_std_quantity
					@part,
					@standardquantity,
					@orderunit

--	29. Indicate unsuccessful calculation in log.
			if @returncode = -1

--	30. Calculation was unsuccessful, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Failed to calculated standard quantity for part:  ' + @part + ' and unit:  ' + @orderunit + '.  Invalid unit for part.'

--	31. Release is valid, get the next sequence and rowid for the new release.
			select	@sequence = isnull ( (
					select	max ( sequence )
					  from	order_detail od
					 where	od.order_no = @orderno ), 0 ) + 1,
				@rowid = isnull ( (
					select	max ( row_id )
					  from	order_detail od
					 where	od.order_no = @orderno ), 0 ) + 1

--	32. Calculate the week number (from fiscalyearbegin).
			select	@weekno = datediff ( dd, @fiscalyearbegin, @releasedt ) / 7 + 1

--	33. Create release.
			insert	order_detail (
					order_no,
					sequence,
					part_number,
					product_name,
					type,
					quantity,
					price,
					alternate_price,
					notes,
					status,
					unit,
					due_date,
					release_no,
					destination,
					customer_part,
					row_id,
					flag,
					ship_type,
					packline_qty,
					plant,
					week_no,
					std_qty,
					weight,
					packaging_type,
					our_cum,
					the_cum,
					committed_qty )
			select	@orderno,
				@sequence,
				@part,
				max ( part.name ),
				'F',
				@quantity,
				min ( pcpm.price ),
				min ( pcpm.alternate_price ),
				'850-Release created thru stored procedure',
				'O',
				@orderunit,
				@releasedt,
				@releaseno,
				@shipto,
				@customerpart,
				@rowid,
				1,
				'N',
				0,
				@plant,
				@weekno,
				@standardquantity,
				@standardquantity * max ( unit_weight ),
				min ( pp.code ),
				0,
				null,
				0
			  from	part
				join part_inventory pi on pi.part = @part
				join part_customer pc on pc.part = @part and
					pc.customer = @customer
				left outer join part_packaging pp on pp.part = @part and
					pp.quantity = pc.customer_standard_pack
				left outer join part_customer_price_matrix pcpm on pcpm.part = @part and
					pcpm.customer = @customer and
					qty_break <= @standardquantity
			 where	part.part = @part
			group by part.part

--	34. Release was created, indicate in log.
			insert	log (
					spid,
					id,
					message )
			select	@@spid,
				(	select	isnull ( max ( id ), 0 ) + 1
					  from	log
					 where	spid = @@spid ),
				'Create release for customer part:  ' + @customerpart + ', destination:  ' + @shipto + ', release date:  ' + convert ( varchar(16), @releasedt ) + ', quantity:  ' + convert ( varchar(20), @quantity ) + '.'

		end -- (3bB)
		else
		begin -- (3cB)

--	35. Determine if exception was order header creation.
			if @orderno is null
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Create releases manually.'
			else

--	36. Determine if exception was multiple parts found.
				if @returncode = -1

--	37. Multiple internal part numbers found, indicate in log.
					insert	log (
							spid,
							id,
							message )
					select	@@spid,
						(	select	isnull ( max ( id ), 0 ) + 1
							  from	log
							 where	spid = @@spid ),
						'Internal part is not unique for the customer part:  ' + @customerpart + ' and customer:  ' + @customer + '.  Fix data and then re-process.'
				else
					if @returncode = 100

--	38. No internal part number found, indicate in log.
						insert	log (
								spid,
								id,
								message )
						select	@@spid,
							(	select	isnull ( max ( id ), 0 ) + 1
								  from	log
								 where	spid = @@spid ),
							'No relationship for customer part:  ' + @customerpart + ' and customer:  ' + @customer + ' exists.  Fix data and then re-process.'

--	39. Record exception data in customer po exceptions.
			insert	m_in_customer_po_exceptions (
					logid,
					plant,
					shipto_id,
					customer_po,
					customer_part,
					release_no,
					order_unit,
					quantity,
					release_dt_qualifier,
					release_dt,
					release_type_qualifier )
			select	(	select	isnull ( max ( id ), 0 )
					  from	log
					 where	spid = @@spid ),
				@plant,
				@shipto,
				@customerpo,
		  		@customerpart,
				@releaseno,
				@orderunit,
				@quantity,
				@releasedtqualifier,
				@releasedt,
				@releasetypequalifier
		end -- (3cB)

--	40. Fetch a row of data from the cursor.
		 fetch	ibcursor
		  into	@plant,
			@shipto,
			@customerpo,
	  		@customerpart,
			@releaseno,
			@orderunit,
			@quantity,
			@releasedtqualifier,
			@releasedt,
			@releasetypequalifier

	end -- (2aB)

--	41. If previous order was valid, calculate committed quantity for the last order.
	if @prevorderno > 0
	begin -- (2bB)

--	42. Calculate committed quantity.
	exec	@returncode = msp_calculate_committed_qty
			@prevorderno

--	43. Indicate calculation successful in log.
		if @returncode = 0

--	44. Calculation was successful, indicate in log.
			insert	log (
					spid,
					id,
					message )
			select	@@spid,
				(	select	isnull ( max ( id ), 0 ) + 1
					  from	log
					 where	spid = @@spid ),
				'Calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.'
		else

--	45. Calculation was unsuccessful, indicate in log
			insert	log (
					spid,
					id,
					message )
			select	@@spid,
				(	select	isnull ( max ( id ), 0 ) + 1
					  from	log
					 where	spid = @@spid ),
				'Failed to calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.  Order requirements not found.'
	end -- (2bB)

--	46. Close the cursor.
	close	ibcursor

end -- (1aB)
else

begin -- (1bB)
	insert	log (
			spid,
			id,
			message )
	select	@@spid,
		(	select	isnull ( max ( id ), 0 ) + 1
			  from	log
			 where	spid = @@spid ),
		'Inbound customer po does not exist.  Check configuration and reprocess.'
	return 100
end -- (1bB)

--	47. Done processing, indicate in log.
insert	log (
		spid,
		id,
		message )
select	@@spid,
	(	select	isnull ( max ( id ), 0 ) + 1
		  from	log
		 where	spid = @@spid ),
	'Processing complete.' + convert ( varchar(20), getdate ( ) )

--	48. Remove processed inbound data.
delete	m_in_customer_po
return 0
GO
