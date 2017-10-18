SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_create_shipper_detail] ( @shipper integer, @serial integer )
as
begin -- (1A)
-------------------------------------------------------------------------------------------
--	stored procedure to create shipper detail.
--      arguments : 	@shipper integer
--			@serial  integer	
--
--
--	Original :MB 03/03/99 
--	Modified :MB 04/30/99  
-------------------------------------------------------------------------------------------
--	declare local variables
	declare @salesman varchar (25), 
		@qty_packed numeric (20,6 ), 
		@std_qty_converted numeric (20,6), 
		@std_qty_packed numeric (20,6),
		@std_price numeric (20,6),
		@part varchar (25),
		@quantity numeric (20,6),
		@customer varchar (10),
		@unit  varchar (10),
		@type  varchar (1)

--	create temp table to hold all values for objects on pallet
	create table #boxes_on_pallet 
	( serial integer,
	  part	 varchar(25),
	  quantity decimal (20,6),
	  unit_measure varchar (10),
	  salesman varchar (25) null,
	  customer varchar (10) null,
	  std_qty_converted decimal (20,6),
	  std_price decimal (20,6) null,
	  shipper integer )

-- 	begin insert transaction
	begin transaction

--	get values from object table to temp table
	insert into #boxes_on_pallet 
	select 	serial,
		part,	
		quantity, 
		unit_measure, 
		'',
		'', 
		0, 
		null,
		@shipper 
	 from object 
	 where serial = @serial and object.type is null or parent_serial = @serial 

--	get salesman for that customer
	update #boxes_on_pallet 
	set salesman = (select customer.salesrep
			  FROM customer, shipper  
			 WHERE shipper.customer = customer.customer AND
			       #boxes_on_pallet.shipper = shipper.id  AND
			       shipper.id = @shipper ),
	    customer = (select shipper.customer
			  FROM customer, shipper  
			 WHERE shipper.customer = customer.customer AND
			       #boxes_on_pallet.shipper = shipper.id  AND
			       shipper.id = @shipper )
	where #boxes_on_pallet.shipper = @shipper 

--	get the std pack qty for that part and unit
	update #boxes_on_pallet 
	set std_qty_converted = isnull ( ( SELECT unit_conversion.conversion
				    FROM part_unit_conversion,   
			        	 unit_conversion  
				   WHERE ( part_unit_conversion.code = unit_conversion.code ) and  
			        	 ( part_unit_conversion.part = #boxes_on_pallet.part ) AND  
				         ( unit_conversion.unit1 = #boxes_on_pallet.unit_measure ) AND  
			        	 ( unit_conversion.unit2 = (select standard_unit 
								    from part_inventory 	
								    where part = #boxes_on_pallet.part )) ), 0 )

--	get price for that part

	set rowcount 1 

	select  @part = part,
		@customer = customer,
		@quantity = quantity
	from   #boxes_on_pallet 
	where  std_price is null 

	while @part > ''
	begin
		exec @std_price =  msp_calc_part_cust_price @part, @customer, @quantity 
		
		update #boxes_on_pallet
		set std_price = @std_price
		where part = @part
		and   customer = @customer 
		and   quantity = @quantity

		select @part = null

		set rowcount 1 

		select  @part = part,
			@customer = customer,
			@quantity = quantity
		from   #boxes_on_pallet 
		where  std_price is null 

	end
	
--	insert row into shipper_detail table 
	insert into shipper_detail 
	(  shipper,   
           part,   
           qty_required,   
           qty_packed,   
           qty_original,   
           accum_shipped,   
           order_no,   
           customer_po,   
           release_no,   
           release_date,   
           type,   
           price,   
           account_code,   
           salesman,   
           tare_weight,   
           gross_weight,   
           net_weight,   
           date_shipped,   
           assigned,   
           packaging_job,   
           note,   
           operator,   
           boxes_staged,   
           pack_line_qty,   
           alternative_qty,   
           alternative_unit,   
           week_no,   
           taxable,   
           price_type,   
           cross_reference,   
           customer_part,   
           dropship_po,   
           dropship_po_row_id,   
           dropship_oe_row_id,
	   part_name,
	   part_original,
	   alternate_price)  
	select @shipper,
	       #boxes_on_pallet.part,
	       #boxes_on_pallet.quantity,
		 ( isnull( #boxes_on_pallet. std_qty_converted, 1 ) * #boxes_on_pallet.quantity) ,
		 #boxes_on_pallet.quantity,
	         null,   
        	 0,   
	         null,   
        	 null,   
	         null,   
        	 null,   
		 #boxes_on_pallet.std_price, 
		 ( case when part.class = 'M' then ( select part_mfg.gl_account_code
						     from part_mfg
						     where part_mfg.part = #boxes_on_pallet.part ) else 
						(select part_purchasing.gl_account_code  
						 from part_purchasing 
						where part_purchasing.part = #boxes_on_pallet.part ) end ),
		 #boxes_on_pallet.salesman,
		 0,
		 0,
		 0,
	         null,   
        	 null,   
	         null,   
		 null,
	         null,   
        	 1,   
	         null,   
        	 #boxes_on_pallet.quantity,
	         #boxes_on_pallet.unit_measure,
	         null,   
        	 null,   
	         null,   
        	 null,   
	         part.cross_ref,   
        	 null,   
	         null,   
        	 null,
		 part.name,
		 #boxes_on_pallet.part,
		 #boxes_on_pallet.std_price 
	  from #boxes_on_pallet, part 
	  where serial  = #boxes_on_pallet.serial 
	  and #boxes_on_pallet.part = part.part 

	commit transaction	

	drop table #boxes_on_pallet	 

end
GO
