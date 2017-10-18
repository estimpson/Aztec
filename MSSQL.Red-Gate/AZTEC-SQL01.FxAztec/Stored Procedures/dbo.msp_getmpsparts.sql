SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_getmpsparts] (@machine varchar (10) ) as
select	distinct part
from	master_prod_sched
where	machine = @machine
GO
