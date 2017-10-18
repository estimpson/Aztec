SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.msp_process_in_release_plan    Script Date: 4/25/2001 11:11:16 AM ******/

/****** Object:  Stored Procedure dbo.msp_process_in_release_plan    Script Date: 3/15/2000 3:48:57 PM ******/
create procedure [dbo].[msp_process_in_release_plan]
as
-------------------------------------------------------------------------------------
--	This procedure creates releases from inbound release plan data.
--
--	Modifications:	29 APR 1999, Eric E. Stimpson	Original
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--							Changed decimal to numeric.
--							Added exception storage.
--			19 AUG 1999, Eric E. Stimpson	Changed tinyint to integer to avoid overflow.
--
--	Returns:	  0	success
--			100	release plan not found
--
--	Process:
--	1. Declare all the required local variables.
--	2. Inititialize all variables.
--	3. Purge log table.
--	4. Log purged, indicate in log.
--	5. Get the totcount from the m_in_release_plan table
--	6. If there is data to process, proceed...
--	7. Data found, start processing, indicate in log.
--	8. Get the fiscal year begin date.
--	9. Declare the cusror for processing inbound release plan data.
--	10. Open the cursor.
--	11. Fetch a row of data from the cursor.
--	12. Continue processing as long as more inbound release plan data exists.
--	13. Processing release, indicate in log.
--	14. Find blanket order.
--	15. If order find was successful.
--	16. Get blanket order info:  blanket part, plant, accumulative shipped.
--	17. If this is a new order, delete old release plan and forecast schedule.
--	18. Deleting release plan.
--	19. Release plan deleted, indicate in log.
--	20. If previous order was valid, calculate committed quantity for the previous order.
--	21. Indicate calculation successful in log.
--	22. Calculation was successful, indicate in log.
--	23. Calculation was unsuccessful, indicate in log
--	24. Assign the prev order no with the current order no, and cumordered with the cumshipped
--	25. Calculate the appropriate releasequantity, cumordered, and newcumordered based on quantityqualifier...
--	26. The quantity value is an accumulative requirement.
--	27. calculate the releasequantity and set the newcumordered.
--	28. The quantity value is a net requirement.
--	29. Calculate the newcumordered and set the releasequantity.
--	30. Calculate standard quantity for release quantity.
--	31. Indicated unsuccessful calculation in log.
--	32. Calculation was unsuccessful, indicate in log
--	33. Determine the validity of the release (releasequantity greater than zero)...
--	34. Release is valid, get the next sequence and rowid for the new release.
--	35. Calculate the week number (from fiscalyearbegin).
--	36. Create release.
--	37. Release was created, indicate in log.
--	38. Set the cumordered to the newcumordered.
--	39. Release was already shipped, indicate in log.
--	40. Determine if exception was multiple orders found.
--	41. Multiple orders found, indicate in log.
--	42. No orders found, indicate in log.
--	43. Record exception data in customer po exceptions.
--	44. Reinitialize order no.
--	45. Fetch a row of data from the cursor 
--	46. If previous order was valid, calculate committed quantity for the previous order.
--	47. Indicate calculation successful in log.
--	48. Calculation was successful, indicate in log.
--	49. Calculation was unsuccessful, indicate in log
--	50. Close the cursor.
--	51. No inbound release plan to process, indicate in log and return rows not found.
--	52. Done processing, indicate in log.
--	53. Remove processed inbound data.
-------------------------------------------------------------------------------------

--	1. Declare all the required local variables.
declare	@returncode		integer,
	@totcount		integer,
	@fiscalyearbegin	datetime,
	@orderno		numeric (8),
	@customerpart		varchar (35),
	@shipto			varchar (20),
	@customerpo		varchar (30),
	@modelyear		varchar (4),
	@releaseno		varchar (30),
	@quantityqualifier	char (1),
	@quantity		numeric (20,6),
	@releasedt		datetime,
	@releasedtqualifier	char (1),
	@blanketpart		varchar (25),
	@plant			varchar (10),
	@prevorderno		numeric (8),
	@cumshipped		numeric (20,6),
	@cumordered		numeric (20,6),
	@newcumordered		numeric (20,6),
	@releasequantity	numeric (20,6),
	@orderunit		char (2),
	@standardquantity	numeric (20,6),
	@sequence		tinyint,
	@rowid			tinyint,
	@weekno			integer

--	2. Inititialize all variables.
select	@totcount = 0,
	@fiscalyearbegin = null,
	@orderno = 0,
	@customerpart = null,
	@shipto = null,
	@customerpo = null,
	@modelyear = null,
	@releaseno = null,
	@quantityqualifier = null,
	@quantity = 0,
	@releasedt = null,
	@releasedtqualifier = null,
	@blanketpart = null,
	@plant = null,
	@prevorderno = 0,
	@cumshipped = 0,
	@cumordered = 0,
	@newcumordered = 0,
	@releasequantity = 0,
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

