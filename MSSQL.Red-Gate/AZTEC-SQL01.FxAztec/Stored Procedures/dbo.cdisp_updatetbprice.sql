SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_updatetbprice] as
begin
	declare	@cnt integer,
		@part	varchar(25),
		@customer varchar(10),
		@price	numeric(20,6)
	
	--	Count if any enteries are there for today
	select	@cnt = count(1)
	from	part_customer_tbp
	where	convert(varchar(10), effect_date,101) = convert(varchar(10), getdate(),101)
	
	if isnull(@cnt,0) > 0 
	begin
		begin tran
		--	Declare a cursor for the records from tbp table
		declare tbpcursor cursor for
		select	tbp.part, tbp.customer, tbp.price
		from	part_customer_tbp tbp
			join part_eecustom as p on p.part = tbp.part
		where	convert(varchar(10), tbp.effect_date,101) = convert(varchar(10), getdate(),101) and
			isnull(p.tb_pricing,'0') = '1' 
		
		--	Open cursor
		open	tbpcursor
		
		--	fetch data
		fetch	tbpcursor into @part, @customer, @price
		
		while @@fetch_status = 0 
		begin
			--	Update sales order header
			update	order_header
			set	alternate_price = @price
			where	customer = @customer and 
				blanket_part = @part and
				isnull(status,'O') = 'O'

			--	Update sales order detail
			update	order_detail
			set	order_detail.alternate_price = @price
			from	order_detail
				join order_header on order_header.order_no = order_detail.order_no 
			where	order_detail.part_number = @part and
				order_header.customer = @customer and 
				isnull(order_header.status,'O') = 'O'

			--	Update part standard
			update	part_standard
			set	price = @price
			where	part = @part				

			--	Update part customer
			update	part_customer
			set	blanket_price = @price
			where	part = @part and
				customer = @customer

			--	Update part customer_price_matrix
			update	part_customer_price_matrix
			set	alternate_price = @price
			where	part = @part and
				customer = @customer and
				qty_break = 1

			--	fetch data
			fetch	tbpcursor into @part, @customer, @price
		end
		
		--	Close cursor
		close	tbpcursor
		deallocate tbpcursor
		
		commit tran
	end
end
GO
