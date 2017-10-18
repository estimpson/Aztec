SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_changedescription] (@part varchar(25), @partdescription varchar(100))
as
begin
--	part_name,shipper_detail
--	part_name,part_vendor
--	description,po_detail
--	description,po_header
--	name,object
--	product_name,quote_detail
--	product_name,order_detail
--	product_name,order_detail_inserted
--	name,part

	begin transaction

	--	Update shipper detail with new part description on open shippers
	update	shipper_detail
	set	part_name = @partdescription
	from	shipper_detail
		join shipper on shipper.id = shipper_detail.shipper
	where	shipper_detail.part_original = @part and
		isnull(shipper.status,'O') in ('O', 'S')
		
	--	update part_vendor with new part description 
	update	part_vendor
	set	part_name = @partdescription
	where	part = @part
	
	--	Update po detail with new part description on open POs
	update	po_detail
	set	description = @partdescription
	from	po_detail
		join po_header on po_header.po_number = po_detail.po_number
	where	po_detail.part_number = @part and
		isnull(po_header.status,'A') = 'A'

	--	Update po header with new part description on open POs
	update	po_header
	set	description = @partdescription
	where	po_header.blanket_part = @part and
		isnull(po_header.status,'A') = 'A'

	--	Update object with new part description on active objects
	update	object
	set	name = @partdescription
	from	object
	where	object.part = @part and
		isnull(object.status,'A') = 'A'

	--	Update shipper detail with new part description on open shippers
	update	quote_detail
	set	product_name = @partdescription
	from	quote_detail
		join quote on quote.quote_number = quote_detail.quote_number
	where	quote_detail.part = @part and
		isnull(quote.status,'O') = 'O'

	--	Update shipper detail with new part description on open shippers
	update	order_detail
	set	product_name = @partdescription
	from	order_detail
		join order_header on order_header.order_no = order_detail.order_no
	where	order_detail.part_number = @part and
		isnull(order_header.status,'O') = 'O'

	--	Update shipper detail with new part description on open shippers
	update	order_detail_inserted
	set	product_name = @partdescription
	from	order_detail_inserted
		join order_header_inserted on order_header_inserted.order_no= order_detail_inserted.order_no
	where	order_detail_inserted.part_number = @part and
		isnull(order_header_inserted.status,'O') = 'O'

	--	Update object with new part description on active objects
	update	part
	set	name = @partdescription
	from	part
	where	part.part = @part
	
	commit transaction
end
GO
