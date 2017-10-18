SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_explode_part] (@parent_part varchar(25),
				   @part varchar(25),
				   @parent_quantity numeric(20,6),
				   @component_due datetime,
				   @bom_level int) as
begin
declare		@part_number                    varchar(25),
		@quantity			numeric(20,6),
		@bom_quantity			numeric(20,6),
		@extended_quantity		numeric(20,6),
		@process_id			varchar(25),
		@dropdead_datetime		datetime,
		@machine			varchar(10),
		@setup_time			numeric(20,6),
		@runtime			numeric(20,6),
		@week_no			int,
		@no_weeks			int,
		@last_day			int,
		@week_cnt			int,
		@day_cnt 			int,
		@sunday				char(1),
		@monday				char(1),
		@tuesday			char(1),
		@wednesday			char(1),
		@thursday			char(1),
		@friday				char(1),
		@saturday			char(1),
		@work_hours_in_day		int,
		@include_set_up			char(1),
		@new_row_id			int,
		@bom_type			char(1)

	select	@sunday = sunday,				/* get user parameters */
		@monday = monday,
		@tuesday = tuesday,
		@wednesday = wednesday,
		@thursday = thursday,
		@friday = friday,
		@saturday = saturday,
		@work_hours_in_day = workhours_in_day,
		@include_set_up = include_setuptime
	  from	parameters

	create	table #components
		(component_part			varchar(25),
		 quantity			numeric(20,6))

	select @bom_level = @bom_level + 1

	select	@bom_quantity = bom.std_qty,			/* BOM Quantity */
		@bom_type     = bom.type
	  from	bill_of_material bom
	 where	@part = bom.part
	   and  @parent_part = bom.parent_part
								/* BOM Extended Quantity */
	if @bom_type = 'P' or @bom_type = 'T' 
		select  @extended_quantity = isnull(@bom_quantity,1)	
	else
		select	@extended_quantity = isnull(@bom_quantity,1) * @parent_quantity
	
	select  @machine = pm.machine				/* Machine */
	  from	part_machine pm
	 where	@part = pm.part
	   and	pm.sequence = 1 

	select	@process_id = pmfg.process_id,			/* Process Id,Setup,Runtime */
		@setup_time = isnull(pmfg.setup_time,0),	/* Drop Dead Date Time */
		@runtime = isnull(@extended_quantity,@parent_quantity)
			* (1 / pmfg.parts_per_hour),
		@dropdead_datetime = dateadd(hh,isnull(-1.0 * @extended_quantity 
			* (1.0 / pmfg.parts_per_hour * 24 / @work_hours_in_day),0.0),
			@component_due)
	  from	part_mfg pmfg
	 where	@part = pmfg.part


       select @dropdead_Datetime = isnull(@dropdead_datetime, @component_due)

	if @include_set_up = 'Y'				/* Include Setup? */
		select	@runtime = @runtime + isnull(@setup_time,0),
			@dropdead_datetime = dateadd(hh,-1.0 * 			isnull(@setup_time,0),@dropdead_datetime)

	select	@no_weeks = datediff(dy,@dropdead_datetime,@component_due) / 7 + 1,
		@last_day = datepart(dw,@dropdead_datetime)

	select @week_cnt = @no_weeks				/* adjust Drop Dead Date Time */
								/* for non-working days */
	while @week_cnt > 0
	begin
		if @week_cnt = 1
			select @day_cnt = datepart(dw,@component_due)
		else
			select @day_cnt = 7
		while @day_cnt > 0
		begin
			if @day_cnt = 1 and @sunday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 2 and @monday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 3 and @tuesday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 4 and @wednesday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 5 and @thursday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 6 and @friday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @day_cnt = 7 and @saturday = 'Y'
				select @dropdead_datetime = dateadd(dy,-1,@dropdead_datetime)
			if @week_cnt = 1 and @day_cnt = @last_day
				break
			select @last_day = datepart(dw,@dropdead_datetime)
			select @day_cnt = @day_cnt - 1
		end
		select @week_cnt = @week_cnt - 1
	end
								/* cal. weeks since fiscal year */
	select	@week_no = datediff(wk,parm.fiscal_year_begin,@component_due)
	  from	parameters parm

	select	@new_row_id = count(new_row_id) + 1		/* unique row id for mps rec. */
	  from	#bom_info

	insert	#bom_info(					/* load work table w/ BOM data */
		parent_part,					/* for parent part */
		part,
		quantity,
		extended_quantity,
		machine,
		process_id,
		setup_time,
		class,
		due_datetime,
		dropdead_datetime,
		runtime,
		group_technology,
		week_no,
		new_row_id,
		bom_level)
	select	@parent_part,
		@part,
		isnull(@bom_quantity,1),
		isnull(@extended_quantity,@parent_quantity),
		isnull(@machine,'NONE'),
		isnull(@process_id,'NONE'),
		isnull(@setup_time,0),
		p.class,
		@component_due,
		isnull(@dropdead_datetime,@component_due),
		isnull(@runtime,0),
		p.group_technology,
		@week_no,
		@new_row_id,
		@bom_level
	  from	part p
	 where	@part = p.part

	insert	#components(component_part, quantity)		/* get components for part */
	select	part, quantity
	  from	bill_of_material
	 where	parent_part = @part

	set rowcount 1						/* setup poor man's cursor */

	select	@part_number = component_part,			/* get a component */
		@quantity = quantity
	  from	#components
      order by	component_part

	while @@rowcount > 0					/* loop for each component */
	begin

		set rowcount 0
								/* call myself for each component */
		execute msp_explode_part @part, @part_number, @extended_quantity, @dropdead_datetime, @bom_level

		set rowcount 1

		delete
		  from	#components
		 where  #components.component_part = @part_number

		select	@part_number = component_part,		/* get next component */
			@quantity = quantity
		  from	#components
	      order by	component_part

	end

	set rowcount 0

	drop table #components					/* clean-up */

return
end
GO
