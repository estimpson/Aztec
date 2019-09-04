SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[udf_StatusName;1]
(	@StatusTable sysname
,	@StatusColumn sysname = 'Status'
,	@StatusValue int)
returns	sysname
as
begin
	declare
		@StatusName sysname
	
	select
		@StatusName = StatusName
	from
		FT.StatusDefn
	where
		StatusTable = @StatusTable
		and
			StatusColumn = @StatusColumn
		and
			StatusCode = @StatusValue
	
	return
		@StatusName
end


GO
