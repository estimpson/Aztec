SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.msp_process_in_ship_sched    Script Date: 4/25/2001 11:11:16 AM ******/

/****** Object:  Stored Procedure dbo.msp_process_in_ship_sched    Script Date: 3/15/2000 3:48:57 PM ******/
CREATE PROCEDURE [dbo].[msp_process_in_ship_sched]
AS
BEGIN TRANSACTION -- (1T)
---------------------------------------------------------------------------------------
--  This procedure creates releases from inbound ship schedule data.
--  Modified:	22 Apr 1999, Eric E. Stimpson
--  Returns:	0		success
--  			100		ship schedule not found 
---------------------------------------------------------------------------------------

--  Declare all the required local variables.
	DECLARE	@returncode			integer,
			@totcount			integer,
			@fiscalyearbegin	datetime,
			@orderno			decimal(8),
			@customerpart		varchar(35),
			@shipto				varchar(20),
			@customerpo			varchar(30),
			@modelyear			varchar(4),
			@releaseno			varchar(30),
			@quantityqualifier	char(1),
			@quantity			decimal(20,6),
			@releasedt			datetime,
			@releasedtqualifier	char(1),
			@blanketpart		varchar(25),
			@plant				varchar(10),
			@prevorderno		decimal(8),
			@cumshipped			decimal(20,6),
			@cumordered			decimal(20,6),
			@newcumordered		decimal(20,6),
			@releasequantity	decimal(20,6),
			@orderunit			char (2),
			@standardquantity	decimal(20,6),
			@sequence			tinyint,
			@rowid				tinyint,
			@weekno				integer

--  Inititialize all variables.
	SELECT	@totcount = 0,
			@fiscalyearbegin = null,
			@orderno = 0,
			@customerpart = null,
			@shipto = null,
			@customerpo = null,
			@modelyear = null,
			@releaseno = null,
			@quantityqualifier = null,
			@quantity = null,
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

--  Purge log table.
	DELETE	log
	 WHERE	spid = @@spid

--  Log purged, indicate in log.
	INSERT	log
	SELECT	@@spid,
			(	SELECT	IsNull ( Max ( id ), 0 ) + 1
				  FROM	log
				 WHERE	spid = @@spid ),
			'Log purged successfully.'

--  Get the totcount from the m_in_ship_schedule table
	SELECT	@totcount = Count ( 1 )
	  FROM	m_in_ship_schedule

--  If there is data to process, proceed...
	IF	( @totcount > 0 )
	BEGIN -- (2aB)

--  Data found, start processing, indicate in log.
		INSERT	log
		SELECT	@@spid,
				(	SELECT	IsNull ( Max ( id ), 0 ) + 1
					  FROM	log
					 WHERE	spid = @@spid ),
				'Start processing ' + Convert ( varchar ( 20 ), GetDate ( ) ) + '.'

--  Get the fiscal year begin date.
		SELECT	@fiscalyearbegin = fiscal_year_begin
		  FROM	parameters

--  Declare the cusror for processing inbound ship schedule data.
		DECLARE	ibcursor CURSOR FOR
		SELECT	customer_part,
				shipto_id,
				customer_po,
				model_year,
				release_no,
				quantity_qualifier,
				quantity,
				release_dt,
				release_dt_qualifier
		  FROM	m_in_ship_schedule
		ORDER BY	1, 2, 3, 4, 8

--  Open the cursor.
		  OPEN	ibcursor

--  Fetch a row of data from the cursor.
		 FETCH	ibcursor
		  INTO	@customerpart,
				@shipto,
				@customerpo,
				@modelyear,
				@releaseno,
				@quantityqualifier,
				@quantity,
				@releasedt,
				@releasedtqualifier

--  Continue processing as long as more inbound ship schedule data exists.
		WHILE	( @@ROWCOUNT > 0 )
		BEGIN -- (3B)

--  Processing release, indicate in log.
			INSERT	log
			SELECT	@@spid,
					(	SELECT	IsNull ( Max ( id ), 0 ) + 1
						  FROM	log
						 WHERE	spid = @@spid ),
					'Searching for blanket order for customer part :  (' + @customerpart + ', destination :' + @shipto + ', customer po :' + @customerpo + ' & model year :'+ @modelyear+'.  Processing release #  (' + @releaseno+') due ' + Convert ( varchar(20), @releasedt, 113) + '.'

