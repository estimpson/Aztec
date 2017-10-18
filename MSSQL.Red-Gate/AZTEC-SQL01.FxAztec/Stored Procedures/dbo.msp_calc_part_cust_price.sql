SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calc_part_cust_price] ( @part varchar (25), @customer varchar (10), @quantity numeric (20,6 ) )
as
begin -- (1A)
-----------------------------------------------------------------------------------------
--	
--
--
--
--
--	mb 03/03/99 
-----------------------------------------------------------------------------------------
	declare @dec_std_price numeric (20,6),
		@premium varchar (1),
		@category varchar (25),
		@currency varchar (3),
		@price_type varchar (1),
		@dec_price numeric (20,6),
		@dec_markup numeric (20,6),
		@dec_premium numeric (20,6),
		@dec_qty_break numeric (20,6),
		@multiplier varchar (1)	

	SELECT	@dec_std_price = ps.price, 
		@premium = ps.premium,
		@category = c.category,
		@currency = c.default_currency_unit,
		@price_type = pc.type
	FROM 	part_standard ps, customer c, part_customer  pc
	WHERE 	ps.part = @part   AND 
		c.customer = @customer AND
		ps.part = pc.part AND 
		pc.customer = c.customer

	if ( isnull ( @price_type , '' ) = '' and isnull ( @category, '' ) = '' )
		return @dec_std_price

	if  @price_type = 'D' 
		SELECT 	@dec_price = price
		FROM 	part_customer_price_matrix as a, part_customer as b
		WHERE 	( a.part = b.part ) AND
			( a.customer = b.customer ) AND
			( a.part = @part ) AND  
			( a.customer = @customer ) 
	else if @price_type = 'C' 
	begin
		SELECT	@dec_markup = markup,
			@multiplier = multiplier,
			@dec_premium = premium
		FROM	category
		WHERE	code = @category 
	
		if @@rowcount <= 0 
			return @dec_std_price
		
		if @premium  <> 'Y' 
			select @dec_premium = 0
	
		if @multiplier = '+'
			select @dec_price = @dec_std_price + @dec_markup + @dec_premium
		else if @multiplier = '-' 
			select @dec_price = @dec_std_price - @dec_markup + @dec_premium
		else if @multiplier = '%' 
			select @dec_price = @dec_std_price + ( @dec_std_price * @dec_markup ) + @dec_premium
		else if @multiplier = 'x'
			select @dec_price = @dec_std_price * @dec_markup + @dec_premium 
	end
	else if @price_type = 'B' 
	begin
		SELECT @dec_qty_break = max(qty_break)
		  FROM part_customer_price_matrix  
		 WHERE ( part = @part ) AND  
		       ( customer = @customer ) AND  
		       ( qty_break <= @quantity ) 
			 
		if @dec_qty_break > 0
			SELECT 	@dec_price = price
			FROM 	part_customer_price_matrix  
			WHERE 	part = @part AND 
				customer = @customer AND  
				qty_break = @dec_qty_break   
		else
			return @dec_std_price
	end
	if isnull ( @dec_price, 0 ) = 0 
		select @dec_price = @dec_std_price
	
	return @dec_price
end -- (1A)
GO
