SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_TypeValue]
(	@TypeTable sysname
,	@TypeName sysname)
returns	int
as
begin
	declare
		@TypeCode int
	
	select
		@TypeCode = TypeCode
	from
		FT.TypeDefn
	where
		TypeTable = @TypeTable
		and	TypeName = @TypeName
	
	return
		@TypeCode
end
GO
