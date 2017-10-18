SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_StatusValue;1]
(	@StatusTable sysname
,	@StatusColumn sysname = 'Status'
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
		and StatusColumn = @StatusColumn
		and StatusName = @StatusName
	
	return
		@StatusCode
end
GO
