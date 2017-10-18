SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_updateinsertedrelease]
(	@orderno	numeric (8),
	@sequence	tinyint,
	@quantity	numeric (20,6) )
as
---------------------------------------------------------------------------------------
--	This procedure updates inserted releases from passed and static data.
--
--	Modifications:	08 JAN 1999, Eric E. Stimpson	Original.
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--							Changed decimal to numeric.
--							Modified to update accums.
--							Modified to use sequence.
--			05 JAN 2000, Eric E. Stimpson	Add result set on success.
--							Modify to honor queue independence.
--	
--	Parameters:	@orderno	mandatory
--			@sequence	mandatory
--			@quantity	mandatory
--
--	Returns:	  0	success
--			 -1	invalid unit for part in order header
--			100	order not found
--
--	Process:
--	1. Declare all the required local variables.
--	2. Get blanket order info:  blanket part, plant, accumulative shipped.
--	3. If blanket part not found, return no rows found.
--	4. Calculate the standard quantity.
--	5. If error calculating standard quantity, then return invalid unit.
--	6. Get old quantity snf order queue prior to change for accum updating later.
--	7. Update release with new quantity.
--	8. Modify accums of all releases which chronologically follow modified release.
--	9. Return success.
---------------------------------------------------------------------------------------

--	1. Declare all the required local variables.
declare	@blanketpart		varchar (25),
	@orderunit		char (2),
	@oldquantity		numeric (20,6),
	@standardquantity	numeric (20,6),
	@returnvalue		integer,
	@orderqueue		char (1)

--	2. Get blanket order info:  blanket part, plant, accumulative shipped.
select	@blanketpart = blanket_part,
	@orderunit = shipping_unit
  from	order_header
 where	order_no = @orderno

--	3. If blanket part not found, return no rows found.
if @blanketpart is null
	return 100

--	4. Calculate the standard quantity.
select	@standardquantity = @quantity

execute	@returnvalue = msp_calculate_std_quantity
		@blanketpart,
		@standardquantity,
		@orderunit

--	5. If error calculating standard quantity, then return invalid unit.
if @returnvalue = -1
	return -1

--	6. Get old quantity and order queue prior to change for accum updating later.
select	@oldquantity = quantity,
	@orderqueue = type
  from	order_detail_inserted
 where	order_no = @orderno and
 	sequence = @sequence

--	7. Update release with new quantity.
update	order_detail_inserted
   set	quantity = @quantity,
	std_qty = @standardquantity,
	the_cum = our_cum + @quantity
 where	order_no = @orderno and
	sequence = @sequence

--	8. Modify accums of all releases which chronologically follow the modified release.
update	order_detail_inserted
   set	our_cum = our_cum + ( @quantity - @oldquantity ),
	the_cum = the_cum + ( @quantity - @oldquantity )
 where	order_no = @orderno and
 	sequence > @sequence and
 	type = @orderqueue

--	9. Return success.
select 0
return 0
GO
