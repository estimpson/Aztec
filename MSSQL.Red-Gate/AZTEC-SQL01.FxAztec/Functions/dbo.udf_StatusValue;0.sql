SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_StatusValue;0]
(	@StatusTable sysname
,	@StatusName sysname)
returns	int
as
begin
	declare
		@StatusCode int
	
	select
		@StatusCode = StatusCode
	from
		FT.StatusDefn
	where
		StatusTable = @StatusTable
		and StatusName = @StatusName
	
	return
		@StatusCode
end
GO