--	5. Get the totcount from the m_in_release_plan table
select	@totcount = count ( 1 )
  from	m_in_release_plan

--	6. If there is data to process, proceed...
if ( @totcount > 0 )
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

--	9. Declare the cusror for processing inbound release plan data.
	declare	ibcursor cursor for
	select	customer_part,
		shipto_id,
		customer_po,
		model_year,
		release_no,
		quantity_qualifier,
		quantity,
		release_dt,
		release_dt_qualifier
	  from	m_in_release_plan
	order by	1, 2, 3, 4, 8

--	10. Open the cursor.
	  open	ibcursor

--	11. Fetch a row of data from the cursor.
	 fetch	ibcursor
	  into	@customerpart,
		@shipto,
		@customerpo,
		@modelyear,
		@releaseno,
		@quantityqualifier,
		@quantity,
		@releasedt,
		@releasedtqualifier

--	12. Continue processing as long as more inbound release plan data exists.
	while ( @@rowcount > 0 )
	begin -- (2B)

--	13. Processing release, indicate in log.
		insert	log (
				spid,
				id,
				message )
		select	@@spid,
			(	select	isnull ( max ( id ), 0 ) + 1
				  from	log
				 where	spid = @@spid ),
			'Searching for blanket order for customer part :  (' + @customerpart + ', destination :' + @shipto + ', customer po :' + @customerpo + ' & model year :'+ @modelyear+'.  Processing release #  (' + @releaseno+') due ' + convert ( varchar(20), @releasedt, 113) + '.'

--	14. Find blanket order.
		exec	@returncode = msp_find_blanket_order
				@customerpart,
				@shipto,
				@customerpo,
				@modelyear,
				@orderno output

--	15. If order find was successful.
		if @returncode = 0
		begin -- (3aB)

--	16. Get blanket order info:  blanket part, plant, accumulative shipped.
			select	@blanketpart = blanket_part,
			        @plant = plant,
			        @cumshipped = isnull ( our_cum, 0 ),
				@orderunit = shipping_unit
			  from	order_header
			 where	order_no = @orderno

--	17. If this is a new order, delete old release plan and forecast schedule.
			if ( @orderno <> isnull ( @prevorderno, 0 ) )
			begin -- (4aB)

--	18. Deleting release plan.
				delete	order_detail
				 where	order_no = @orderno and
			 		type = 'P'

--	19. Release plan deleted, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Deleted old release plan from order detail.'

--	20. If previous order was valid, calculate committed quantity for the previous order.
				if @prevorderno > 0
				begin -- (5B)
					exec	@returncode = msp_calculate_committed_qty
								@prevorderno,
								null,
								null

--	21. Indicate calculation successful in log.
					if @returncode = 0

--	22. Calculation was successful, indicate in log.
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

--	23. Calculation was unsuccessful, indicate in log
						insert	log (
								spid,
								id,
								message )
						select	@@spid,
							(	select	isnull ( max ( id ), 0 ) + 1
								  from	log
								 where	spid = @@spid ),
							'Failed to calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.  Order not found.'
				end -- (5B)
					
--	24. Assign the prev order no with the current order no, and cumordered with the cumshipped
				select	@prevorderno = @orderno,
					@cumordered = @cumshipped
			end -- (4aB)

--	25. Calculate the appropriate releasequantity, cumordered, and newcumordered based on quantityqualifier...
			if ( @quantityqualifier = 'A' )

--	26. The quantity value is an accumulative requirement.
--	27. calculate the releasequantity and set the newcumordered.
				select	@releasequantity = @quantity - @cumordered,
					@newcumordered = @quantity
			else

--	28. The quantity value is a net requirement.
--	29. Calculate the newcumordered and set the releasequantity.
				select	@newcumordered = @quantity + @cumordered,
					@releasequantity = @quantity

--	30. Calculate standard quantity for release quantity.
				select	@standardquantity = @releasequantity
				exec	@returncode = msp_calculate_std_quantity
						@blanketpart,
						@releasequantity,
						@orderunit

--	31. Indicated unsuccessful calculation in log.
					if @returncode = -1

--	32. Calculation was unsuccessful, indicate in log
						insert	log (
								spid,
								id,
								message )
						select	@@spid,
							(	select	isnull ( max ( id ), 0 ) + 1
								  from	log
								 where	spid = @@spid ),
							'Failed to calculated standard quantity for part:  ' + @blanketpart + ' and unit:  ' + @orderunit + '.  Invalid unit for part.'

--	33. Determine the validity of the release (releasequantity greater than zero)...
			if @releasequantity > 0
			begin -- (4bB)

