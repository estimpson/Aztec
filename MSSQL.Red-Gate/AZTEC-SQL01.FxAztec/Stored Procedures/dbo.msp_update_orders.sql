SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc
[dbo].[msp_update_orders] (
	@shipper integer )
as
---------------------------------------------------------------------------------------
--	This procedure updates orders based on shipped line items.
--
--	Modifications:	01 MAR 1999, Harish P. Gubbi	Original.
--			02 JUL 1999, Harish P. Gubbi	Updating releases for normal orders.
--			03 JUL 1999, Harish P. Gubbi	Re-sequencing for normal orders.
--			07 JUL 1999, Eric E. Stimpson	Reformatted.
--			04 AUG 1999, Eric E. Stimpson	Removed loop through blanket order releases.
--			03 SEP 1999, Eric E. Stimpson	Removed references to @accumshipped from blanket order processing.
--			21 FEB 2001, Harish G. P	Changed the column to get the right std qty for normal orders	
--			31 MAR 2001, Harish G. P	Changed the column to from pack_line_qty to qty_packed for normal orders	
--			06 MAR 2002, Harish G. P	Included a new variable to store od.quantity & use the same in the equation
--							 to calculate new shipqty
--			10 FEB 2003, Harish G. P	Included order type check while closing the order
--			23 JAN 2012, Andre S. Boulanger - Added code to Insert Mazda Delivery Order Numbers
--
--	Parameters:	@shipper
--			@operator
--			@returnvalue
--
--	Returns:	  0	success
--
--	Process:
--	1.	Declare all the required local variables.
--	2.	Update accum shipped on shipper detail and blanket order header.
--	3.	Remove mps records and releases for fully shipped releases.
--	4.	Remove mps records and mark releases for partially shipped releases.
--	5.	Declare cursor for lineitems shipped against normal orders.
--	6.	Loop through lineitems.
--	7.	Declare cursor for releases.
--	8.	Loop through all releases for this part and suffix in due_date order.
--	9.	Check if release was fully shipped.
--	10.	Remove mps records and releases for fully shipped release.
--	11.	Remove mps records and mark releases for partially shipped release.
--	12.	Get next release.
--	13.	Get next lineitem.
--	14.	Declare cursor for shipped orders.
--	15.	Loop through orders.
--	16.	Check order for remaining releases.
--	17.	Resequence remaining releases.
--	18.	Initialize new sequence.
--	19.	Mark remaining releases to process.
--	20.	Declare cursor for remainingreleases.
--	21.	Loop through all remaining releases.
--	22.	Set new sequence.
--	23.	Get next remaining release.
--	24.	Get next shipped order.
--	25.	Return.
---------------------------------------------------------------------------------------

--	1.	Declare all the required local variables.
declare @part		varchar (25),
	@orderno	numeric (8,0),
	@stdqty		numeric (20,6),
	@suffix		integer,
	@ordertype	char (1),
	@ourcum		numeric (20,6),
	@accumshipped	numeric (20,6),
	@sequence	numeric (5,0),
	@relstdqty	numeric (20,6),
	@shipqty	numeric (20,6),	
	@releasedt	datetime,
	@releaseno	varchar (20),
	@rowid		integer,
	@newsequence	integer,
	@odqty		numeric(20,6),
	@odunit		char(2),
	@stdunit	char(2),
	@factor		numeric(20,6)

--	2.	Update accum shipped on shipper detail and blanket order header.
update	shipper_detail
set	accum_shipped = order_header.our_cum + shipper_detail.alternative_qty
from	shipper_detail
	join shipper on shipper_detail.shipper = shipper.id
	join order_header on shipper_detail.order_no = order_header.order_no
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B'

update	order_header
set	our_cum = order_header.our_cum + shipper_detail.alternative_qty
from	shipper_detail
	join shipper on shipper_detail.shipper = shipper.id
	join order_header on shipper_detail.order_no = order_header.order_no
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B'

--	3.	Remove mps records and releases for fully shipped releases.
delete	master_prod_sched
from	master_prod_sched
	join order_detail on origin = order_detail.order_no and
		source = order_detail.row_id
	join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.the_cum <= order_header.our_cum
	
--Added Insert To Mazda Delivery Order Numbers table for Mazda ASNs
/*declare @TradingPartnerCode varchar(15)
select @TradingPartnerCode = (select max(trading_partner_code) from edi_setups where destination = (select destination from shipper where id = @shipper and shipper.status = 'C'))
if upper(@TradingPartnerCode) like '%MAZDA%'
Begin
insert EDI.MazdaDeliveryOrderNumbers
        ( DeliveryOrderNumber, Quantity, OrderNo, ShipperID )

select
	left(order_detail.Release_no,9),
	order_detail.quantity,
	order_detail.order_no,
	@Shipper
from
	dbo.order_detail
join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.the_cum <= order_header.our_cum
End
	*/

