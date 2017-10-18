SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure	[dbo].[msp_scdatavalidation] (@part varchar(25) = null)
as
----------------------------------------------------------------------------------------------------------------------
--	msp_scdatavalidation : To identify the invalid data elements before running super cop
--
--	parameters:	None 
--
--	process:
--	1.	Declarations
--	2.	Declare temp tables
--	3.	Insert part or parts from either passed value or from order_detail as these are all top level parts
--	4.	Initilize
--	5.	Get the temp table count
--	6.	Process all the level one parts
--	7.	Initilize the required variables with initial values
--	8.	Delete temp tables
--	9.	Insert row into vbom temp table	
--		10.	Delete temp table
--		11.	Get components for this current part
--		12.	Check whether the parent part exists in the components list
--		13.	On count being > 0 write to err temp table
--			14.	Check whether the part already exists in the err list temp table
--			15.	On count being > 0 write to err temp table
--			16.	Check whether the part exists in the vbom temp table
--				17.	Get bomlevel & tree from the temp table
--			18.	Process all the component parts	
--			19.	Get the 1st part for processing		
--				20.	Check whether the part is found in vbom temp table
--					21.	Check whether the part already exists in the err list temp table
--					22.	On count being = 0 write to err temp table
--					23.	write data to other temp tables				
--				24.	Get the 1st part for processing		
--		25.	update the temp table set processed with 0
--		26.	Get the next unprocessed part		
--	27.	Get the temp table count
--	28.	Display results
--
--	Purpose:
--	Check for all null std_qty in bill_of_material_ec 
--	Check for all null parts_per_hour in part_machine 
--	Check for all null row_id & std_qty in order_detail
--	Check for dead start date based on setup time, due date & other parameters. ??

--	Process :
--	1.	Declarations
--	1.1	Check for infinite bom (ie call msp_findinfinitebom procedure ) 
--	2.	Initialize
--	3.	Demand with std_qty having null values
--	4.	Demand with row_id having null values 
--	5.	Check any demand is there, if so proceed further
--	6.	Bom parts with std qty being null for the current level parts
--	7.	Parts with parts per hour being null for the current level parts
--	8.	Check for qnty over parts per hour division & what it evaluates to (computation)
--	9.	Calculate the math to arrive at the start date
--	10.	Get components for all the level 1 parts
--			11.	Bom parts with std qty being null for the current level parts			
--			12.	Parts with parts per hour being null for the current level parts			
--			13.	Check for qnty over parts per hour division & what it evaluates to (computation)
--			14.	Calculate the math to arrive at the start date
--	15.	Verify count in the temp table
--	16.	Display results
--		
--	Development:	Harish Gubbi	2/9/00	Created	
--			Harish Gubbi	9/29/01	Modified. Increased the size of @airow variable
--							  Included '%' in the patindex string
------------------------------------------------------------------------------------------------------------------

--	1.	Declarations
declare	@current_level	integer

declare	@count integer,
	@currentpart	varchar(25),
	@parentpart	varchar(25),
	@ppart		varchar(25),
	@bomlevel	integer,
	@processed	smallint,
	@incrementor	integer,
	@foundcount	integer,
	@counter	integer,
	@found		integer,
	@tree		varchar(255),
	@airow		varchar(5),
	@pos		integer,
	@checkcount	integer,
	@rwcount	integer

--	2.	Declare temp tables
create	table #partsmain ( part varchar(25) null)

create	table #parts ( part varchar(25) null )

create	table #partext ( parentpart varchar(25) null,
			 part	varchar(25) null,
			 processed smallint null)

create	table #vbom (	part varchar(25) null,
			bomlevel integer null,
			airow	varchar(2) null,
			tree	varchar(255) null)

create	table #errlist (parentpart varchar(25) null,
			componentpart varchar(25) null)

create table #sctemp ( part varchar(25) not null,
			due datetime not null,
			qnty numeric(20,6) null,
			source integer null,
			origin numeric(8,0) null,
			id integer,
			rowno integer null )

create table #scoutput ( reason varchar(255))

--	3.	Insert part or parts from either passed value or from order_detail as these are all top level parts
if isnull(@part,'') = ''
begin
	insert	into #partsmain 
	select	distinct part_number
	from	order_detail od
		join order_header oh on oh.order_no = od.order_no 
	where	isnull(oh.status,'O') <> 'C'
	order by part_number
end
else
	insert	into #partsmain values ( @part ) 

--	4.	Initilize
select	@count = 0,
	@parentpart = '',
	@bomlevel = 1

--	5.	Get the temp table count
select	@parentpart = min ( part ),
	@count = count ( 1 ) 
from	#partsmain
where	part > @parentpart

--	6.	Process all the level one parts
while	@count > 0 
begin	-- 1b

--	7.	Initilize the required variables with initial values
	select	@incrementor = 1,
		@bomlevel = 1,
		@checkcount = 1,
		@ppart = @parentpart
	
--	8.	Delete temp tables
	delete	#vbom
	delete	#partext

--	9.	Insert row into vbom temp table	
	insert	into #vbom values ( @ppart, @bomlevel, '1', '-1-' )
	
	while @checkcount > 0 
	begin	-- 2b

--		10.	Delete temp table
		delete	#parts

--		11.	Get components for this current part
		insert	into #parts 
		select	part
		from	bill_of_material
		where	parent_part = @ppart
		order by part
		
--		12.	Check whether the parent part exists in the components list
		select	@foundcount = count ( 1 )
		from	#parts
		where	part = @ppart

