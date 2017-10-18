SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_po_qty_assigned] (@po_number integer) as

declare		@part_number                    varchar(25),
		@part_mps			varchar(25),
		@part_assign			varchar(25),
		@std_qty                        numeric(20,6),
		@due_date                       datetime,
		@due	                        datetime,
		@order_no                       numeric(8,0),
		@row_id                         int,
		@origin                         numeric(8,0),
		@source                         int,
		@plant                          varchar(10),
		@qnty				numeric(20,6),
		@qty_left			numeric(20,6),
		@assign_qty			numeric(20,6),
		@id				numeric(12,0)

	create table #mps_po_part ( 
		part				varchar(25),
		plant				varchar(10) null,
		quantity			numeric(20,6) null)

	create table #mps_temp (
		part				varchar(25),
		plant				varchar(10) null)

	create table #mps_assign (
		part				varchar(25),
		due				datetime,
		source				int,
		origin				numeric(8,0),
		qnty				numeric(20,6),
		id				numeric(12,0) )

	begin transaction

	insert into #mps_po_part
	select	max (part_number),
		max (plant),			/* get po detail record */
		sum(standard_qty)
	  from	po_detail
	where   po_number = @po_number
	group by part_number, plant

	set rowcount 1				/* setup poor man's cursor */

	select	@part_number = part,		/* get po detail record */ 		
		@plant = plant,
		@std_qty = quantity
	  from	#mps_po_part

	while @@rowcount > 0 
	begin 

		set rowcount 0

		insert	#mps_temp  	        /* get distinct mps plant,parts */
		select	part, plant
		  from	master_prod_sched
		where   part = @part_number
		group by part, plant
		order by part

		set rowcount 1

		select @part_mps = part
		from #mps_temp

		while @@rowcount > 0 
		begin

			set rowcount 0

			update master_prod_sched 
			set qty_assigned = 0
			where part = @part_mps

			select @assign_qty = sum ( standard_qty )
			from po_detail
			where part_number = @part_mps
			and  status <> 'C'

						/* get po and wo qty w/ null plant */
			insert	#mps_assign (part, due, source, origin, qnty, id)
			select	part, due, source, origin, qnty, id
			  from	master_prod_sched
			 where	part = @part_mps
			order by due

			set rowcount 1

		 	select 	@due = due, 
			       	@source = source, 
			       	@origin = origin, 
				@qnty = qnty,
				@id = id
			  from	master_prod_sched
			where   part =@part_mps
			  order by due		

			select @qty_left = @assign_qty

			while ( @@rowcount > 0 )  and ( @qty_left > 0 )
			begin

				set rowcount 0

				if @qty_left > @qnty	/* assign qty from oldest to newest */
				begin
					update	master_prod_sched
					   set	qty_assigned = @qnty
					 where	part = @part_mps
					   and	source = @source
				   	   and	origin = @origin
				   	   and	due = @due
					   and  id = @id
	
					select	@qty_left = @qty_left - @qnty
				end
				else
				begin
					update	master_prod_sched
					   set	qty_assigned = @qty_left
					 where	part = @part_mps
					   and	source = @source
				   	   and	origin = @origin
				   	   and	due = @due
					   and  id = @id

					select	@qty_left = 0
				end				

				set rowcount 1

				delete  from #mps_assign
				 where	part = @part_mps
				   and	source = @source
				   and	origin = @origin
				   and	due = @due
				   and  id = @id

				select	@due = due,		/* get next mps plant, part */
					@source = source,
					@origin = origin,
					@qnty = qnty,
					@id   = id
				  from	#mps_assign
				 where	part = @part_mps
			      order by	due
				
			end

			set rowcount 0

			delete  from #mps_assign
	
			select	@assign_qty = 0

			set rowcount 0

			delete  from #mps_temp

			set rowcount 1

			select @part_mps = part
			from #mps_temp

		end 
		
		set rowcount 0	  

		delete from #mps_po_part
		where part = @part_number

		set rowcount 1					/* setup poor man's cursor */
	
		select	@part_number = part,			/* get po detail record */
			@plant = plant,
			@std_qty = quantity
		  from	#mps_po_part

	end 

	commit transaction					/* commit transaction */

	drop table #mps_temp					/* clean-up */
	drop table #mps_assign 
	drop table #mps_po_part
GO
