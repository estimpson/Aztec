SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_createinsertedrelease]
(	@orderno	numeric (8),
	@duedate	datetime,
	@quantity	numeric (20,6),
	@orderqueue	char (1) = null,
	@note		char (255) = null,
	@forecasttype	char (1) = null )
as
---------------------------------------------------------------------------------------
--	This procedure creates inserted releases from passed and static data.
--
--	Modifications:	08 JAN 1999, Eric E. Stimpson
--			25 MAY 1999, Eric E. Stimpson	Modified formatting.
--							Changed decimal to numeric.
--							Modified to update accums.
--							Modified to use sequence.
--			05 JAN 2000, Eric E. Stimpson	Add result set on success.
--							Modify to honor queue independence.
--			25 FEB 2000, Eric E. Stimpson	Fix to get our_cum for new last release.
--
--	Parameters:	@orderno	mandatory
--			@duedate	mandatory
--			@quantity	mandatory
--			@orderqueue	optional
--			@note		optional
--			@forecasttype	optional
--
--	Returns:	  0	success
--			100	order not found
--
--	Process:
--	1. Declare all the required local variables.
--	2. Get blanket order info:  blanket part, plant, accumulative shipped.
--	3. If blanket part not found, return no rows found.
--	4. Get the fiscal year begin date.
--	5. Calculate the week number (from fiscalyearbegin).
--	6. Find the sequence, rowid, and beginning cum of the release to be inserted.
--	7. Modify sequence numbers and accums of all releases which chronologically follow the release to be created.
--	8. Create release.
--	9. Return success.
---------------------------------------------------------------------------------------

--	1. Declare all the required local variables.
declare	@blanketpart		varchar ( 25 ),
	@shipto			varchar (20),
	@customerpart		varchar (35),
	@plant			varchar (10),
	@orderunit		char (2),
	@sequence		tinyint,
	@rowid			tinyint,
	@fiscalyearbegin	datetime,
	@weekno			integer,
	@begincum		numeric (20,6)

--	2. Get blanket order info:  blanket part, plant, accumulative shipped.
select	@blanketpart = blanket_part,
	@shipto = destination,
	@customerpart = customer_part,
	@plant = plant,
	@orderunit = shipping_unit
  from	order_header
 where	order_no = @orderno

--	3. If blanket part not found, return no rows found.
if @blanketpart is null
	return 100

--	4. Get the fiscal year begin date.
select	@fiscalyearbegin = fiscal_year_begin
  from	parameters

--	5. Calculate the week number (from fiscalyearbegin).
select	@weekno = datediff ( dd, @fiscalyearbegin, @duedate ) / 7 + 1

--	6. Find the sequence, rowid, and beginning cum of the release to be inserted.
select	@sequence = isnull ( max ( sequence ) + 1, (
		case when @orderqueue = 'P'
			then 101
			else 1
		end ) ),
	@rowid = isnull ( max ( row_id ) + 1, (
		case when @orderqueue = 'P'
			then 101
			else 1
		end ) ),
	@begincum = isnull ( max ( the_cum ), isnull ( (
		select	our_cum
		  from	order_header
		 where	order_no = @orderno ), 0 ) )
  from	order_detail_inserted
 where	order_no = @orderno and
 	due_date < @duedate and
 	type = @orderqueue

--	7. Modify sequence numbers and accums of all releases which chronologically follow the release to be created.
update	order_detail_inserted
   set	sequence = sequence + 1,
   	row_id = row_id + 1,
   	our_cum = our_cum + @quantity,
	the_cum = the_cum + @quantity
 where	order_no = @orderno and
 	sequence >= @sequence and
 	type = @orderqueue

--	8. Create release.
	insert	order_detail_inserted
	(		order_no,
			sequence,
			part_number,
			type,
			quantity,
			our_cum,
			the_cum,
			unit,
			notes,
			status,
			due_date,
			destination,
			customer_part,
			row_id,
			flag,
			ship_type,
			packline_qty,
			plant,
			week_no )
	values
	(	@orderno,
		@sequence,
		@blanketpart,
		isnull ( @orderqueue, 'F' ),
		@quantity,
		@begincum,
		@begincum + @quantity,
		@orderunit,
		isnull ( @note, 'Release created thru stored procedure' ),
		@forecasttype,
		@duedate,
		@shipto,
		@customerpart,
		@rowid,
		1,
		'N',
		0,
		@plant,
		@weekno )

--	9. Return success.
select 0
return 0
GO
