SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_gssreport_enhanced] (@destination varchar(10), @mode char(1)=null) as
begin 	
	declare	@part	varchar(25),
		@due	datetime,
		@qty	decimal(20,6),
		@committedqty	decimal(20,6),
		@orderno	numeric(8,0),
		@onhand	decimal(20,6),
		@cpart	varchar(30),
		@customerpo	varchar(30),
		@modelyear	varchar(10),
		@stdate		datetime,
		@rpdue	numeric(20,6),
		@rday1		numeric(20,6),
		@rday2		numeric(20,6),
		@rday3		numeric(20,6),
		@rday4		numeric(20,6),
		@rday5		numeric(20,6),
		@rday6		numeric(20,6),
		@cpdue	numeric(20,6),
		@cday1		numeric(20,6),
		@cday2		numeric(20,6),
		@cday3		numeric(20,6),
		@cday4		numeric(20,6),
		@cday5		numeric(20,6),
		@cday6		numeric(20,6),
		@cnt		integer,
		@sdtstamp	varchar(10),
		@qtyreq		numeric(20,6),
		@multiplier	smallint
		
	create table #ordtemp (
		destination	varchar(10),
		part		varchar(25),
		cpart		varchar(30),
		customerpo	varchar(30),
		modelyear	varchar(10),
		onhand		numeric(20,6),
		rpdue	numeric(20,6),
		rday1		numeric(20,6),
		rday2		numeric(20,6),
		rday3		numeric(20,6),
		rday4		numeric(20,6),
		rday5		numeric(20,6),
		rday6		numeric(20,6),
		cpdue	numeric(20,6),
		cday1		numeric(20,6),
		cday2		numeric(20,6),
		cday3		numeric(20,6),
		cday4		numeric(20,6),
		cday5		numeric(20,6),
		cday6		numeric(20,6))

	select	@stdate = getdate()
	
	If @mode is null
		select	@mode = 'D'
		
	select	@multiplier = 1
	
	if @mode = 'W' or @mode = 'w'
		select	@multiplier = 7
		
	declare	ord_cursor cursor for 
	select	oh.destination,
		od.order_no,
		od.part_number,
		od.due_date, 
		od.customer_part,
		isnull(oh.customer_po,''),
		isnull(oh.model_year,''),
		isnull(sum(od.quantity),0) quantity
	from	order_detail od
		join order_header oh on oh.order_no = od.order_no 
	where	oh.destination = @destination and 
		isnull(oh.status,'O') = 'O' and
		od.due_date < dateadd(dd,(6 * @multiplier),@stdate)
	group by oh.destination, od.order_no, od.part_number, od.due_date, od.customer_part, 
		oh.customer_po, oh.model_year
	order by 1,2,3

	open	ord_cursor
	fetch	ord_cursor into @destination, @orderno, @part, @due, @cpart, @customerpo, @modelyear, @qty
	
	while	(@@fetch_status=0) 
	begin
	
		select	@rpdue=0, @rday1=0, @rday2=0, @rday3=0, @rday4=0, @rday5=0, @rday6=0,
			@cpdue=0, @cday1=0, @cday2=0, @cday3=0, @cday4=0, @cday5=0, @cday6=0,
			@onhand=0, @cnt=0

		select	@onhand = isnull(sum(quantity),0)
		from	object
		where	part = @part and status = 'A'
		
		if @mode = 'D'
			select	@rpdue	= (case when convert(varchar(10), @due, 111) < convert(varchar(10), @stdate,111) then isnull(@qty,0) else 0 end),
				@rday1	= (case	when convert(varchar(10), @due, 111) = convert(varchar(10), @stdate,111) then isnull(@qty,0)else 0 end),
				@rday2	= (case	when convert(varchar(10), @due, 111) = convert(varchar(10), dateadd(dd,(1 * @multiplier),@stdate),111) then isnull(@qty,0) else 0 end),
				@rday3	= (case	when convert(varchar(10), @due, 111) = convert(varchar(10), dateadd(dd,(2 * @multiplier),@stdate),111) then isnull(@qty,0) else 0 end),
				@rday4	= (case when convert(varchar(10), @due, 111) = convert(varchar(10), dateadd(dd,(3 * @multiplier),@stdate),111) then isnull(@qty,0) else 0 end),
				@rday5	= (case when convert(varchar(10), @due, 111) = convert(varchar(10), dateadd(dd,(4 * @multiplier),@stdate),111) then isnull(@qty,0) else 0 end),
				@rday6	= (case when convert(varchar(10), @due, 111) = convert(varchar(10), dateadd(dd,(5 * @multiplier),@stdate),111) then isnull(@qty,0) else 0 end)
		else
			if datepart(wk,@due) < datepart(wk, @stdate) 
				select	@rpdue = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, @stdate) 
				select	@rday1 = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, dateadd(dd,(1 * @multiplier),@stdate))
				select	@rday2 = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, dateadd(dd,(2 * @multiplier),@stdate))
				select	@rday3 = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, dateadd(dd,(3 * @multiplier),@stdate))
				select	@rday4 = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, dateadd(dd,(4 * @multiplier),@stdate))
				select	@rday5 = isnull(@qty,0)
			else if datepart(wk,@due) = datepart(wk, dateadd(dd,(5 * @multiplier),@stdate))
				select	@rday6 = isnull(@qty,0)						

		declare sd_cursor cursor for
		select	convert(varchar(10),date_stamp,111), 
			qty_required
		from	shipper_detail
			join shipper on shipper.id = shipper_detail.shipper
		where	order_no=@orderno and
			part=@part and
			shipper.type is null and
			(status='O' or status='A' or status='S')
		
		open	sd_cursor
		fetch	sd_cursor into @sdtstamp, @qtyreq
		
		while	(@@fetch_status=0)
		begin
			if @mode = 'D'
				select	@cpdue = @cpdue + (case when @sdtstamp < convert(varchar(10), @stdate,111) then @qtyreq else 0 end),
					@cday1 = @cday1 + (case when @sdtstamp = convert(varchar(10), @stdate,111) then @qtyreq else 0 end),
					@cday2 = @cday2 + (case when @sdtstamp = convert(varchar(10), dateadd(dd,(1 * @multiplier),@stdate),111) then @qtyreq else 0 end),
					@cday3 = @cday3 + (case when @sdtstamp = convert(varchar(10), dateadd(dd,(2 * @multiplier),@stdate),111) then @qtyreq else 0 end),
					@cday4 = @cday4 + (case when @sdtstamp = convert(varchar(10), dateadd(dd,(3 * @multiplier),@stdate),111) then @qtyreq else 0 end),
					@cday5 = @cday5 + (case when @sdtstamp = convert(varchar(10), dateadd(dd,(4 * @multiplier),@stdate),111) then @qtyreq else 0 end),
					@cday6 = @cday6 + (case when @sdtstamp = convert(varchar(10), dateadd(dd,(5 * @multiplier),@stdate),111) then @qtyreq else 0 end)
			else		
				if datepart(wk,@sdtstamp) < datepart(wk, @stdate) 
					select	@cpdue = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, @stdate) 
					select	@cday1 = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, dateadd(dd,(1 * @multiplier),@stdate)) 	
					select	@cday2 = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, dateadd(dd,(2 * @multiplier),@stdate)) 	
					select	@cday3 = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, dateadd(dd,(3 * @multiplier),@stdate)) 	
					select	@cday4 = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, dateadd(dd,(4 * @multiplier),@stdate)) 	
					select	@cday5 = isnull(@qtyreq,0)
				else if datepart(wk,@sdtstamp) = datepart(wk, dateadd(dd,(5 * @multiplier),@stdate)) 	
					select	@cday6 = isnull(@qtyreq,0)
		
			fetch	sd_cursor into @sdtstamp, @qtyreq		
		end
		close	sd_cursor
		deallocate sd_cursor
		
		select	@cnt = isnull(count(1),0)
		from	#ordtemp
		where	destination = @destination and
			part	= @part and
			customerpo = @customerpo and
			modelyear = @modelyear
	
		if isnull(@cnt,0)=0 
		begin
			insert	into #ordtemp 
			values	(@destination, @part, @cpart, @customerpo, @modelyear, @onhand,
				@rpdue, @rday1, @rday2, @rday3, @rday4, @rday5, @rday6,
				@cpdue, @cday1, @cday2, @cday3, @cday4, @cday5, @cday6)
		end
		else
		begin
			update	#ordtemp
			set	rpdue	= rpdue + @rpdue,
				rday1	= rday1 + @rday1,
				rday2	= rday2 + @rday2,
				rday3	= rday3 + @rday3,
				rday4	= rday4 + @rday4,
				rday5	= rday5 + @rday5,
				rday6	= rday6 + @rday6,
				cpdue 	= @cpdue,
				cday1	= @cday1,
				cday2	= @cday2,
				cday3	= @cday3,
				cday4	= @cday4,
				cday5	= @cday5,
				cday6	= @cday6
			where	destination = @destination and
				part	= @part and
				customerpo = @customerpo and
				modelyear = @modelyear
		end
		
		fetch	ord_cursor into @destination, @orderno, @part, @due, @cpart, @customerpo, @modelyear, @qty			
	end 
	close	ord_cursor
	deallocate ord_cursor
	
	select	destination, part, cpart, customerpo, modelyear, onhand,
		rpdue, rday1, rday2, rday3, rday4, rday5, rday6,
		cpdue, cday1, cday2, cday3, cday4, cday5, cday6,
		(rpdue - cpdue) dpdue, (rday1 - cday1) dday1, 
		(rday2 - cday2) dday2, (rday3 - cday3) dday3, (rday4 - cday4) dday4, 
		(rday5 - cday5) dday5, (rday6 - cday6) dday6,
		company_name, company_logo		
	from	#ordtemp
		cross join parameters
	order	by 1, 2, 4
end
GO
