SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_po_comparision] (@mode char(1)=null, @start_dt datetime=null ) as
begin
	declare	@part varchar(25)
	create table #mps ( part varchar(25) )
	create table #pparts ( cpart varchar(25), ppart varchar(25), bomqty numeric(20,6)) 
	create table #ponhand ( cpart varchar(25), ppart varchar(25), onhand numeric(20,6)) 		
	create table #mpsdmd (	part varchar(25),
				demandpast numeric(20,6),
				demand1 numeric(20,6),
				demand2 numeric(20,6),
				demand3 numeric(20,6),
				demand4 numeric(20,6),
				demand5 numeric(20,6),
				demand6 numeric(20,6),
				demand7 numeric(20,6),
				demand8 numeric(20,6),
				demand9 numeric(20,6),
				demand10 numeric(20,6),
				demand11 numeric(20,6),
				demand12 numeric(20,6),
				demandfuture numeric(20,6))
	create table #mpsasgn (	part varchar(25),
				asgnpast numeric(20,6),
				asgn1 numeric(20,6),
				asgn2 numeric(20,6),
				asgn3 numeric(20,6),
				asgn4 numeric(20,6),
				asgn5 numeric(20,6),
				asgn6 numeric(20,6),
				asgn7 numeric(20,6),
				asgn8 numeric(20,6),
				asgn9 numeric(20,6),
				asgn10 numeric(20,6),
				asgn11 numeric(20,6),
				asgn12 numeric(20,6),
				asgnfuture numeric(20,6))
	
	--	1.	Declare local variables.
	declare @current_level int
	declare @count int
	declare	@childpart varchar (25)
	declare @bomqty numeric(20,6)
	declare	@cbomqty numeric(20,6)
	
	--	2.	Create temporary table for exploding components.
	create table #stack 
	(
		part	varchar (25),
		stack_level	int,
		bomqty	numeric (20,6)		
	) 
	
	--	3,	Declare trigger for looping through parts at current low level.
	declare	childparts cursor for
	select	part, bomqty
	from	#stack
	where	stack_level = @current_level
	
	insert	into #mps
	select	distinct part 
	from	master_prod_sched
	where	type = 'P'
	order by part
	
	declare purparts cursor for 
	select	a.part
	from	#mps a
	order by 1
	
	open	purparts
	fetch	purparts into @part
	while ( @@fetch_status = 0 )
	begin
			--	4.	Initialize stack with part or list of top parts.
		select @current_level = 1
		insert into #stack
		values ( @part, @current_level, 1)
		
		--	5.	If rows found, loop through current level, adding children.
		if @@rowcount > 0 
			select @count = 1
		else
			select @count = 0
		
		while @count > 0
		begin
		
		--	6.	Add components for each part at current level using cursor.
			select @count = 0
		
			open childparts
		
			fetch	childparts
			into	@childpart, @cbomqty
		
			while @@fetch_status = 0
			begin
		
		--	7.	Store level and total usage at this level for components.
				insert	#stack
				select	bom.parent_part,
					@current_level + 1,
					bom.quantity * @cbomqty
				from	bill_of_material as bom
				where	bom.part = @childpart
		
				select	@count = 1
		
				fetch	childparts
				into	@childpart, @cbomqty
			end
		
			close	childparts
		
		--	8.	Continue incrementing level as long as new components are added.
			if @count = 1
				select @current_level = @current_level + 1
		end
		
		--	9.	Deallocate components cursor.
		--deallocate childparts
	
		insert into #pparts 
		select @part, part, bomqty from #stack group by part, bomqty
	
		delete #stack
		fetch	purparts into @part
	end
	close purparts
	deallocate purparts
	deallocate childparts	
	
	insert into #ponhand	
	select	p.cpart,
		p.ppart,
		isnull(sum(o.quantity * p.bomqty),0)		
	from	#pparts p
		join object o on o.part = p.ppart
	group by p.cpart, p.ppart
	order by 1,2
	
	if @mode is null 
		select @mode = 'W'
	if @start_dt is null
		select @start_dt = getdate()

	if @mode = 'M'
	begin
		insert	into #mpsdmd
		select	#mps.part,
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due < @start_dt and 
				mps.part = #mps.part) demandpast,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= @start_dt and mps.due < dateadd ( month, 1, @start_dt ) and
				mps.part = #mps.part) demand1,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 1, @start_dt ) and 
				mps.due < dateadd ( month, 2, @start_dt ) and
				mps.part = #mps.part) demand2,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 2, @start_dt ) and 
				mps.due < dateadd ( month, 3, @start_dt ) and
				mps.part = #mps.part) demand3,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 3, @start_dt ) and 
				mps.due < dateadd ( month, 4, @start_dt ) and
				mps.part = #mps.part) demand4,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 4, @start_dt ) and 
				mps.due < dateadd ( month, 5, @start_dt ) and
				mps.part = #mps.part) demand5,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 5, @start_dt ) and 
				mps.due < dateadd ( month, 6, @start_dt ) and
				mps.part = #mps.part) demand6,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 6, @start_dt ) and 
				mps.due < dateadd ( month, 7, @start_dt ) and
				mps.part = #mps.part) demand7,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 7, @start_dt ) and 
				mps.due < dateadd ( month, 8, @start_dt ) and
				mps.part = #mps.part) demand8,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 8, @start_dt ) and 
				mps.due < dateadd ( month, 9, @start_dt ) and
				mps.part = #mps.part) demand9,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 9, @start_dt ) and 
				mps.due < dateadd ( month, 10, @start_dt ) and
				mps.part = #mps.part) demand10,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 10, @start_dt ) and 
				mps.due < dateadd ( month, 11, @start_dt ) and
				mps.part = #mps.part) demand11,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 11, @start_dt ) and 
				mps.due < dateadd ( month, 12, @start_dt ) and
				mps.part = #mps.part) demand12,
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( month, 12, @start_dt ) and
				mps.part = #mps.part) demandfuture
		from	#mps
		order	by #mps.part			

		insert into #mpsasgn
		select	#mps.part,
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due < @start_dt and 
				pod.part_number = #mps.part) asgndpast,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= @start_dt and pod.date_due < dateadd ( month, 1, @start_dt ) and
				pod.part_number = #mps.part) asgnd1,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 1, @start_dt ) and 
				pod.date_due < dateadd ( month, 2, @start_dt ) and
				pod.part_number = #mps.part) asgnd2,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 2, @start_dt ) and 
				pod.date_due < dateadd ( month, 3, @start_dt ) and
				pod.part_number = #mps.part) asgnd3,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 3, @start_dt ) and 
				pod.date_due < dateadd ( month, 4, @start_dt ) and
				pod.part_number = #mps.part) asgnd4,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 4, @start_dt ) and 
				pod.date_due < dateadd ( month, 5, @start_dt ) and
				pod.part_number = #mps.part) asgnd5,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 5, @start_dt ) and 
				pod.date_due < dateadd ( month, 6, @start_dt ) and
				pod.part_number = #mps.part) asgnd6,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 6, @start_dt ) and 
				pod.date_due < dateadd ( month, 7, @start_dt ) and
				pod.part_number = #mps.part) asgnd7,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 7, @start_dt ) and 
				pod.date_due < dateadd ( month, 8, @start_dt ) and
				pod.part_number = #mps.part) asgnd8,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 8, @start_dt ) and 
				pod.date_due < dateadd ( month, 9, @start_dt ) and
				pod.part_number = #mps.part) asgnd9,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 9, @start_dt ) and 
				pod.date_due < dateadd ( month, 10, @start_dt ) and
				pod.part_number = #mps.part) asgnd10,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 10, @start_dt ) and 
				pod.date_due < dateadd ( month, 11, @start_dt ) and
				pod.part_number = #mps.part) asgnd11,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 11, @start_dt ) and 
				pod.date_due < dateadd ( month, 12, @start_dt ) and
				pod.part_number = #mps.part) asgnd12,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( month, 12, @start_dt ) and
				pod.part_number = #mps.part) asgndfuture
		from	#mps
		order	by #mps.part			
	end
	else
	begin
		insert	into #mpsdmd
		select	#mps.part,
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due < @start_dt and 
				mps.part = #mps.part) demandpast,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= @start_dt and mps.due < dateadd ( week, 1, @start_dt ) and
				mps.part = #mps.part) demand1,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 1, @start_dt ) and 
				mps.due < dateadd ( week, 2, @start_dt ) and
				mps.part = #mps.part) demand2,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 2, @start_dt ) and 
				mps.due < dateadd ( week, 3, @start_dt ) and
				mps.part = #mps.part) demand3,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 3, @start_dt ) and 
				mps.due < dateadd ( week, 4, @start_dt ) and
				mps.part = #mps.part) demand4,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 4, @start_dt ) and 
				mps.due < dateadd ( week, 5, @start_dt ) and
				mps.part = #mps.part) demand5,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 5, @start_dt ) and 
				mps.due < dateadd ( week, 6, @start_dt ) and
				mps.part = #mps.part) demand6,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 6, @start_dt ) and 
				mps.due < dateadd ( week, 7, @start_dt ) and
				mps.part = #mps.part) demand7,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 7, @start_dt ) and 
				mps.due < dateadd ( week, 8, @start_dt ) and
				mps.part = #mps.part) demand8,
				
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 8, @start_dt ) and 
				mps.due < dateadd ( week, 9, @start_dt ) and
				mps.part = #mps.part) demand9,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 9, @start_dt ) and 
				mps.due < dateadd ( week, 10, @start_dt ) and
				mps.part = #mps.part) demand10,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 10, @start_dt ) and 
				mps.due < dateadd ( week, 11, @start_dt ) and
				mps.part = #mps.part) demand11,
	
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 11, @start_dt ) and 
				mps.due < dateadd ( week, 12, @start_dt ) and
				mps.part = #mps.part) demand12,
			(select	isnull(sum(mps.qnty),0)
			from	master_prod_sched mps
			where	mps.due >= dateadd ( week, 12, @start_dt ) and
				mps.part = #mps.part) demandfuture
		from	#mps
		order	by #mps.part			

		insert into #mpsasgn
		select	#mps.part,
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due < @start_dt and 
				pod.part_number = #mps.part) asgndpast,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= @start_dt and pod.date_due < dateadd ( week, 1, @start_dt ) and
				pod.part_number = #mps.part) asgnd1,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 1, @start_dt ) and 
				pod.date_due < dateadd ( week, 2, @start_dt ) and
				pod.part_number = #mps.part) asgnd2,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 2, @start_dt ) and 
				pod.date_due < dateadd ( week, 3, @start_dt ) and
				pod.part_number = #mps.part) asgnd3,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 3, @start_dt ) and 
				pod.date_due < dateadd ( week, 4, @start_dt ) and
				pod.part_number = #mps.part) asgnd4,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 4, @start_dt ) and 
				pod.date_due < dateadd ( week, 5, @start_dt ) and
				pod.part_number = #mps.part) asgnd5,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 5, @start_dt ) and 
				pod.date_due < dateadd ( week, 6, @start_dt ) and
				pod.part_number = #mps.part) asgnd6,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 6, @start_dt ) and 
				pod.date_due < dateadd ( week, 7, @start_dt ) and
				pod.part_number = #mps.part) asgnd7,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 7, @start_dt ) and 
				pod.date_due < dateadd ( week, 8, @start_dt ) and
				pod.part_number = #mps.part) asgnd8,
				
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 8, @start_dt ) and 
				pod.date_due < dateadd ( week, 9, @start_dt ) and
				pod.part_number = #mps.part) asgnd9,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 9, @start_dt ) and 
				pod.date_due < dateadd ( week, 10, @start_dt ) and
				pod.part_number = #mps.part) asgnd10,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 10, @start_dt ) and 
				pod.date_due < dateadd ( week, 11, @start_dt ) and
				pod.part_number = #mps.part) asgnd11,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 11, @start_dt ) and 
				pod.date_due < dateadd ( week, 12, @start_dt ) and
				pod.part_number = #mps.part) asgnd12,
	
			(select	isnull(sum(pod.balance),0)
			from	po_detail pod
			where	pod.date_due >= dateadd ( week, 12, @start_dt ) and
				pod.part_number = #mps.part) asgndfuture
		from	#mps
		order	by #mps.part			
	end

	if @mode = 'M'
		select	#mps.part,
			p.name,
			p.description_long,
			parto.default_vendor,
			pv.min_on_order,
			v.name,
			@start_dt date1,
			dateadd ( month, 1, @start_dt ) date2,
			dateadd ( month, 2, @start_dt ) date3,
			dateadd ( month, 3, @start_dt ) date4,
			dateadd ( month, 4, @start_dt ) date5,
			dateadd ( month, 5, @start_dt ) date6,
			dateadd ( month, 6, @start_dt ) date7,
			dateadd ( month, 7, @start_dt ) date8,
			dateadd ( month, 8, @start_dt ) date9,
			dateadd ( month, 9, @start_dt ) date10,
			dateadd ( month, 10, @start_dt ) date11,
	 		dateadd ( month, 11, @start_dt ) date12,
			dateadd ( month, 12, @start_dt ) datefuture,
			demandpast,
			demand1,
			demand2,
			demand3,
			demand4,
			demand5,
			demand6,
			demand7,
			demand8,
			demand9,
			demand10,
			demand11,
			demand12,
			demandfuture,
			asgnpast,
			asgn1,
			asgn2,
			asgn3,
			asgn4,
			asgn5,
			asgn6,
			asgn7,
			asgn8,
			asgn9,
			asgn10,
			asgn11,
			asgn12,
			asgnfuture,
			(select isnull(sum(onhand),0) from #ponhand where cpart = #mps.part) onhand,
			pmt.company_name company_name,
			pmt.company_logo company_logo
		from	#mps
			join part p on p.part = #mps.part
			join part_online parto on parto.part = p.part
			LEFT outer join #mpsdmd on #mpsdmd.part = #mps.part
			LEFT outer join #mpsasgn on #mpsasgn.part = #mps.part
			LEFT OUTER join part_vendor pv on pv.part = p.part and pv.vendor = parto.default_vendor
			LEFT OUTER join vendor v on v.code = parto.default_vendor
			CROSS JOIN parameters pmt
			order	by #mps.part
	else
			select	#mps.part,
			p.name,
			p.description_long,
			parto.default_vendor,
			pv.min_on_order,
			v.name,
			@start_dt date1,
			dateadd ( week, 1, @start_dt ) date2,
			dateadd ( week, 2, @start_dt ) date3,
			dateadd ( week, 3, @start_dt ) date4,
			dateadd ( week, 4, @start_dt ) date5,
			dateadd ( week, 5, @start_dt ) date6,
			dateadd ( week, 6, @start_dt ) date7,
			dateadd ( week, 7, @start_dt ) date8,
			dateadd ( week, 8, @start_dt ) date9,
			dateadd ( week, 9, @start_dt ) date10,
			dateadd ( week, 10, @start_dt ) date11,
	 		dateadd ( week, 11, @start_dt ) date12,
			dateadd ( week, 12, @start_dt ) datefuture,
			demandpast,
			demand1,
			demand2,
			demand3,
			demand4,
			demand5,
			demand6,
			demand7,
			demand8,
			demand9,
			demand10,
			demand11,
			demand12,
			demandfuture,
			asgnpast,
			asgn1,
			asgn2,
			asgn3,
			asgn4,
			asgn5,
			asgn6,
			asgn7,
			asgn8,
			asgn9,
			asgn10,
			asgn11,
			asgn12,
			asgnfuture,
			(select isnull(sum(onhand),0) from #ponhand where cpart = #mps.part) onhand,
			pmt.company_name company_name,
			pmt.company_logo company_logo
		from	#mps
			join part p on p.part = #mps.part
			join part_online parto on parto.part = p.part
			LEFT outer join #mpsdmd on #mpsdmd.part = #mps.part
			LEFT outer join #mpsasgn on #mpsasgn.part = #mps.part
			left OUTER join part_vendor pv on pv.part = p.part and pv.vendor = parto.default_vendor
			LEFT OUTER join vendor v on v.code = parto.default_vendor
			CROSS join parameters pmt
		order	by #mps.part
end
GO
