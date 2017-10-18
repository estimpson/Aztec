SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_low_level]
(	@part	varchar (25) )
as

--	1.	Declare local variables.
declare @current_level int
declare @count int
declare @countnew int
declare	@childpart varchar (25)

--	2.	Create temporary table for exploding components.
create table #stack 
(
	part	varchar (25),
	stack_level	int,
	quantity numeric (20, 6)
) 

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
	
select	@count = isnull(count(1),0)
from	#stack	
where	stack_level = @current_level

--	5.	If rows found, loop through current level, adding children.
while @count > 0
begin
	declare	childparts cursor for
	select	part
	from	#stack
	where	stack_level = @current_level

--	6.	Add components for each part at current level using cursor.
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
			select	sum ( isnull(#stack.quantity,0) )
			from	#stack
			where	#stack.part = @childpart and
				#stack.stack_level = @current_level )
		from	bill_of_material as bom
		where	bom.parent_part = @childpart

		fetch	childparts
		into	@childpart

	end

	close	childparts

	--	9.	Deallocate components cursor.
	deallocate childparts


--	8.	Continue incrementing level as long as new components are added.
	select @current_level = @current_level + 1
		
	select	@count = isnull(count(1),0)
	from	#stack	
	where	stack_level = @current_level
	
end	

--	10.	Return result set.
select part, max ( stack_level ), sum ( quantity )
from #stack
group by part
order by max ( stack_level )

--	11.	Return.
if @@rowcount > 0
	return 0
else
	return 100
GO
