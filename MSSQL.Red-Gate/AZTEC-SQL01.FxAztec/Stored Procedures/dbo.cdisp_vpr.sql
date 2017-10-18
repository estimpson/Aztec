SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_vpr] (@stdate datetime, @eddate datetime=null) as
begin
--	Declarations
	declare	@ponumber integer,
		@vendor	varchar(10),	
		@part	varchar(25),
		@due	datetime,
		@qty	decimal(20,6),
		@qtyrec	decimal(20,6),
		@recdt	datetime,
		@sad	integer,
		@ra	integer,
		@sadpag	integer,
		@rapag	integer,		
		@psad	integer,
		@pra	integer,
		@vrating integer,
		@vpoints integer,		
		@rating	varchar(25),
		@relcontrol char(1),
		@tcount	smallint,
		@racount smallint,
		@sacount smallint

--	Temp table creation		
	create table #vprdata
		(vendor	varchar(10),
		part	varchar(25),		
		due	datetime,
		qty	decimal(20,6),
		recdt	datetime,
		qtyrec	decimal(20,6),
		sad	integer,
		ra	integer,		
		psad	integer,
		pra	integer,
		vrating	smallint,
		rating	varchar(25),
		ponumber integer)

--	Another temp table required in the process
	create table #recdata	
		(lastrecvddate datetime,
		raccuracy char(1))	
		
--	Validate enddate		
	if @eddate is null
		select	@eddate = getdate()	

--	Arrive at the proper datetime for both start and time 
	select	@stdate = convert(datetime, (convert(varchar(10),@stdate,111) + ' 00:00:00')),
		@eddate = convert(datetime, (convert(varchar(10),@eddate,111) + ' 23:23:59'))

--	Declare a cursor to extract data for the specified date range	
	declare vprcursor cursor for
	select	distinct b.vendor,
		b.po_number, 
		b.part, 
		b.date_due,
		b.quantity,
		poh.release_control
	from	cdipohistory b 
		join po_header poh on poh.po_number = b.po_number
	where	b.date_due >= @stdate and b.date_due <= @eddate
	group	by b.vendor, b.po_number, b.part, b.date_due, b.quantity, poh.release_control
	
--	Open cursor	
	Open	vprcursor

--	Fetch data
	fetch	vprcursor into @vendor, @ponumber, @part, @due, @qty, @relcontrol

--	Process all rows, each row at a time	
	while	(@@fetch_status = 0) 
	begin
		--	Initialize
		select	@qtyrec=0, @sad=0, @ra=0, @psad=-1, @pra=-1, @vrating=0, 
			@rating=''
			
		--	Get the total qty received for a given part, vendor and date
		select	@qtyrec = (case @relcontrol
					when 'A' then isnull(max(received),0) 
					else isnull(sum(last_recvd_amount),0) 
				   end),
			@recdt	= max(last_recvd_date)
		from	cdipohistory
		where	vendor = @vendor and
			po_number = @ponumber and
			part = @part and
			date_due = @due

		-- 	Get the latest quantity			
		select	@qty = isnull(quantity, @qty)
		from	cdipohistory
		where	vendor = @vendor and
			po_number = @ponumber and
			part = @part and
			date_due = @due and
			last_recvd_date = @recdt
			
		--	Delete the temp table
		delete	#recdata
		
		--	insert into #recdata temp table	
		insert	into #recdata
		select	convert(varchar(10),b.last_recvd_date, 101),
			max(b.raccuracy)
		from	cdipohistory b 
		where	b.date_due >= @stdate and b.date_due <= @eddate and
			b.vendor = @vendor and po_number = @ponumber and part = @part
		group	by b.vendor, b.po_number, b.part, convert(varchar(10),b.last_recvd_date, 101)

		--	Get the total count of the records in the recdata temp table
		select	@tcount = isnull(count(1),1)
		from	#recdata
		
		--	Count the number of accurate entries
		select	@racount = isnull(count(1),0)
		from	#recdata
		where	isnull(raccuracy,'A') = 'A'

		--	Compute the scheduled adherance
		if (@qtyrec < @qty) or (@recdt > @due)
			select	@sad = 0
		else
			select	@sad = convert(integer, (isnull(@qtyrec,0) / isnull(@qty,1)) * 100)
			
		--	Compute receiving accuracy	
		select	@sadpag = convert(integer, (isnull(@qtyrec,0) / isnull(@qty,1)) * 100),
			@rapag	= convert(integer, ((isnull(@racount,0) / isnull(@tcount,1)) * 100))
			
		select	@ra = convert(integer, ((isnull(@racount,0) / isnull(@tcount,1)) * 100))
		
		--	Determine the points for schedule adherence daily %
		select	@psad = isnull(pointsd,-1)
		from	cdi_ppdcr
		where	p_age = @sad
		
		--	Determine the points for receiving accuracy %
		select	@pra = isnull(pointsd,-1)
		from	cdi_ppdcr
		where	p_age = @ra

		--	Validate the points
		if isnull(@psad,-1) < 0 
			select @psad = 100
			
		if isnull(@pra,-1) < 0 
			select @pra = 100
				
		--	Compute the rating value 		
		select	@vrating = 100 - (@psad + @pra),
			@vpoints = 100 - (@psad + @pra)

		--	validate rating
		if isnull(@vrating,-1) < 0 
			select @vrating = 0

		--	Determine rating	
		select	@rating = rating
		from	cdi_vprating
		where	@vrating >= lrange and
			@vrating <= hrange

		--	Insert data into temp table
		insert	into #vprdata 
		values	(@vendor, @part, @due, @qty, @recdt, @qtyrec, @sadpag, @rapag, 
			@psad, @pra, @vpoints, @rating, @ponumber)
		
		--	Get next set of data
		fetch	vprcursor into @vendor, @ponumber, @part, @due, @qty, @relcontrol
		
	end
--	Close cursor
	close	vprcursor
	deallocate vprcursor
	

--	Display results	
	select  vendor, part, due, qty, recdt, qtyrec, 0, sad, ra, 
		psad, pra, vrating, rating, ponumber,
		company_name, company_logo
	from	#vprdata
		cross join parameters
	order	by vendor, part
end
GO
