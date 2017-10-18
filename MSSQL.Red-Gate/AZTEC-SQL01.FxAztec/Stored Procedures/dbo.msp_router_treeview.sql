SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[msp_router_treeview]
	@top_part varchar(25)
,	@mode smallint
,	@user_datetime datetime
as
set nocount on
select @user_datetime = getdate()

begin transaction
-- declarations
	declare @item_level integer,
		@line char(30),
		@parent_part varchar(25),
		@part varchar(25),
		@current_datetime datetime,
		@start_datetime datetime,
		@activity varchar(25),
		@item_type varchar(2),
		@substitute_part varchar(1),
		@type varchar(1),
		@label varchar(255),
		@rowcount integer,
		@temp varchar(255),
		@item_type_number smallint,
		@sequence smallint,
		@eng_level  varchar (10),
		@stack_item_id smallint,
		@parent_id smallint,
		@new_item_id smallint,
		@routertype varchar(40)
		

-- create temporary tables
	create table #stack (
		id			numeric(8,0) identity not null,
		parent_id		integer,
		parent_part		varchar(25) null,
		part			varchar(25) null,
		item_level		smallint null,
		start_datetime		datetime null,
		end_datetime		datetime null,
		substitute_part		varchar(1) null,
		type			varchar(1) null,
		spid			integer not null
	)

	create table #output_stack(
		parent_id 		smallint,
		item_id			numeric(8,0) identity not null,
		parent_item 		varchar(25) null,
		item 			varchar(25) null,
		item_level 		smallint null,
		item_type 		varchar(2) null,
		item_label 		varchar(255) null,
		activity 		varchar(25) null,
		machine 		varchar(15) null,
		parent_part 		varchar(25) null,
		part 			varchar(25) null,
		components 		smallint null,
		start_datetime 		datetime null,
		item_type_number 	smallint null,
		sequence 		smallint null
	)
	

-- get current date in the format mm/dd/yyyy hh:mm:ss
	select	@current_datetime = getdate()
