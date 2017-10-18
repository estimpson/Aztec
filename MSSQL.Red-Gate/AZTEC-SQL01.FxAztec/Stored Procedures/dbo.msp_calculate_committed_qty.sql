SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[msp_calculate_committed_qty] (
	@orderno	numeric(8,0),
	@ordpart	varchar (25) = null,
	@suffix		integer = null )
as
---------------------------------------------------------------------------------------
-- 	This procedure calculates the committed quantity for an order.
--
--	Modifications:	22 JAN 1999, Eric E. Stimpson	Original.
--			29 MAY 1999, Eric E. Stimpson	Modified formatting.
--			09 JUN 1999, Chris Rogers	Modified to use due_date instead of sequence order.
--			06 JUL 1999, Eric E. Stimpson	Added suffix loop for normal orders.
--			08 AUG 1999, Chris Rogers	Included sequence for uniqueness in the case of duplicate due_date.
--							Changed @orderno argument to a numeric(8,0) to match db.
--			10 FEB 2000, Eric E. Stimpson	Fixed issue with finding next release with duplicate due_dates.
--			12 DEC 2001, Harish Gubbi	Changed the logic of assigining the committed qty
--			20 JAN 2003, Harish Gubbi	Changed the cursor var from releases to creleases
--
--	Paramters:	@orderno	mandatory
--			@ordpart	optional
--			@suffix		optional
--
--	Returns:	  0		success
--			100		order not found
--
--	Process:
--	1.	Declarations.
--	2.	Initializations.
--	3.	Check if part number was passed and loop through all parts if not.
--	4.	Check if suffix was passed and loop through all suffixes if not.
--	5.	Check if order exists and return 100 if not.
--	6.	Build shipper part number from part number and suffix.
--	7.	Get the total committed for this part.
--	8.	Set committed quantity to zero for this order.
--	9.	Initialize due date and sequence.	
--	10.	Loop through order detail rows, writing committed quantities.
--	11.	If sequence was found, set committed quantity appropriately, otherwise set remaining committed to zero.
--	12.	If release is less than remaining committed quantity then use whole release.
--	13.	Otherwise, use partial release.
--	14.	Find the next order detail release and its quantity.
--	15.	Completed successfully, return 0
---------------------------------------------------------------------------------------

--	1.	Declarations.
declare	@shippart		varchar (35),
	@shiptype		char (1),
	@committedleft		numeric (20,6),
	@releaseqty		numeric (20,6),
	@sequence		integer,
	@retcode		integer,
	@due_date		datetime,
	@ctrvar			integer

--	2.	Initializations.
select	@retcode = 100
select	@due_date = DateAdd ( yy, -10, GetDate ( ) )

--	3.	Check if part number was passed and loop through all parts if not.
if @ordpart is null
begin -- (1aB)
	select	@ordpart = min ( part_number )
	  from	order_detail
	 where	order_no = @orderno

	while @ordpart > ''
	begin -- (2aB)
		exec	@retcode = msp_calculate_committed_qty
				@orderno,
				@ordpart

		select	@ordpart = min ( part_number )
		  from	order_detail
		 where	order_no = @orderno and
			part_number > @ordpart
	end -- (2aB)
	return @retcode

end -- (1aB)

--	4.	Check if suffix was passed and loop through all suffixes if not.
if @suffix is null
begin -- (1aB)
	select	@suffix = min ( suffix )
	  from	order_detail
	 where	order_no = @orderno and
		part_number = @ordpart

	while @suffix > 0
	begin -- (2bB)
		exec	@retcode = msp_calculate_committed_qty
				@orderno,
				@ordpart,
				@suffix

		select	@suffix = min ( suffix )
		  from	order_detail
		 where	order_no = @orderno and
			part_number = @ordpart and
			suffix > @suffix
	end -- (2bB)

end -- (1aB)

--	5.	Check if order exists and return 100 if not.
if
(	select	count ( 1 )
	  from	order_detail
	 where	order_no = @orderno and
		part_number = @ordpart and
		( suffix = @suffix or @suffix is null ) ) = 0
	return 100

--	6.	Build shipper part number from part number and suffix.
if @suffix > 0
	select	@shippart = @ordpart + '-' + convert ( varchar ( 9 ), @suffix )
else
	select	@shippart = @ordpart

--	7.	Get the total committed for this part.
select	@committedleft = isnull ( (
	select	sum ( qty_required )
	  from	shipper_detail,
		shipper
	 where	order_no = @orderno and
		part = @shippart and
		shipper = id and
		shipper.type is null and
		( status = 'O' or status = 'A' or status = 'S') ), 0 )

--	8.	Set committed quantity to zero for this order.
update	order_detail
   set	committed_qty = 0
 where	order_no = @orderno and
	part_number = @ordpart and
	( ( suffix is null ) or suffix = @suffix )

declare	creleases cursor local for
select	due_date, sequence, quantity
from	order_detail
where	order_no = @orderno and
	part_number = @ordpart and
	(	suffix is null or
		suffix = @suffix )
order by due_date, sequence	


--	9.	Initialize due date and sequence.	
select	@ctrvar = 0

--	Open cursor
open	creleases

--	fetch data from the cursor
fetch	creleases
into	@due_date, @sequence, @releaseqty

--	Check sqlstatus
if @@fetch_status <> 0 
	select @ctrvar = 1

--	loop through all the order detail rows
while @ctrvar = 0
begin

	--	10.	Loop through order detail rows, writing committed quantities.
	if @committedleft > 0 
	begin -- (1bB)

	--	11.	If sequence was found, set committed quantity appropriately, otherwise set remaining committed to zero.
		if @sequence > 0
		begin -- (2bB)
	
	--	12.	If release is less than remaining committed quantity then use whole release.
			if @committedleft > @releaseqty
			begin -- (3bB)
				update	order_detail
				   set	committed_qty = @releaseqty
				 where	order_no = @orderno and
					sequence = @sequence
	
				select	@committedleft = @committedleft - @releaseqty
			end -- (3bB)
	
	--	13.	Otherwise, use partial release.
			else
			begin -- (3cB)
				update	order_detail
				   set	committed_qty = @committedleft
				 where	order_no = @orderno and
					sequence = @sequence
	
				select	@committedleft = 0
			end -- (3cB)
	
		end -- (2bB)
		else
			select	@committedleft = 0

		--	fetch data from the cursor			
		fetch	creleases
		into	@due_date, @sequence, @releaseqty
		
		--	Check sqlstatus		
		if @@fetch_status <> 0 
			select @ctrvar = 1

	end -- (1bB)
	else
		select @ctrvar = 1
end

--	Close cursor
close	creleases
deallocate creleases
	
--	15.	Completed successfully, return 0.
return 0
GO
