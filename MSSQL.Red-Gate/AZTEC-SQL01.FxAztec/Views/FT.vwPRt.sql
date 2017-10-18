SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwPRt]
(	Part,
	BufferTime,
	RunRate,
	CrewSize )
as
--	Description:
--	Use part_mfg view because it only pulls primary machine.
select	Part = Part.Part,
	BufferTime = 1,
	RunRate = min ( 1 / part_machine.parts_per_hour ),
	CrewSize = min ( part_machine.crew_size )
from	dbo.part Part
	left outer join dbo.part_machine part_machine on Part.Part = part_machine.part and
		part_machine.sequence = 1 and
		part_machine.parts_per_hour > 0
group by
	Part.Part
having	Count (1) = 1
GO