-- initialize parent and item id
	select	@new_item_id = 0
		
	insert into #stack (
		parent_id,
		parent_part,
		part,
		item_level,
		start_datetime,
		end_datetime,
		substitute_part,
		type,
		spid) 
	values	(0,
		@top_part,
		@top_part,
		1,
		@current_datetime,
		@current_datetime,
		'N',
		'M',
		@@spid)
	
	select @item_level=1

	while @item_level>0
	begin
		select @activity=''
		select @parent_part=''
		select @part=''
		
		if exists(select 1 from #stack where item_level=@item_level and spid=@@spid)
		begin
			select 	@eng_level = ''
			
			select	@start_datetime=min(start_datetime)
			from	#stack
			where	item_level=@item_level
				and spid=@@spid
				
			select 	@stack_item_id = min(id)
			from	#stack
			where 	item_level=@item_level
				and start_datetime=@start_datetime
				and spid=@@spid

			select 	@parent_part=parent_part,
				@part=part,
				@substitute_part=substitute_part,
				@type=type,
				@parent_id = parent_id
			from	#stack
			where 	id = @stack_item_id and
				spid = @@spid

			select	@eng_level=engineering_level
			from 	effective_change_notice
			where	part=@part
				and effective_date=(	select	max(effective_date)
							from	effective_change_notice
							where 	part=@part
								and effective_date<=@current_datetime) 
			select	@activity=activity_router.code,
				@sequence=sequence,
				@routertype=activity_codes.flow_route_window
			from 	activity_router
					join activity_codes on activity_router.code = activity_codes.code
			where 	parent_part=@top_part
				and part=@part

			if isnull(@activity,'')>''
			begin
				if @routertype = 'w_create_flow_route_outside_version2'
				begin
					select @item_type='O1'
					select @label='Outside Process:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
					select @item_type_number=10
				end
				else
				begin
					select @item_type='A1'
					select @label='Activity:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
					select @item_type_number=9
				end
			end
			else
			begin
				select	@activity=activity_router.code,
					@sequence=sequence,
					@routertype=activity_codes.flow_route_window
				from 	activity_router
						join activity_codes on activity_router.code = activity_codes.code
				where 	parent_part=@parent_part
					and part=@part
					
				if isnull(@activity,'')>''
				begin
					if @routertype = 'w_create_flow_route_outside_version2'
					begin
						select @item_type='O2'
						select @label='Outside Process:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
						select @item_type_number=10
					end
					else
					begin
						select @item_type='A2'
						select @label='Activity:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
						select @item_type_number=9
					end
				end
				else
				begin
					select	@activity=activity_router.code,
						@sequence=sequence,
						@routertype=activity_codes.flow_route_window
					from 	activity_router
							join activity_codes on activity_router.code = activity_codes.code
					where 	parent_part=@part
						and part=@part

					if isnull(@activity,'')>''
					begin
						if @routertype = 'w_create_flow_route_outside_version2'
						begin
							select @item_type='O3'
							select @label='Outside Process:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
							select @item_type_number=10
						end
						else
						begin
							select @item_type='A3'
							select @label='Activity:'+@activity+' / Output:'+@part+' Eng.Level: ' + @eng_level
							select @item_type_number=9
						end
					end
					else
					begin
						if isnull(@substitute_part,'N')='Y'
							if isnull(@type,'M')='M'
							begin
								select @item_type='SM'
								select @label='Substitute (Material):'+@part+' Eng.Level: ' + @eng_level
								select @item_type_number=7
							end
							else
							begin
								select @item_type='ST'
								select @label='Substitute (Tool):'+@part+' Eng.Level: ' + @eng_level
								select @item_type_number=8
							end
						else
							if isnull(@type,'M')='M'
							begin
								select @item_type='CM'
								select @label='Component (Material):'+@part+' Eng.Level: ' + @eng_level
								select @item_type_number=5
							end
							else
							begin
								select @item_type='CT'
								select @label='Component (Tool):'+@part+' Eng.Level: ' + @eng_level
								select @item_type_number=6
							end
							
						select @activity=''
					end
				end
			end
			
			insert into #output_stack (
				parent_id,
				parent_item,
				item,
				item_level,
				item_type,
				item_label,
				activity,
				machine,
				parent_part,
				part,
				components,
				start_datetime,
				item_type_number,
				sequence )
			values	(@parent_id,
				@parent_part,
				@part,
				@item_level,
				@item_type,
				@label,
				@activity,
				'',
				@parent_part,
				@part,
				0,
				@start_datetime,
				@item_type_number,
				@sequence)
				
			select 	@new_item_id = max(item_id)
			from	#output_stack
			
			if isnull(@activity,'')>''
			begin
				if @item_type = 'O1' or @item_type = 'O2' or @item_type = 'O3'
				begin
					
					insert into #output_stack (
						parent_id,
						parent_item,
						item,
						item_level,
						item_type,
						item_label,
						activity,
						machine,
						parent_part,
						part,
						components,
						start_datetime,
						item_type_number,
						sequence )
					select 	@new_item_id,
						@part,
						machine,
						@item_level+1,
						'OP',
						'Primary Vendor:'+machine,
						@activity,
						machine,
						@parent_part,
						@part,
						0,
						null,
						4,
						0
					from	part_machine
					where 	part=@part
						and activity=@activity
						and sequence=1

					insert into #output_stack (
						parent_id,
						parent_item,
						item,
						item_level,
						item_type,
						item_label,
						activity,
						machine,
						parent_part,
						part,
						components,
						start_datetime,
						item_type_number,
						sequence )
					select	@new_item_id,
						@part,
						machine,
						@item_level+1,
						'OP',
						'Secondary Vendor:'+machine,
						@activity,
						machine,
						@parent_part,
						@part,
						0,
						null,
						4,
						0
					from	part_machine
					where 	part=@part
						and activity=@activity
						and sequence>1
						
				end
				else
				begin
					
					insert into #output_stack (
						parent_id,
						parent_item,
						item,
						item_level,
						item_type,
						item_label,
						activity,
						machine,
						parent_part,
						part,
						components,
						start_datetime,
						item_type_number,
						sequence )
					select	@new_item_id,
						@part,
						machine,
						@item_level+1,
						'MP',
						'Primary Machine:'+machine,
						@activity,
						machine,
						@parent_part,
						@part,
						0,
						null,
						1,
						0
					from 	part_machine
					where 	part=@part
						and activity=@activity
						and sequence=1

					insert into #output_stack (
						parent_id,
						parent_item,
						item,
						item_level,
						item_type,
						item_label,
						activity,
						machine,
						parent_part,
						part,
						components,
						start_datetime,
						item_type_number,
						sequence )
					select	@new_item_id,
						@part,
						machine,
						@item_level+1,
						'MS',
						'Secondary Machine:'+machine,
						@activity,
						machine,
						@parent_part,
						@part,
						0,
						null,
						2,
						0
					from 	part_machine
					where 	part=@part
						and activity=@activity
						and sequence>1

					insert into #output_stack (
						parent_id,
						parent_item,
						item,
						item_level,
						item_type,
						item_label,
						activity,
						machine,
						parent_part,
						part,
						components,
						start_datetime,
						item_type_number,
						sequence )
					select	#output_stack.item_id,
						pmt.machine,
						pmt.tool,
						@item_level+2,
						'MT',
						'Machine Tool:'+pmt.tool,
						'',
						pmt.machine,
						@parent_part,
						@part,
						0,
						null,
						3,
						0
					from 	part_machine as pm
						,part_machine_tool as pmt,
						#output_stack
					where 	pm.part=pmt.part
						and pm.machine=pmt.machine
						and pm.part=@part
						and pm.activity=@activity
						and #output_stack.activity = @activity
						and #output_stack.machine = pmt.machine
						and #output_stack.parent_part = @parent_part
						and #output_stack.part = @part
				end
			end

			if @mode=1
				insert into #stack (
					parent_id,
					parent_part,
					part,
					item_level,
					start_datetime,
					end_datetime,
					substitute_part,
					type,
					spid)
				select	@new_item_id,
					@part,
					part,
					@item_level+1,
					start_datetime,
					start_datetime,
					substitute_part,
					type,
					@@spid
				from 	bill_of_material_ec
				where 	parent_part=@part
					and start_datetime>@current_datetime
				order by part
			else if @mode=2
				insert into #stack (
					parent_id,
					parent_part,
					part,
					item_level,
					start_datetime,
					end_datetime,
					substitute_part,
					type,
					spid)
				select	@new_item_id,
					@part,
					part,
					@item_level+1,
					start_datetime,
					start_datetime,
					substitute_part,
					type,
					@@spid
				from 	bill_of_material_ec
				where 	parent_part=@part
				order by part
			else if @mode=3
				insert into #stack (
					parent_id,
					parent_part,
					part,
					item_level,
					start_datetime,
					end_datetime,
					substitute_part,
					type,
					spid)
				select 	@new_item_id,
					@part,
					part,
					@item_level+1,
					start_datetime,
					null,
					substitute_part,
					type,
					@@spid
				from 	bill_of_material_ec
				where 	parent_part=@part
					and start_datetime>=@user_datetime
					and ( end_datetime is null or end_datetime > @user_datetime)
				order by part
			else
				insert into #stack (
					parent_id,
					parent_part,
					part,
					item_level,
					start_datetime,
					end_datetime,
					substitute_part,
					type,
					spid)
				select 	@new_item_id,
					@part,
					part,
					@item_level+1,
					start_datetime,
					start_datetime,
					substitute_part,
					type,
					@@spid
				from 	bill_of_material_ec
				where 	parent_part=@part
					and start_datetime<=@current_datetime
					and(end_datetime>=@current_datetime or end_datetime is null)
				order by part

			select @rowcount=@@rowcount

			delete from #stack
			where 	item_level=@item_level
				and id = @stack_item_id

			update	#output_stack set
				components = @rowcount
			where	item_id = @new_item_id
				
			if @rowcount>0
				select @item_level=@item_level+1
		end
		else
			select @item_level=@item_level-1
	end

	select	#output_stack.parent_item,
		#output_stack.item,
		#output_stack.item_level,
		#output_stack.item_type,
		#output_stack.item_label,
		#output_stack.activity,
		#output_stack.machine,
		#output_stack.parent_part,
		#output_stack.part,
		0,
		0,
		0,
		#output_stack.components,
		#output_stack.start_datetime,
		#output_stack.item_type_number,
		#output_stack.sequence,
		#output_stack.parent_id,
		#output_stack.item_id
	from	#output_stack 
	order by item_level asc

commit transaction

GO
