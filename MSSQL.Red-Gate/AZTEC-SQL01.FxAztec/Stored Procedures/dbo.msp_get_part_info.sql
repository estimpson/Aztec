SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_get_part_info] (
@part varchar(25), 
@qty numeric(20,6)) 
as
begin -- (1b)
------------------------------------------------------------------------------------------------
--	Modifications	08/08/02, HGP	Included seq as part of the where clause to get the 
--					primary machine of the part
------------------------------------------------------------------------------------------------
begin transaction
declare	@machine_no	varchar(10), 
	@due_date	datetime,     
	@process_id	varchar(25),
	@setup_time	numeric(15,7),
	@cycle_time	int,          
	@runtime	numeric(15,7),
	@cycle_unit	varchar(15), 
	@parts_per_hour numeric(20,6), 
	@parts_per_cycle numeric(20,6),
	@include_set_up char(1), 
	@parts_rate	int

select	@process_id = ISNULL(part_mfg.process_id,'NONE'),
	@cycle_time = part_mfg.cycle_time,
	@cycle_unit = part_mfg.cycle_unit,
	@parts_per_hour = ISNULL(part_mfg.parts_per_hour,1),
	@parts_per_cycle = part_mfg.parts_per_cycle,
	@setup_time = isnull(part_mfg.setup_time,0),     
	@runtime = isnull(@qty,0) * isnull((1 / isnull(part_mfg.parts_per_hour,1)),0),
	@machine_no = part_machine.machine,
	@due_date = getdate()
from	part_mfg,
	part_machine
where	(part_mfg.part=@part and part_machine.part=@part and part_machine.sequence=1)

IF @process_id IS NULL 
	select @process_id = 'NONE'

select	@include_set_up = isnull(include_setuptime,'N')
from	parameters

-- include setup time with runtime is if it is set to Y in parameter table
IF (@include_set_up = 'Y')
	select @runtime = isnull(@runtime,0) + isnull(@setup_time,0)

-- if the machine no is null get it from part_inventory table 
IF (@machine_no IS NULL)
	select	@machine_no=primary_location
	from	part_inventory
	where	(part=@part)

if (@cycle_time=0 or @cycle_time is null)
	select	@parts_rate=1
else 
	select	@parts_rate=0
	
if @due_date IS NULL
	select	@due_date = getdate()

select	@process_id, @cycle_time, @cycle_unit, @parts_per_hour, @parts_per_cycle, @setup_time,
	@runtime, @machine_no, @due_date, @due_date, @due_date, @due_date, @parts_rate, 
	isnull(@include_set_up,'N')
	
commit transaction

end -- (1e)
GO
