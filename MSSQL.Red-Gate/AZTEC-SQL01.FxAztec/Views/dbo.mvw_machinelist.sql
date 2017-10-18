SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_machinelist] 
	(machine,
	sequence,
	part ) 
as
select	part_machine.machine,   
	part_machine.sequence,
	part_machine.part
from	part_machine  
where	part_machine.machine > '' 
--	and part_machine.sequence <= 6 -- needs to be included for guardian
GO
