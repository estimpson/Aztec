SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_StatusName;0]
(	@StatusTable sysname
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
		and StatusCode = @StatusValue
	
	return
		@StatusName
end
GO