--  Find blanket order.
			EXEC	@returncode = msp_find_blanket_order
						@customerpart,
						@shipto,
						@customerpo,
						@modelyear,
						@orderno OUTPUT

--  If order find was successful.
			IF @returncode = 0
			BEGIN -- (4B)

--  Get blanket order info:  blanket part, plant, accumulative shipped.
				SELECT	@blanketpart = blanket_part,
				        @plant = plant,
				        @cumshipped = IsNull(our_cum,0),
						@orderunit = shipping_unit
	              FROM	order_header
				 WHERE	order_no = @orderno

--  If this is a new order, delete old ship schedule, and forecast schedule.
				IF	( @orderno <> IsNull ( @prevorderno, 0 ) )
				BEGIN -- (5aB)

--  Deleting ship schedule.
					DELETE	order_detail
					 WHERE	order_no = @orderno AND
					 		type = 'F'

--  Ship schedule deleted, indicate in log.
					INSERT	log
					SELECT	@@spid,
							(	SELECT	IsNull ( Max ( id ), 0 ) + 1
								  FROM	log
								 WHERE	spid = @@spid ),
							'Deleted old ship schedule from order detail.'

--  If previous order was valid, calculate committed quantity for the previous order.
					IF @prevorderno > 0
					BEGIN -- (6B)
						EXEC	@returncode = msp_calculate_committed_qty
									@prevorderno,
									@blanketpart,
									NULL

--  Indicate calculation success in log.
						IF @returncode = 0

--  Calculation was successful, indicate in log.
							INSERT	log
							SELECT	@@spid,
									(	SELECT	IsNull ( Max ( id ), 0 ) + 1
										  FROM	log
										 WHERE	spid = @@spid ),
									'Calculated committed quantity for order:  ' + Convert ( char ( 8 ), @prevorderno ) + '.'
						ELSE

--  Calculation was unsuccessful, indicate in log
							INSERT	log
							SELECT	@@spid,
									(	SELECT	IsNull ( Max ( id ), 0 ) + 1
										  FROM	log
										 WHERE	spid = @@spid ),
									'Failed to calculated committed quantity for order:  ' + Convert ( char ( 8 ), @prevorderno ) + '.  Order not found.'
					END -- (6B)
						
--  Assign the prev order no with the current order no, and cumordered with the cumshipped
					SELECT	@prevorderno = @orderno,
							@cumordered = @cumshipped
				END -- (5aB)

--  Calculate the appropriate releasequantity, cumordered, and newcumordered based on quantityqualifier...
				IF	( @quantityqualifier = 'A' )

--  The quantity value is an accumulative requirement.
--  Calculate the releasequantity and set the newcumordered.
					SELECT	@releasequantity = @quantity - @cumordered,
							@newcumordered = @quantity
				ELSE

--  The quantity value is a net requirement.
--  Calculate the newcumordered and set the releasequantity.
					SELECT	@newcumordered = @quantity + @cumordered,
							@releasequantity = @quantity

--  Calculate standard quantity for release quantity.
					SELECT	@standardquantity = @releasequantity
					EXEC	@returncode = msp_calculate_std_quantity
								@blanketpart,
								@releasequantity,
								@orderunit

--  Indicate unsuccessful calculation in log.
						IF @returncode = -1

--  Calculation was unsuccessful, indicate in log
							INSERT	log
							SELECT	@@spid,
									(	SELECT	IsNull ( Max ( id ), 0 ) + 1
										  FROM	log
										 WHERE	spid = @@spid ),
									'Failed to calculated standard quantity for part:  ' + @blanketpart + ' and unit:  ' + @orderunit + '.  Invalid unit for part.'

--  Determine the validity of the release (releasequantity greater than zero)...
				IF	@releasequantity > 0
				BEGIN -- (5bB)

--  Release is valid, get the next sequence and rowid for the new release.
					SELECT	@sequence = IsNull ( (
								SELECT	Max ( sequence )
								  FROM	order_detail as od
								 WHERE	od.order_no = @orderno AND
								 		type = 'F' ), 0 ) + 1,
							@rowid = IsNull ( (
								SELECT	Max ( row_id )
								  FROM	order_detail as od
								 WHERE	od.order_no = @orderno AND
								 		type = 'F' ), 0 ) + 1

--  Calculate the week number (from fiscalyearbegin).
					SELECT	@Weekno = Datediff ( dd, @fiscalyearbegin, @releasedt ) / 7 + 1

