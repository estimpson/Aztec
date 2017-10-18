SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_customer_scorecard] (	@customer varchar(25) )
as
begin
--	GPH 12/26/00 Modified the select statement on open orders as it was summing up wrongly.
--	GPH 03/10/01 Include a select statement to get the time portion of the datetime column
--			on both start and end datetime columns
--	GPH 12/21/01 Included table prefix on status column on couple of select statement


	declare	@start_date		datetime,
		@end_date		datetime,
		@quote_count		integer,
		@quote_amount		decimal(20,6),
		@order_count		integer,
		@order_amount		decimal(20,6),
		@shipsched_count	integer,
		@shipsched_amount	decimal(20,6),
		@shiphist_count		integer,
		@shiphist_amount	decimal(20,6),
		@issues_count		integer,
		@pastdue_count		integer,
		@pastdue_amount		decimal(20,6),
		@return_count		integer,
		@return_amount		decimal(20,6),
		@closure_rate		decimal(20,6),
		@closure_right		decimal(20,6),
		@closure_left		decimal(20,6),
		@ontime_rate		decimal(20,6),
		@ontime_right		decimal(20,6),
		@ontime_left		decimal(20,6),
		@return_rate		decimal(20,6),
		@return_right		decimal(20,6),
		@return_left		decimal(20,6),
		@order_blanket_amount	decimal(20,6),
		@order_normal_amount	decimal(20,6)
		
	if ( select count(customer) from customer_additional where customer = @customer ) < 1
		insert into customer_additional ( customer, type ) values ( @customer, ' ' )
		
	select	@start_date = isnull(start_date,dateadd ( yy, -5, GetDate ( ) ) ),
		@end_date = isnull(end_date,dateadd ( yy, 5, GetDate ( ) ) )
	from	customer_additional
	where	customer = @customer
	
	select	@start_date = convert(datetime, (convert(varchar,datepart(yy,@start_date))+'/'+convert(varchar,datepart(mm,@start_date))+'/'+convert(varchar,datepart(dd,@start_date))+' 00:00:01')),
 		@end_date = convert(datetime, (convert(varchar,datepart(yy,@end_date))+'/'+convert(varchar,datepart(mm,@end_date))+'/'+convert(varchar,datepart(dd,@end_date))+' 23:59:59'))
	
	-- Get the # and $ of quotes for this customer
	select	@quote_count = count(q.quote_number)
	from	quote q
	where 	q.status <> 'C' and 
		q.customer = @customer and 
		q.quote_date >= @start_date and 
		q.quote_date <= @end_date
				
	if @quote_count > 0
		select	@quote_amount = sum(qd.quantity * qd.price)
		from	quote q,
			quote_detail qd
		where 	q.quote_number = qd.quote_number and
			q.status <> 'C' and 
			q.customer = @customer and 
			q.quote_date >= @start_date and 
			q.quote_date <= @end_date
	else
		select @quote_amount = 0
				
	-- Get the # and $ of orders for this customer
	select	@order_count = count(order_no) 
	from 	order_header 
	where 	isnull(order_header.status,'') <> 'C' and 
		customer = @customer and 
		order_date >= @start_date and 
		order_date <= @end_date
	
	if @order_count > 0
		select	@order_amount = sum(IsNull(od.alternate_price,0) * isnull(od.quantity,0))
		from	order_header oh,
			order_detail od
		where 	oh.order_no = od.order_no and
			isnull(oh.status,'') <> 'C' and 
			oh.customer = @customer and 
			oh.order_date >= @start_date and 
			oh.order_date <= @end_date
	else
		select @order_amount = 0
				
	
	-- Get the # and $ of ship schedules for this customer
	select	@shipsched_count = count(s.id)
	from	shipper s
	where	( s.status = 'O' or s.status = 'S' ) and 
		( s.type='O' or s.type='Q' or s.type='V' or s.type is null ) and 
		s.customer = @customer and 
		s.date_stamp >= @start_date and 
		s.date_stamp <= @end_date
	
	if @shipsched_count > 0
		select	@shipsched_amount = isnull(sum(IsNull ( sd.price, 0 ) * IsNull(sd.qty_packed,0)),0)
		from	shipper s,
			shipper_detail sd
		where	s.id = sd.shipper and
			( s.status = 'O' or s.status = 'S' ) and 
			( s.type='O' or s.type='Q' or s.type='V' or s.type is null ) and 
			s.customer = @customer and 
			s.date_stamp >= @start_date and 
			s.date_stamp <= @end_date
	else
		select @shipsched_amount = 0
	
	-- Get the # of ship histories for this customer
	select	@shiphist_count = count(s.id)
	from	shipper s
	where 	( s.status = 'C' or s.status = 'Z' ) and 
		( s.type='O' or s.type='Q' or s.type='V' or s.type is null ) and 
		s.customer = @customer  and 
		s.date_shipped >= @start_date and 
		s.date_shipped <= @end_date
				
	if @shiphist_count > 0
		select	@shiphist_amount = isnull(sum(IsNull(sd.price,0)*IsNull(sd.qty_packed,0)),0)
		from	shipper s,
			shipper_detail sd
		where 	s.id = sd.shipper and
			( s.status = 'C' or s.status = 'Z' ) and 
			( s.type='O' or s.type='Q' or s.type='V' or s.type is null ) and 
			s.customer = @customer  and 
			s.date_shipped >= @start_date and 
			s.date_shipped <= @end_date
	else
		select @shiphist_amount = 0
	
	-- Issues will go here
	select	@issues_count = count(issue_number)
	from	cs_issues_vw
	where	origin = @customer and
		type = 'O' and
		start_date >= @start_date and start_date <= @end_date
	
	
	-- Get the # of past due orders
	select	@pastdue_count = count(order_no) 
	from 	order_header 
	where 	datediff(day,(select min(due_date) from order_detail where order_detail.order_no = order_header.order_no),GetDate()) > 0 and 
		isnull(order_header.status,'') <> 'C' and 
		customer = @customer and 
		order_date >= @start_date and 
		order_date <= @end_date
	
	if @pastdue_count > 0
		select	@pastdue_amount = sum(IsNull ( od.alternate_price, 0 ) * isnull(od.quantity,0))
		from	order_header oh,
			order_detail od
		where 	oh.order_no = od.order_no and
			datediff(day,(select min(due_date) from order_detail where order_detail.order_no = oh.order_no),GetDate()) > 0 and 
			isnull(oh.status,'') <> 'C' and 
			customer = @customer and 
			order_date >= @start_date and 
			order_date <= @end_date
	else
		select @pastdue_amount = 0
	
	
	-- Get the # and $ of returns for this customer
	select	@return_count = count(customer)
	from	cs_returns_vw
	where 	cs_returns_vw.status <> 'C' and 
		customer = @customer and 
		date_stamp >= @start_date and 
		date_stamp <= @end_date
	
	if @return_count > 0
		select	@return_count = count(customer),
			@return_amount = isnull(sum(IsNull(qty_packed,0) * IsNull(price,0)),0)
		from	cs_rma_detail_vw
				join cs_returns_vw on id = shipper
		where	cs_returns_vw.status <> 'C' and 
			rmacustomer=@customer and
			customer = @customer and 
			date_stamp >= @start_date and 
			date_stamp <= @end_date
	else
		select @return_count = 0
			
	-- Get the closure rate for the date range given
	select	@closure_left = count(quote_number) 
	from	quote 
	where 	quote.status <> 'C' and 
		customer = @customer and 
		quote_date >= @start_date and 
		quote_date <= @end_date
	
	select	@closure_right = count(quote_number) 
	from	quote 
	where 	customer = @customer and 
		quote_date >= @start_date and 
		quote_date <= @end_date
	
	if @closure_right = 0
		select @closure_right = 1
		
	select @closure_rate = isnull(@closure_left,0) / isnull(@closure_right,1)
	
	
	-- Get the on-time delivery rating for the date range given
	select	@ontime_left = count(id) 
	from	shipper 
	where 	date_shipped is null and 
		customer = @customer and 
		date_stamp >= @start_date and 
		date_stamp <= @end_date
	
	select 	@ontime_right = count(id) 
	from	shipper 
	where 	customer = @customer and 
		date_stamp >= @start_date and 
		date_stamp <= @end_date
				
	if @ontime_right = 0
		select @ontime_right = 1
		
	select @ontime_rate = isnull(@ontime_left,0) / isnull(@ontime_right,1)
	
	
	-- Get the return rating for the date range given
	select	@return_left = sum(IsNull(qty_packed,0))
	from	cs_rma_detail_vw
			join cs_returns_vw on id = shipper
	where 	cs_returns_vw.status <> 'C' and 
		customer = @customer and 
		rmacustomer = @customer and 
		date_stamp >= @start_date and 
		date_stamp <= @end_date
	
	select	@return_right = sum(IsNull(sd.qty_packed,0)) 
	from	shipper s, 
		shipper_detail sd 
	where 	s.id = sd.shipper and 
		s.customer = @customer and 
		s.date_shipped >= @start_date and 
		s.date_shipped <= @end_date
				
	if @return_right = 0
		select @return_right = 1
		
	select @return_rate = isnull(@return_left,0) / isnull(@return_right,1)
	
	
	select	@quote_count,
		@quote_amount,
		@order_count,
		@order_amount,
		@shipsched_count,
		@shipsched_amount,
		@shiphist_count,
		@shiphist_amount,
		@issues_count,
		@pastdue_count,
		@pastdue_amount,
		@return_count,
		@return_amount,
		@closure_rate,
		@ontime_rate,
		@return_rate,
		@start_date,
		@end_date,
		@customer
		
end
GO
