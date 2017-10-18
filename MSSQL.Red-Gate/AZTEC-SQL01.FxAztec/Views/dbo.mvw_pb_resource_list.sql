SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_pb_resource_list] (
	resource_name,
	resource_type )
as select machine_no,
	1
from	machine
GO