--  Create release.
					INSERT	order_detail
					(		order_no,
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
					VALUES
					(		@orderno,
							@sequence,
							@blanketpart,
							'F',
							@releasequantity,
							@releasedtqualifier,
							'862-Release created thru stored procedure',
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

--  Release was created, indicate in log.
					INSERT	log
					SELECT	@@spid,
							(	SELECT	IsNull ( Max ( id ), 0 ) + 1
								  FROM	log
								 WHERE	spid = @@spid ),
							'Inserted release for customer part :' + @customerpart+', destination :' + @shipto + ', release date :' + Convert( varchar(16), @releasedt ) + ', quantity :' + Convert( varchar(20), @releasequantity )

--  Set the cumordered to the newcumordered.
					SELECT	@cumordered = @newcumordered
				END -- (5bB)
				ELSE

--  Release was already shipped, indicate in log.
					INSERT	log
					SELECT	@@spid,
							(	SELECT	IsNull ( Max ( id ), 0 ) + 1
								  FROM	log
								 WHERE	spid = @@spid ),
							'Release not saved because quantity ordered has already been shipped.'
			END -- (4B)
			ELSE

--  Determine if exception was multiple orders found.
				IF @returncode = -1
	
--  Multiple orders found, indicate in log.
					INSERT	log
					SELECT	@@spid,
							(	SELECT	IsNull ( Max ( id ), 0 ) + 1
								  FROM	log
								 WHERE	spid = @@spid ),
							'Blanket order is not unique for the customer part: ' + @customerpart + ', destination: ' + @shipto + ', customer po: ' + @customerpo + ' & model year: ' + @modelyear + '. Create one & then re-process.'
	
				ELSE
	
--  No orders found, indicate in log.
					INSERT	log
					SELECT	@@spid,
							(	SELECT	IsNull ( Max ( id ), 0 ) + 1
								  FROM	log
								 WHERE	spid = @@spid ),
							'Blanket order does not exist for the customer part: ' + @customerpart + ', destination: ' + @shipto + ', customer po: ' + @customerpo + ' & model year: ' + @modelyear + '. Create one & then re-process.'

--  Reinitialize order no.
	        SELECT	@orderno = 0

--  Fetch a row of data from the cursor 
			 FETCH	ibcursor
			  INTO	@customerpart,
					@shipto,
					@customerpo,
					@modelyear,
					@releaseno,
					@quantityqualifier,
					@quantity,
					@releasedt,
					@releasedtqualifier

		END -- (3B)

--  If previous order was valid, calculate committed quantity for the previous order.
		IF @prevorderno > 0
		BEGIN -- (3bB)
			EXEC	@returncode = msp_calculate_committed_qty
						@prevorderno,
						@blanketpart,
						NULL

--  Indicate calculation success in log.
		IF @returncode = 0

--  Calculation was successful, indicate in log.
			INSERT	log
			SELECT	@@spid,
					(	SELECT	IsNull ( Max ( id ), 0 ) + 1
						  FROM	log
						 WHERE	spid = @@spid ),
					'Calculated committed quantity for order:  ' + Convert ( char ( 8 ), @prevorderno ) + '.'
		ELSE

--  Calculation was unsuccessful, indicate in log
			INSERT	log
			SELECT	@@spid,
					(	SELECT	IsNull ( Max ( id ), 0 ) + 1
						  FROM	log
						 WHERE	spid = @@spid ),
					'Failed to calculated committed quantity for order:  ' + Convert ( char ( 8 ), @prevorderno ) + '.  Order not found.'
		END -- (3bB)

--  Close the cursor.
		CLOSE	ibcursor

	END -- (2aB)
	ELSE

--  No inbound ship schedule to process, indicate in log and return rows not found.
	BEGIN -- (2bB)
		INSERT	log
		SELECT	@@spid,
				(	SELECT	IsNull ( Max ( id ), 0 ) + 1
					  FROM	log
					 WHERE	spid = @@spid ),
		'Inbound ship schedule does not exist.  Check configuration and reprocess.'
		COMMIT TRANSACTION -- (1T)
		Return	100
	END -- (2bB)

--  Done processing, indicate in log.
	INSERT	log
	SELECT	@@spid,
			(	SELECT	IsNull ( Max ( id ), 0 ) + 1
				  FROM	log
				 WHERE	spid = @@spid ),
			'Processing complete.' + Convert ( varchar(20), getdate ( ) )
--  Remove processed inbound data.
	DELETE	m_in_ship_schedule

COMMIT TRANSACTION -- (1T)
Return 0
GO
