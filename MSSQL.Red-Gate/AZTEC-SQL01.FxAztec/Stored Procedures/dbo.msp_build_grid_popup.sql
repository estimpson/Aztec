SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_grid_popup] (@part varchar(25),@start_dt datetime,@type char(1))
as
begin -- (1b)
	declare	@onhand numeric(20,6),
		@onhand_rem numeric(20,6),
		@min_on_order numeric(20,6),
		@lead_time numeric(6,2),
		@receiving_um varchar(10),
		@parts_per_hour numeric(20,6),
		@qty_required numeric(20,6),
		@work_hours integer,
		@parts_per_day numeric(20,6),
		@po1 numeric(20,6),
		@po2 numeric(20,6),
		@po3 numeric(20,6),
		@po4 numeric(20,6),
		@po5 numeric(20,6),
		@po6 numeric(20,6),
		@po7 numeric(20,6),
		@po8 numeric(20,6),
		@po_past numeric(20,6),
		@po_future numeric(20,6),
		@asgnd_past numeric(20,6),
		@asgnd1 numeric(20,6),
		@asgnd2 numeric(20,6),
		@asgnd3 numeric(20,6),
		@asgnd4 numeric(20,6),
		@asgnd5 numeric(20,6),
		@asgnd6 numeric(20,6),
		@asgnd7 numeric(20,6),
		@asgnd8 numeric(20,6),
		@asgnd_future numeric(20,6),
		@demand_past numeric(20,6),
		@demand1 numeric(20,6),
		@demand2 numeric(20,6),
		@demand3 numeric(20,6),
		@demand4 numeric(20,6),
		@demand5 numeric(20,6),
		@demand6 numeric(20,6),
		@demand7 numeric(20,6),
		@demand8 numeric(20,6),
		@demand_future numeric(20,6),
		@net_sh_past numeric(20,6),
		@net_sh_1 numeric(20,6),
		@net_sh_2 numeric(20,6),
		@net_sh_3 numeric(20,6),
		@net_sh_4 numeric(20,6),
		@net_sh_5 numeric(20,6),
		@net_sh_6 numeric(20,6),
		@net_sh_7 numeric(20,6),
		@net_sh_8 numeric(20,6),
		@net_sh_future numeric(20,6),
		@net_req_past numeric(20,6),
		@net_req_1 numeric(20,6),
		@net_req_2 numeric(20,6),
		@net_req_3 numeric(20,6),
		@net_req_4 numeric(20,6),
		@net_req_5 numeric(20,6),
		@net_req_6 numeric(20,6),
		@net_req_7 numeric(20,6),
		@net_req_8 numeric(20,6),
		@net_req_future numeric(20,6),
		@inv_bal_past numeric(20,6),
		@inv_bal_1 numeric(20,6),
		@inv_bal_2 numeric(20,6),
		@inv_bal_3 numeric(20,6),
		@inv_bal_4 numeric(20,6),
		@inv_bal_5 numeric(20,6),
		@inv_bal_6 numeric(20,6),
		@inv_bal_7 numeric(20,6),
		@inv_bal_8 numeric(20,6),
		@inv_bal_future numeric(20,6),
		@standard_pack numeric(20,6),
		@sug_rel_past numeric(20,6),
		@sug_rel_1 numeric(20,6),
		@sug_rel_2 numeric(20,6),
		@sug_rel_3 numeric(20,6),
		@sug_rel_4 numeric(20,6),
		@sug_rel_5 numeric(20,6),
		@sug_rel_6 numeric(20,6),
		@sug_rel_7 numeric(20,6),
		@sug_rel_8 numeric(20,6),
		@sug_rel_future numeric(20,6),
		@name varchar(50)
	/* select onhand quantity for that part.*/
	--select @onhand=SUM(isnull(quantity,0))
	--  from object
	--  where(part=@part and status='A')
	select	@onhand=isnull(on_hand,0)
	from	part_online
	where	(part=@part)
	select	@onhand=(isnull(@onhand,0))
	select	@onhand_rem=@onhand
	/* select name */
	select	@name=name
	from	part
	where	part=@part
	--  if @type = 'P'
	--   begin -- (2b)
	/* select standard_pack from part_inventory */
	select	@standard_pack=isnull(standard_pack,1)
	from	part_inventory
	where	part=@part
	/* select info from part_vendor */
	select	@min_on_order=min_on_order,
		@lead_time=lead_time,
		@receiving_um=receiving_um
	from	part_vendor
	where	part=@part
	-- verify values in variables
	select	@min_on_order = isnull( @min_on_order, 1 ),
		@receiving_um = isnull( @receiving_um, 'EA')
	/*select po_detail qty for this part..*/
	select	@po_past=isnull(sum(case when po_detail.date_due<@start_dt then quantity else 0 end),0),
		@po1=isnull(sum(case when po_detail.date_due>=@start_dt               and po_detail.date_due<DateAdd(dd,1,@start_dt) then quantity else 0 end),0),
		@po2=isnull(sum(case when po_detail.date_due>=DateAdd(dd,1,@start_dt) and po_detail.date_due<DateAdd(dd,2,@start_dt) then quantity else 0 end),0),
		@po3=isnull(sum(case when po_detail.date_due>=DateAdd(dd,2,@start_dt) and po_detail.date_due<DateAdd(dd,3,@start_dt) then quantity else 0 end),0),
		@po4=isnull(sum(case when po_detail.date_due>=DateAdd(dd,3,@start_dt) and po_detail.date_due<DateAdd(dd,4,@start_dt) then quantity else 0 end),0),
		@po5=isnull(sum(case when po_detail.date_due>=DateAdd(dd,4,@start_dt) and po_detail.date_due<DateAdd(dd,5,@start_dt) then quantity else 0 end),0),
		@po6=isnull(sum(case when po_detail.date_due>=DateAdd(dd,1,@start_dt) and po_detail.date_due<DateAdd(dd,7,@start_dt) then quantity else 0 end),0),
		@po7=isnull(sum(case when po_detail.date_due>=DateAdd(dd,7,@start_dt) and po_detail.date_due<DateAdd(dd,14,@start_dt) then quantity else 0 end),0),
		@po8=isnull(sum(case when po_detail.date_due>=DateAdd(dd,14,@start_dt) and po_detail.date_due<DateAdd(dd,21,@start_dt) then quantity else 0 end),0),
		@po_future=isnull(sum(case when po_detail.date_due>DateAdd(dd,21,@start_dt) then quantity else 0 end),0)
	from	po_detail
	where	part_number=@part and (deleted<>'Y' or deleted is null)
	--   end -- (2e)
	/*select demand quantities for the respective buckets..*/
	select	@demand_past=isnull(sum(case when due<@start_dt then qnty else 0 end),0),
		@demand1=isnull(sum(case when due>=@start_dt               and due<DateAdd(dd,1,@start_dt) then qnty else 0 end),0),
		@demand2=isnull(sum(case when due>=DateAdd(dd,1,@start_dt) and due<DateAdd(dd,2,@start_dt) then qnty else 0 end),0),
		@demand3=isnull(sum(case when due>=DateAdd(dd,2,@start_dt) and due<DateAdd(dd,3,@start_dt) then qnty else 0 end),0),
		@demand4=isnull(sum(case when due>=DateAdd(dd,3,@start_dt) and due<DateAdd(dd,4,@start_dt) then qnty else 0 end),0),
		@demand5=isnull(sum(case when due>=DateAdd(dd,4,@start_dt) and due<DateAdd(dd,5,@start_dt) then qnty else 0 end),0),
		@demand6=isnull(sum(case when due>=DateAdd(dd,1,@start_dt) and due<DateAdd(dd,7,@start_dt) then qnty else 0 end),0),
		@demand7=isnull(sum(case when due>=DateAdd(dd,7,@start_dt) and due<DateAdd(dd,14,@start_dt) then qnty else 0 end),0),
		@demand8=isnull(sum(case when due>=DateAdd(dd,14,@start_dt) and due<DateAdd(dd,21,@start_dt) then qnty else 0 end),0),
		@demand_future=isnull(sum(case when due>=DateAdd(dd,21,@start_dt) then qnty else 0 end),0)
	from	master_prod_sched
	where	part=@part and type=@type
	--group by master_prod_sched.due
	/*  get hard queue qty from work order table*/
	if @type='P'
		select	@qty_Required=sum(qty_required),
			@parts_per_hour=sum(parts_per_hour)
		from	workorder_detail
		where	part=any(select parent_part from bill_of_material_ec where part=@part)
	else
		select	@qty_Required=sum(qty_required),
			@parts_per_hour=max(parts_per_hour)
		from	workorder_Detail
		where	part=@part
	select	@work_hours=workhours_in_day
	from	parameters
	/*calculate parts manufactured per day*/
	select	@parts_per_day=isnull(@parts_per_hour,0)*isnull(@work_hours,0),
		@asgnd_past=0
	if @demand_past>0
		if @parts_per_day>=@qty_required
			select @asgnd_past=isnull((case when @qty_required>=@parts_per_day then @parts_per_day else @qty_required end),0)
		else
			select @asgnd_past=isnull(@qty_required,0)
	else
		select @asgnd_past=0
	if @demand1>0
		select @asgnd1=isnull((case when(@qty_required-@asgnd_past)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd_past) end),0)
	else
		select @asgnd1=0
		--if	@parts_per_day>=@qty_required
		--	select @asgnd1=isnull((case when @qty_required>=@parts_per_day then @parts_per_day else @qty_required end),0)
		--else
		--	select @asgnd1=isnull(@qty_required,0)
		--   else
		--     select @asgnd1=0
	if	@demand2>0
		select @asgnd2=isnull((case when(@qty_required-@asgnd1)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd1) end),0)
	else
		select @asgnd2=0
	if	@demand3>0
		select @asgnd3=isnull((case when(@qty_required-@asgnd2)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd2) end),0)
	else
		select @asgnd3=0
	if @demand4>0
		select @asgnd4=isnull((case when(@qty_required-@asgnd3)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd3) end),0)
	else
		select @asgnd4=0
	if @demand5>0
		select @asgnd5=isnull((case when(@qty_required-@asgnd4)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd4) end),0)
	else
		select @asgnd5=0
	if @demand6>0
		select @asgnd6=isnull((case when(@qty_required-@asgnd5)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd5) end),0)
	else
		select @asgnd6=0
	if @demand7>0
		select @asgnd7=isnull((case when(@qty_required-@asgnd6)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd6) end),0)
	else
		select @asgnd7=0
	if @demand8>0
		select @asgnd8=isnull((case when(@qty_required-@asgnd7)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd7) end),0)
	else
		select @asgnd8=0
	if @demand_future>0
		select @asgnd_future=isnull((case when(@qty_required-@asgnd8)>@parts_per_day then @parts_per_day else(@qty_required-@asgnd8) end),0)
	else
		select @asgnd_future=0
	/* compute net soft hard queue requirment */
	
	select	@net_sh_past=@demand_past-@asgnd_past,
		@net_sh_1=@demand1-@asgnd1,
		@net_sh_2=@demand2-@asgnd2,
		@net_sh_3=@demand3-@asgnd3,
		@net_sh_4=@demand4-@asgnd4,
		@net_sh_5=@demand5-@asgnd5,
		@net_sh_6=@demand6-@asgnd6,
		@net_sh_7=@demand7-@asgnd7,
		@net_sh_8=@demand8-@asgnd8,
		@net_sh_future=@demand_future-@asgnd_future
	/*compute the net requirement..*/
	if @net_sh_past>0
		if @onhand_rem<=@net_sh_past
			select	@net_req_past=(@net_sh_past-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_past=0
		else
			select	@net_req_past=0,
				@onhand_rem=@onhand_rem-@net_sh_past,
				@inv_bal_past=@onhand_rem
	else
		select	@net_req_past=0,
			@inv_bal_past=@onhand_rem
	if @net_sh_1>0
		if @onhand_rem<=@net_sh_1
			select	@net_req_1=(@net_sh_1-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_1=0
		else
			select	@net_req_1=0,
				@onhand_rem=@onhand_rem-@net_sh_1,
				@inv_bal_1=@onhand_rem
	else
		select	@net_req_1=0,
			@inv_bal_1=@onhand_rem
	if @net_sh_2>0
		if @onhand_rem<=@net_sh_2
		        select	@net_req_2=(@net_sh_2-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_2=0
		else
			select	@net_req_2=0,
				@onhand_rem=@onhand_rem-@net_sh_2,
				@inv_bal_2=@onhand_rem
	else
		select	@net_req_2=0,
			@inv_bal_2=@onhand_rem
	if @net_sh_3>0
		if @onhand_rem<=@net_sh_3
		        select	@net_req_3=(@net_sh_3-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_3=0
		else
			select	@net_req_3=0,
				@onhand_rem=@onhand_rem-@net_sh_3,
				@inv_bal_3=@onhand_rem
	else
		select	@net_req_3=0,
			@inv_bal_3=@onhand_rem
	if @net_sh_4>0
		if @onhand_rem<=@net_sh_4
			select	@net_req_4=(@net_sh_4-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_4=0
		else
			select	@net_req_4=0,
				@onhand_rem=@onhand_rem-@net_sh_4,
				@inv_bal_4=@onhand_rem
	else
		select	@net_req_4=0,
			@inv_bal_4=@onhand_rem
	if @net_sh_5>0
		if @onhand_rem<=@net_sh_5
			select	@net_req_5=(@net_sh_5-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_5=0
		else
			select	@net_req_5=0,
				@onhand_rem=@onhand_rem-@net_sh_5,
				@inv_bal_5=@onhand_rem
	else
		select	@net_req_5=0,
			@inv_bal_5=@onhand_rem
	/* reset the onhand rem to distribute it to the weekly buckets..*/
	--   select @onhand_rem=@onhand
	/*weekly buckets*/
	if @net_sh_6>0
		if @onhand_rem<=@net_sh_6
			select	@net_req_6=(@net_sh_6-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_6=0
		else
			select	@net_req_6=0,
				@onhand_rem=@onhand_rem-@net_sh_6,
				@inv_bal_6=@onhand_rem
	else
		select	@net_req_6=0,
			@inv_bal_6=@onhand_rem
	if @net_sh_7>0
		if @onhand_rem<=@net_sh_7
			select	@net_req_7=(@net_sh_7-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_7=0
		else
			select	@net_req_7=0,
				@onhand_rem=@onhand_rem-@net_sh_7,
				@inv_bal_7=@onhand_rem
	else
		select	@net_req_7=0,
			@inv_bal_7=@onhand_rem
	if @net_sh_8>0
		if @onhand_rem<=@net_sh_8
			select	@net_req_8=(@net_sh_8-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_8=0
		else
			select	@net_req_8=0,
				@onhand_rem=@onhand_rem-@net_sh_8,
				@inv_bal_8=@onhand_rem
	else
		select	@net_req_8=0,
			@inv_bal_8=@onhand_rem
	if @net_sh_future>0
		if @onhand_rem<=@net_sh_future
			select	@net_req_future=(@net_sh_future-@onhand_rem),
				@onhand_rem=0,
				@inv_bal_future=0
		else
			select	@net_req_future=0,
				@onhand_rem=@onhand_rem-@net_sh_future,
				@inv_bal_future=@onhand_rem
	else
		select	@net_req_future=0,
			@inv_bal_future=@onhand_rem
	/* compute the suggested release quanitites */
	if @net_req_past>0
		if @net_req_past>@min_on_order
			select @sug_rel_past=((@net_req_past/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_past=@min_on_order
	else
		select @sug_rel_past=0
	if @net_req_1>0
		if @net_req_1>@min_on_order
			select @sug_rel_1=((@net_req_1/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_1=@min_on_order
	else
		select @sug_rel_1=0
	if @net_req_2>0
		if @net_req_2>@min_on_order
			select @sug_rel_2=((@net_req_2/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_2=@min_on_order
	else
		select @sug_rel_2=0
	if @net_req_3>0
		if @net_req_3>@min_on_order
			select @sug_rel_3=((@net_req_3/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_3=@min_on_order
	else
		select @sug_rel_3=0
	if @net_req_4>0
		if @net_req_4>@min_on_order
			select @sug_rel_4=((@net_req_4/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_4=@min_on_order
	else
		select @sug_rel_4=0
	if @net_req_5>0
		if @net_req_5>@min_on_order
			select @sug_rel_5=((@net_req_5/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_5=@min_on_order
	else	
		select @sug_rel_5=0
	if @net_req_6>0
		if @net_req_6>@min_on_order
			select @sug_rel_6=((@net_req_6/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_6=@min_on_order
	else
		select @sug_rel_6=0
	if @net_req_7>0
		if @net_req_7>@min_on_order
			select @sug_rel_7=((@net_req_7/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_7=@min_on_order
	else
		select @sug_rel_7=0
	if @net_req_8>0
		if @net_req_8>@min_on_order
			select @sug_rel_8=((@net_req_8/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_8=@min_on_order
	else
		select @sug_rel_8=0
	if @net_req_future>0
		if @net_req_future>@min_on_order
			select @sug_rel_future=((@net_req_future/@min_on_order)+1)*@min_on_order
		else
			select @sug_rel_future=@min_on_order
	else
		select @sug_rel_future=0
	/* select all the result set values */
	select	part=@part,
		name=@name,
		onhand=@onhand,
		past_date='Past Due',
		date1=@start_dt,
		date2=(DateAdd(dd,1,@start_dt)),
		date3=(DateAdd(dd,2,@start_dt)),
		date4=(DateAdd(dd,3,@start_dt)),
		date5=(DateAdd(dd,4,@start_dt)),
		date6=(DateAdd(dd,7,@start_dt)),
		date7=(DateAdd(dd,14,@start_dt)),
		date8=(DateAdd(dd,21,@start_dt)),
		future_date='Future',
		demand_past=@demand_past,
		demand1=@demand1,
		demand2=@demand2,
		demand3=@demand3,
		demand4=@demand4,
		demand5=@demand5,
		demand6=@demand6,
		demand7=@demand7,
		demand8=@demand8,
		demand_future=@demand_future,
		asgnd_past=@asgnd_past,
		asgnd1=@asgnd1,
		asgnd2=@asgnd2,
		asgnd3=@asgnd3,
		asgnd4=@asgnd4,
		asgnd5=@asgnd5,
		asgnd6=@asgnd6,
		asgnd7=@asgnd7,
		asgnd8=@asgnd8,
		asgnd_future=isnull(@asgnd_future,0),
		net_sh_past=@demand_past - isnull(@asgnd_past,0),
		net_sh_1=@demand1 - @asgnd1,
		net_sh_2=@demand2 - @asgnd2,
		net_sh_3=@demand3 - @asgnd3,
		net_sh_4=@demand4 - @asgnd4,
		net_sh_5=@demand5 - @asgnd5,
		net_sh_6=@demand6 - @asgnd6,
		net_sh_7=@demand7 - @asgnd7,
		net_sh_8=@demand8 - @asgnd8,
		net_sh_future=@demand_future - @asgnd_future,
		po_past=@po_past,
		po1=@po1,
		po2=@po2,
		po3=@po3,
		po4=@po4,
		po5=@po5,
		po6=@po6,
		po7=@po7,
		po8=@po8,
		po_future=@po_future,
		net_req_past=@net_req_past,
		net_req1=@net_req_1,
		net_req2=@net_req_2,
		net_req3=@net_req_3,
		net_req4=@net_req_4,
		net_req5=@net_req_5,
		net_req6=@net_req_6,
		net_req7=@net_req_7,
		net_req8=@net_req_8,
		net_reqfuture=@net_req_future,
		inv_bal_past=@inv_bal_past,
		inv_bal1=@inv_bal_1,
		inv_bal2=@inv_bal_2,
		inv_bal3=@inv_bal_3,
		inv_bal4=@inv_bal_4,
		inv_bal5=@inv_bal_5,
		inv_bal6=@inv_bal_6,
		inv_bal7=@inv_bal_7,
		inv_bal8=@inv_bal_8,
		inv_bal_future=@inv_bal_future,
		sug_rel_past=@sug_rel_past,
		sug_rel_1=@sug_rel_1,
		sug_rel_2=@sug_rel_2,
		sug_rel_3=@sug_rel_3,
		sug_rel_4=@sug_rel_4,
		sug_rel_5=@sug_rel_5,
		sug_rel_6=@sug_rel_6,
		sug_rel_7=@sug_rel_7,
		sug_rel_8=@sug_rel_8,
		sug_rel_future=@sug_rel_future,
		proj_bal_past=@sug_rel_past-@net_req_past,
		proj_bal_1=@sug_rel_1-@net_req_1,
		proj_bal_2=@sug_rel_2-@net_req_2,
		proj_bal_3=@sug_rel_3-@net_req_3,
		proj_bal_4=@sug_rel_4-@net_req_4,
		proj_bal_5=@sug_rel_5-@net_req_5,
		proj_bal_6=@sug_rel_6-@net_req_6,
		proj_bal_7=@sug_rel_7-@net_req_7,
		proj_bal_8=@sug_rel_8-@net_req_8,
		proj_bal_future=@sug_rel_future-@net_req_future,
		standard_pack=isnull(@standard_pack,1),
		min_on_order=@min_on_order,
		lead_time=isnull(@lead_time,0),
		receiving_um=@receiving_um
end -- (1e)
GO
