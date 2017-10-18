SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_removeinsertedrelease]
(	@orderno	numeric (8),
	@sequence	tinyint )
as
---------------------------------------------------------------------------------------
--	This procedure removes inserted releases.
--
--	Modifications:	08 JAN 1999, Eric E. Stimpson	Original.
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--							Changed decimal to numeric.
--							Modified to update accums.
--							Modified to update sequence.
--							Modified to use sequence.
--			05 JAN 2000, Eric E. Stimpson	Add result set on success.
--							Modify to honor queue independence.
--	
--	Parameters:	@orderno	mandatory
--			@sequence	mandatory
--			@quantity	mandatory
--
--	Returns:	  0	success
--			100	release not found
--
--	Process:
--	1. Declare all the required local variables.
--	2. Get old quantity and order queue prior to removing release for sequence and accum updating.
--	3. If no rows, return no rows found.
--	4. Remove inserted release.
--	5. Modify sequence numbers and accums of all releases which chronologically follow the removed release.
--	6. Return success.
---------------------------------------------------------------------------------------

--	1. Declare all the required local variables.
declare	@oldquantity		numeric (20,6),
	@orderqueue		char (1)

--	2. Get old quantity and order queue prior to removing release for sequence and accum updating.
select	@oldquantity = quantity,
	@orderqueue = type
  from	order_detail_inserted
 where	order_no = @orderno and
	sequence = @sequence

--	3. If no rows, return no rows found.
if @@rowcount = 0
	return 100

--	4. Remove inserted release.
delete	order_detail_inserted
 where	order_no = @orderno and
	sequence = @sequence

--	5. Modify sequence numbers, row id, and accums of all releases which chronologically follow the removed release.
update	order_detail_inserted
   set	sequence = sequence - 1,
	row_id = row_id - 1,
  	our_cum = our_cum - @oldquantity,
	the_cum = the_cum - @oldquantity
 where	order_no = @orderno and
 	sequence > @sequence and
 	type = @orderqueue

--	6. Return success.
select 0
return 0
GO
