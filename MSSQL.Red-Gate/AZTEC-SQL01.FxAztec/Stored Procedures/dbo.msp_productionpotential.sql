SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_productionpotential]
(	@part	varchar (25) )
as

--	1.	Declare local variables.
declare @current_level int
declare @count int
declare	@childpart varchar (25)
declare	@onhand	numeric(20,6)
declare @bqty	numeric(20,6)
declare @cpart	varchar ( 25 )
declare	@pptime numeric(20,6)

--	2.	Create temporary table for exploding components.
create table #stack 
(
	part	varchar (25),
	stack_level	int,
	quantity numeric (20, 6)
) 


create table #bomparts (part varchar(25),
			levl integer,
			qty numeric(20,6) )		

create table #bparts (	part varchar(25),
			qty numeric ( 20, 6 ),
			onhand numeric(20,6) null)
			
--	3,	Declare trigger for looping through parts at current low level.
declare	childparts cursor for
select	part
from	#stack
where	stack_level = @current_level

--	4.	Initialize stack with part or list of top parts.
select @current_level = 1
if @part =  '' 
	insert into #stack
	select part, @current_level, 1
	from part
	where part not in ( select part from bill_of_material ) 

else
	insert into #stack
	values ( @part, @current_level, 1 )

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
	into	@childpart

	while @@fetch_status = 0
	begin

--	7.	Store level and total usage at this level for components.
		insert	#stack
		select	bom.part,
			@current_level + 1,
			bom.quantity * (
			select	sum ( #stack.quantity )
			from	#stack
			where	#stack.part = @childpart and
				#stack.stack_level = @current_level )
		from	bill_of_material as bom
		where	bom.parent_part = @childpart

		select	@count = 1

		fetch	childparts
		into	@childpart
	end

	close childparts
	
--	8.	Continue incrementing level as long as new components are added.
	if @count = 1
		select @current_level = @current_level + 1
end

--	9.	Deallocate components cursor.
deallocate childparts

--	10.	Insert the parts into another temp table
insert into #bomparts
select part, max ( stack_level ), sum ( quantity )
from #stack
group by part
order by max ( stack_level )

--	11.	Insert the parts & onhand into another temp table
insert into #bparts
select	bmp.part,
	bmp.qty,
	isnull(pol.on_hand,0)
from	#bomparts bmp
	join part_online pol on pol.part = bmp.part

--	12.	Get Min on hand from the temp table
select	@onhand = isnull(min(onhand),0) from #bparts

--	13.	Get the part & bom qty for that onhand
select	@cpart = part,
	@bqty  = qty
from	#bparts
where	onhand = @onhand

--	14.	Get the parts per hour from part machine 
select	@pptime = parts_per_hour
from	part_mfg
where	part = @cpart

--	12.	Return result set.	
select @cpart part, @onhand onhand, (isnull((@onhand * @bqty),0)/isnull(@pptime,1)) pptime
GO