delete	order_detail
from	order_detail
	join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.the_cum <= order_header.our_cum

--	Added on 12/05/03 from here
declare	odlines cursor for
select	od.order_no, od.part_number, od.quantity, od.unit, od.sequence, piv.standard_unit
from	order_detail od
	join order_header oh on oh.order_no = od.order_no
	join part_inventory piv on piv.part = od.part_number
where	od.quantity = od.std_qty and
	od.unit <> piv.standard_unit and
	oh.order_no in ( select order_no from shipper_detail where shipper = @shipper)

open odlines

fetch	odlines
into	@orderno, @part, @odqty, @odunit, @sequence, @stdunit

while ( @@fetch_status = 0 )
begin -- (1aa)

	--	Get the standard quantity conversion factor.
	select	@factor = IsNull
			( (	select	conversion
				  from	unit_conversion,
					part_unit_conversion
				 where	part_unit_conversion.part = @part AND
					part_unit_conversion.code = unit_conversion.code AND
					unit_conversion.unit1 = @odunit AND
					unit_conversion.unit2 = @stdunit), -1 )

	if @factor > 0
	begin 
		--	Calculate the standard quantity.
		select	@stdqty = @odqty * @factor
	
		--	update order detail
		update	order_detail
		set	std_qty = @stdqty
		where	order_no = @orderno and
			part_number = @part and
			sequence = @sequence
	end		
	
	fetch	odlines
	into	@orderno, @part, @odqty, @odunit, @sequence, @stdunit
end -- (1aa)
close	odlines
deallocate odlines
--	Added on 12/05/03 till here	

--	4.	Remove mps records and mark releases for partially shipped releases.
delete	master_prod_sched
from	master_prod_sched
	join order_detail on origin = order_detail.order_no and
		source = order_detail.row_id
	join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.our_cum < order_header.our_cum and
	order_detail.the_cum > order_header.our_cum


--Added Insert To Mazda Delivery Order Numbers table for Mazda ASNs
/*if upper(@TradingPartnerCode) like '%MAZDA%'
Begin
insert EDI.MazdaDeliveryOrderNumbers
        ( DeliveryOrderNumber, Quantity, OrderNo, ShipperID )

select
	left(order_detail.Release_no,9),
	order_header.our_cum - order_detail.our_cum ,
	order_detail.order_no,
	@Shipper
from	order_detail
	join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.our_cum < order_header.our_cum and
	order_detail.the_cum > order_header.our_cum
end
*/


update	order_detail
set	std_qty = order_detail.the_cum - order_header.our_cum,
	quantity = order_detail.the_cum - order_header.our_cum,
	our_cum = order_header.our_cum,
	flag=1
from	order_detail
	join order_header on order_detail.order_no = order_header.order_no
	join shipper_detail on shipper_detail.order_no = order_header.order_no
	join shipper on shipper_detail.shipper = shipper.id
where	shipper_detail.shipper = @shipper and
	order_header.order_type = 'B' and
	order_detail.our_cum < order_header.our_cum and
	order_detail.the_cum > order_header.our_cum

--	Added on 12/05/03 from here
declare	odlines cursor for
select	od.order_no, od.part_number, od.quantity, od.unit, od.sequence, piv.standard_unit
from	order_detail od
	join order_header oh on oh.order_no = od.order_no
	join part_inventory piv on piv.part = od.part_number
where	od.quantity = od.std_qty and
	od.unit <> piv.standard_unit and
	oh.order_no in ( select order_no from shipper_detail where shipper = @shipper)

open odlines

fetch	odlines
into	@orderno, @part, @odqty, @odunit, @sequence, @stdunit

while ( @@fetch_status = 0 )
begin -- (1aa)

	--	Get the standard quantity conversion factor.
	select	@factor = IsNull
			( (	select	conversion
				  from	unit_conversion,
					part_unit_conversion
				 where	part_unit_conversion.part = @part AND
					part_unit_conversion.code = unit_conversion.code AND
					unit_conversion.unit1 = @odunit AND
					unit_conversion.unit2 = @stdunit), -1 )

	if @factor > 0
	begin 
		--	Calculate the standard quantity.
		select	@stdqty = @odqty * @factor
	
		--	update order detail
		update	order_detail
		set	std_qty = @stdqty
		where	order_no = @orderno and
			part_number = @part and
			sequence = @sequence
	end		
	
	fetch	odlines
	into	@orderno, @part, @odqty, @odunit, @sequence, @stdunit
end -- (1aa)
close	odlines
deallocate odlines
--	Added on 12/05/03 till here

