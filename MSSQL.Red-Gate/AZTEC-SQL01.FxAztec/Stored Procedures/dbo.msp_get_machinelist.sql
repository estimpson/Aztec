SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_get_machinelist] (@as_filterstring varchar(25)) as
begin -- (1b)
  if @as_filterstring is null or @as_filterstring='' or @as_filterstring='All'
     select machine_no
       from machine
      where status = 'R'
     order by machine_no
  else
     select m.machine_no
       from machine as m
       join location as l on l.code=m.machine_no and l.group_no=@as_filterstring
      where m.status = 'R' 
     order by m.machine_no
end -- (1e)
GO
