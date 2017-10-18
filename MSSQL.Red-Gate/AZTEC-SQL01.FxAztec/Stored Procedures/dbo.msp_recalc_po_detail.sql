SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_recalc_po_detail] ( @po_number integer )
as
begin
	declare @qty_overreceived numeric (20,6),
		@received  	  numeric (20,6),
		@quantity	  numeric (20,6),
		@vendor_code      varchar (10),
		@part_number      varchar (25),
		@row_id           integer,
		@date_due	  datetime,
		@part		  varchar (25),	
		@qty_received     numeric (20,6),	  
		@balance	  numeric (20,6),
		@unit             varchar (2),
		@conversion_qty   numeric (20,6)
	
	/* create temp table to get all po detail rows to be processed */

	create table #mps_po_detail
	( part_number varchar (25),
          vendor_code varchar (10),
	  quantity    numeric (20,6) ,
	  received    numeric (20,6) null,
	  row_id      integer,
	  date_due    datetime,
	  unit		varchar (2) )

	/* create temp table to get all the part in detail */
	
	create table #mps_po_part
	( part_number varchar (25),
	  received    numeric (20,6) )

	/* get the parts to be processed */
	insert into #mps_po_part
	select part_number, sum (received)	
	from po_detail 
	where po_number = @po_number
	group by part_number

	begin transaction

	set rowcount 1

	/* get the first part */
	select @part = part_number,
	       @received = received
	from #mps_po_part
	
	/* loop through while rowcount is greater than zero */
	while @@rowcount > 0 
	begin 	
		set rowcount 0 

		/* get all the rows for the po and part number */
		insert into #mps_po_detail
		select part_number, 
			 vendor_code, 	
			 quantity, 
			 received, 
			 row_id, 
			 date_due, 
			 Unit_of_measure
		from po_detail
		where po_number = @po_number
		and   part_number = @part
		order by date_due 

		set rowcount 1

		select  @part_number = part_number,
			@vendor_code = vendor_code,
		        @quantity    = quantity,
			@row_id     = row_id,
			@date_due   = date_due,
			@unit       = unit
		from #mps_po_detail

		/* get the qty conversion */	
		select @conversion_qty = unit_conversion.conversion  
		from part_unit_conversion, unit_conversion  
		where ( part_unit_conversion.code = unit_conversion.code ) and  
		      ( part_unit_conversion.part = @part_number ) and  
		      ( unit_conversion.unit1 = @unit ) and  
		      ( unit_conversion.unit2 = ( select  standard_unit
						    from  part_inventory  
						   where  part = @Part_number ) ) 

		select @conversion_qty = isnull ( @conversion_qty, 1 ) 

		/* gt over received quantity from part vendor table */
		select @qty_overreceived = qty_over_received
		from part_vendor
		where part = @part
		and   vendor = @vendor_code 

		select @qty_received = isnull ( @received, 0 ) + isnull ( @qty_overreceived, 0 )

		/* loop through all rows for that part in po detail */
		while @@rowcount > 0 and @qty_received > 0
		begin

			set rowcount 0 

			if @quantity > 0 
			begin
				/* assign the received quantities */
				if @qty_received > @quantity    	
				begin
					update	po_detail
					   set	quantity = @quantity,
						received = @quantity,
						balance  = 0,
						standard_qty = 0
					where po_number = @po_number 
					and   part_number = @part_number
					and   row_id      = @row_id
					and   date_due    = @date_due
		
					select	@qty_received = @qty_received - @quantity
					select  @qty_overreceived = @qty_received

				end
				else
				begin
					select @balance = ( @quantity - @qty_received )

					update	po_detail
					   set	quantity = @quantity,
						received = @qty_received,
						balance  = @balance,
						standard_qty = ( @balance * @conversion_qty )
					where po_number = @po_number 
					and   part_number = @part_number
					and   row_id      = @row_id
					and   date_due    = @date_due
	
					select	@qty_received = 0
					select  @qty_overreceived = 0
				end				

			  end

			  set rowcount 0
		
			  delete from #mps_po_detail
				where part_number = @part_number
				and   row_id      = @row_id
				and   date_due    = @date_due
				
			set rowcount 1

			select  @part_number = part_number,
				@vendor_code = vendor_code,
			        @quantity    = quantity,
			        @row_id     = row_id,
			        @date_due   = date_due,
				@unit       = unit
			 from  #mps_po_detail

		end 

		set rowcount 0

		/* update part vendor with remaining quantities */
		update part_vendor
		set qty_over_received = @qty_overreceived
		where part = @part
		and   vendor = @vendor_code 

		/* delete from temp table the part that was already processed */
		delete from #mps_po_part
		where part_number = @part
		
		set rowcount 1

		select 	@part = part_number,
	       		@received = received
		from #mps_po_part

	end 

	/* delete rows which are marked for deletion and and balance is zero */
	delete from po_detail
	where  deleted = 'Y' OR balance <= 0 

	commit transaction

	exec msp_update_po_qty_assigned @po_number	

	/* return value 1 */
	select 1 

	drop table #mps_po_detail	

end
GO