--	34. Release is valid, get the next sequence and rowid for the new release.
				select	@sequence = isnull ( (
						select	max ( sequence )
						  from	order_detail as od
						 where	od.order_no = @orderno and
					 		type = 'P' ), 100 ) + 1,
					@rowid = isnull ( (
						select	max ( row_id )
						  from	order_detail as od
						 where	od.order_no = @orderno and
					 		type = 'P' ), 100 ) + 1

--	35. Calculate the week number (from fiscalyearbegin).
				select	@weekno = datediff ( dd, @fiscalyearbegin, @releasedt ) / 7 + 1

--	36. Create release.
				insert	order_detail (
						order_no,
						sequence,
						part_number,
						type,
						quantity,
						status,
						notes,
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
						our_cum,
						the_cum )
				values (	@orderno,
						@sequence,
						@blanketpart,
						'P',
						@releasequantity,
						@releasedtqualifier,
						'830-Release created thru stored procedure',
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
						@cumordered,
						@newcumordered )

--	37. Release was created, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Inserted release for customer part :' + @customerpart+', destination :' + @shipto + ', release date :' + convert( varchar(16), @releasedt ) + ', quantity :' + convert( varchar(20), @releasequantity )

--	38. Set the cumordered to the newcumordered.
				select	@cumordered = @newcumordered
			end -- (4bB)
			else

--	39. Release was already shipped, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Release not saved because quantity ordered has already been shipped.'
		end -- (3aB)
		else
		begin -- (3bB)

--	40. Determine if exception was multiple orders found.
			if @returncode = -1

--	41. Multiple orders found, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Blanket order is not unique for the customer part: ' + @customerpart + ', destination: ' + @shipto + ', customer po: ' + @customerpo + ' & model year: ' + @modelyear + '. create one & then re-process.'

			else

--	42. No orders found, indicate in log.
				insert	log (
						spid,
						id,
						message )
				select	@@spid,
					(	select	isnull ( max ( id ), 0 ) + 1
						  from	log
						 where	spid = @@spid ),
					'Blanket order does not exist for the customer part: ' + @customerpart + ', destination: ' + @shipto + ', customer po: ' + @customerpo + ' & model year: ' + @modelyear + '. create one & then re-process.'

--	43. Record exception data in customer po exceptions.
			insert	m_in_release_plan_exceptions (
					logid,
					customer_part,
					shipto_id,
					customer_po,
					model_year,
					release_no,
					quantity_qualifier,
					quantity,
					release_dt_qualifier,
					release_dt )
			select	(	select	isnull ( max ( id ), 0 )
					  from	log
					 where	spid = @@spid ),
				@customerpart,
				@shipto,
				@customerpo,
				@modelyear,
				@releaseno,
				@quantityqualifier,
				@quantity,
				@releasedtqualifier,
				@releasedt
		end -- (3bB)

--	44. Reinitialize order no.
        select	@orderno = 0

--	45. Fetch a row of data from the cursor 
		 fetch	ibcursor
		  into	@customerpart,
			@shipto,
			@customerpo,
			@modelyear,
			@releaseno,
			@quantityqualifier,
			@quantity,
			@releasedt,
			@releasedtqualifier

	end -- (2B)

--	46. If previous order was valid, calculate committed quantity for the previous order.
	if @prevorderno > 0
	begin -- (2bB)
		exec	@returncode = msp_calculate_committed_qty
				@prevorderno,
				null,
				null

--	47. Indicate calculation successful in log.
	if @returncode = 0

--	48. Calculation was successful, indicate in log.
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

--	49. Calculation was unsuccessful, indicate in log
		insert	log (
				spid,
				id,
				message )
		select	@@spid,
			(	select	isnull ( max ( id ), 0 ) + 1
				  from	log
				 where	spid = @@spid ),
			'Failed to calculated committed quantity for order:  ' + convert ( char ( 8 ), @prevorderno ) + '.  Order not found.'
	end -- (2bB)

--	50. Close the cursor.
	close	ibcursor

end -- (1aB)
else

--	51. No inbound release plan to process, indicate in log and return rows not found.
begin -- (1bB)
	insert	log (
			spid,
			id,
			message )
	select	@@spid,
		(	select	isnull ( max ( id ), 0 ) + 1
			  from	log
			 where	spid = @@spid ),
		'Inbound release plan does not exist.  Check configuration and reprocess.'

	return	100
end -- (1bB)

--	52. Done processing, indicate in log.
insert	log (
		spid,
		id,
		message )
select	@@spid,
	(	select	isnull ( max ( id ), 0 ) + 1
		  from	log
		 where	spid = @@spid ),
	'Processing complete.' + convert ( varchar(20), getdate ( ) )

--	53. Remove processed inbound data.
delete	m_in_release_plan
return 0
GO