--		13.	On count being > 0 write to err temp table
		if @foundcount > 0 
		begin	-- 3b
	
--			14.	Check whether the part already exists in the err list temp table
			select	@found = count ( 1 )
			from	#errlist
			where	parentpart = @ppart
	
--			15.	On count being > 0 write to err temp table
			if @found > 0 
				insert	into #errlist values ( @ppart, @ppart ) 
		end	-- 3b
		else
		begin	-- 4b
	
--			16.	Check whether the part exists in the vbom temp table
			select	@found = count ( 1 ) 
			from	#vbom
			where	part = @ppart
				
			if @found > 0 
			begin	-- 5b
	
--				17.	Get bomlevel & tree from the temp table
				select	@bomlevel = isnull(max(bomlevel),0) + 1,
					@tree = max(tree)
				from	#vbom
				where	part = @ppart
				
			end	-- 5b
	
--			18.	Process all the component parts	
			select	@currentpart = ''
	
--			19.	Get the 1st part for processing		
			select	@currentpart = min ( part ),
				@counter = count ( 1 )
			from	#parts
			where	part > @currentpart
				
			while @counter > 0 
			begin	-- 6b
	
--				20.	Check whether the part is found in vbom temp table
				select	@found = count ( 1 ) 
				from	#vbom
				where	part = @currentpart	
				
				if @found > 0 
				begin	-- 7b
					select	@airow = '%-' + airow + '-%'
					from	#vbom
					where	part = @currentpart	
					
					select	@pos = isnull(patindex ( @airow, @tree ),0) 
				end	-- 7b
				if @pos > 0 
				begin	-- 8b
				
--					21.	Check whether the part already exists in the err list temp table
					select	@found = count ( 1 )
					from	#errlist
					where	parentpart = @ppart and
						componentpart = @currentpart
					
--					22.	On count being = 0 write to err temp table
					if @found = 0 
					begin	-- 9b
						insert	into #errlist values ( @ppart, @currentpart ) 
						select	@counter = 0, @airow = '', @pos = 0 
					end	-- 9b	
				end	-- 8b
				else
				begin	-- 10b

--					23.	write data to other temp tables				
					insert	into #partext values ( @ppart, @currentpart, -1 )
					select	@incrementor = @incrementor + 1
					select	@tree = @tree + convert ( varchar, @incrementor ) + '-'
					insert	into #vbom values ( @currentpart, @bomlevel, convert ( varchar, @incrementor ), @tree ) 
				end	-- 10b
				
--				24.	Get the 1st part for processing		
				select	@currentpart = min ( part ),
					@counter = count ( 1 )
				from	#parts
				where	part > @currentpart
				
			end	-- 6b
		end	-- 4b

--		25.	update the temp table set processed with 0
		update	#partext set processed = 0 where part = @ppart

--		26.	Get the next unprocessed part		
		select	@ppart = min ( part ),
			@checkcount = count ( 1 )
		from	#partext
		where	processed < 0 

	end	-- 2b

--	27.	Get the temp table count
	select	@parentpart = min ( part ),
		@count = count ( 1 ) 
	from	#partsmain
	where	part > @parentpart
end	-- 1b

--	28.	Display results
--	select * from #vbom
--	1.1	Check for infinite boms
insert	into #scoutput (reason ) 
select  'Parent part ' + parentpart + ' with the component part ' + componentpart + ' is in a infinite bill of material' from #errlist

select	@count = count ( 1 ) 
from	#sctemp

if @count = 0 
begin	-- 0b

	--	Bom parts with std qty being null for the current level parts
	insert	into #scoutput (reason ) 
	select	'Parent part ' +bom.parent_part + ' with component part ' + bom.part + ' has null standard quantity '
	from	bill_of_material bom
	where	(bom.std_qty is null or bom.std_qty = 0 )
	
	--	Inserting parts with parts per hour with null or 0 value
	insert	into #scoutput (reason ) 
	select	'Part '+ part + ' with parts per hour having a 0 or a null value'
	from	part_machine
	where	parts_per_hour = 0 or parts_per_hour is null
	
	--	Inserting parts with duplicate row ids in order detail
	insert	into #scoutput (reason ) 
	select	distinct 'Sales Order no '+ convert ( varchar, od.order_no ) + ' has duplicate row ids '
	from	 order_detail od
	where	(select count(1) from order_detail od1 where od1.order_no = od.order_no and od1.row_id = od.row_id) > 1
	group by order_no, row_id

	--	Inserting parts with null std_qty in order detail
	insert	into #scoutput (reason ) 
	select	distinct 'Sales Order no '+ convert ( varchar, od.order_no ) +', sequence '+convert(varchar,sequence)+ ' & part ' + part_number + ' has null standard quantity '
	from	order_detail od
	where	(od.std_qty is null or od.std_qty = 0 ) 

	--	Inserting parts with null row_id in order detail
	insert	into #scoutput (reason ) 
	select	distinct 'Sales Order no '+ convert ( varchar, od.order_no ) +', sequence '+convert(varchar,sequence)+ ' & part ' + part_number + ' has null row id '
	from	order_detail od
	where	(od.row_id is null or od.row_id = 0 ) 
	
	--	15.	Verify count in the temp table
	select	@count = isnull(count ( 1 ),0)
	from	#scoutput
	
	if @count = 0 
		insert	into #scoutput (reason ) 
		values	('No problems reported in the data')
	else
		insert into #scoutput ( reason )
		values ( 'The above data problems have been identified, Fix the data problem before running super cop')
end	-- 0b
--	16.	Display results
select	reason from #scoutput
GO