--	5.	Declare cursor for lineitems shipped against normal orders.
declare lineitems cursor for
	select	shipper_detail.part_original,
		shipper_detail.order_no,
		shipper_detail.qty_packed,
		shipper_detail.suffix,
		order_header.order_type,
		order_header.our_cum,
		shipper_detail.alternative_qty
	from	shipper_detail
		join shipper on shipper_detail.shipper = shipper.id
		join order_header on shipper_detail.order_no = order_header.order_no
	where	shipper_detail.shipper = @shipper and
		shipper.type is null and
		order_header.order_type = 'N'

--	6.	Loop through lineitems.
open lineitems

fetch	lineitems
into	@part,
	@orderno,
	@stdqty,
	@suffix,
	@ordertype,
	@ourcum,
	@shipqty

while ( @@fetch_status = 0 )
begin -- (1aB)

--	7.	Declare cursor for releases.
	declare releases insensitive cursor for
	select	sequence,
		std_qty,
		row_id,
		quantity
	from	order_detail
	where	order_no = @orderno and
		part_number = @part and
		IsNull ( suffix, 0 ) = IsNull ( @suffix, 0 )
	order by due_date

--	8.	Loop through all releases for this part and suffix in due_date order.
	open releases

	fetch	releases
	into	@sequence,
		@relstdqty,
		@rowid,
		@odqty

	while ( @@fetch_status = 0 and @stdqty > 0 )
	begin -- (2aB)

--	9.	Check if release was fully shipped.

		if @relstdqty <= @stdqty
		begin -- (3aB)

--	10.	Remove mps records and releases for fully shipped release.

			delete	master_prod_sched
			from	master_prod_sched
			where	origin = @orderno and
				source = @rowid
			
			delete	order_detail
			where	order_no = @orderno and
				sequence = @sequence

			select	@stdqty = @stdqty - @relstdqty,
				@shipqty = @shipqty - @odqty
		end -- (3aB)
		else
		begin -- (3bB)
--	11.	Remove mps records and mark releases for partially shipped release.

			delete	master_prod_sched
			from	master_prod_sched
			where	origin = @orderno and
				source = @rowid

			update	order_detail
			set	std_qty = @relstdqty - @stdqty,
				quantity = order_detail.quantity - @shipqty
			where	order_no = @orderno and
				sequence = @sequence

			select	@stdqty = 0
		end -- (3bB)

--	12.	Get next release.

		fetch	releases
		into	@sequence,
			@relstdqty,
			@rowid,
			@odqty
	end -- (2aB)
	close releases
	deallocate releases
	
--	13.	Get next lineitem.

	fetch	lineitems
	into	@part,
		@orderno,
		@stdqty,
		@suffix,
		@ordertype,
		@ourcum,
		@shipqty
end -- (1aB)
close lineitems
deallocate lineitems

--	14.	Declare cursor for shipped orders.

declare orders cursor for
	select distinct shipper_detail.order_no
	from	shipper_detail
		join shipper on shipper_detail.shipper = shipper.id
		join order_header on shipper_detail.order_no = order_header.order_no
	where	shipper_detail.shipper = @shipper and
		shipper.type is null

--	15.	Loop through orders.

open orders

fetch	orders
into	@orderno

while ( @@fetch_status = 0 )
begin -- (1bB)

--	16.	Check order for remaining releases.

	if not exists (
		select	sequence
		from	order_detail
		where	order_no = @orderno )
		update	order_header
		set	status='C'
		where	order_no = @orderno and isnull(order_type,'B') = 'N'
	
	else
--	17.	Resequence remaining releases.

	begin -- (2bB)

--	18.	Initialize new sequence.

		select	@newsequence = 0

--	19.	Mark remaining releases to process.

		update	order_detail
		set	sequence = - sequence
		where	order_no = @orderno

--	20.	Declare cursor for remainingreleases.

		declare remainingreleases insensitive cursor for
			select	sequence
			from	order_detail
			where	order_no = @orderno
			order by part_number,
				due_date

--	21.	Loop through all remaining releases.

		open remainingreleases

		fetch	remainingreleases
		into	@sequence
		
		while ( @@fetch_status = 0 )
		begin -- (3cB)

--	22.	Set new sequence.

			select	@newsequence = @newsequence + 1
			
			update	order_detail
			set	sequence = @newsequence
			where	order_no = @orderno and
				sequence = @sequence

--	23.	Get next remaining release.

			fetch	remainingreleases
			into	@sequence
		end -- (3cB)
		close remainingreleases
		deallocate remainingreleases
	end -- (2bB)

--	24.	Recalculate committed quantity.
	execute msp_calculate_committed_qty @orderno

--	24.	Get next shipped order.

	fetch	orders
	into	@orderno

end -- (1bB)
close orders
deallocate orders

--	25.	Return.
return 0

GO
