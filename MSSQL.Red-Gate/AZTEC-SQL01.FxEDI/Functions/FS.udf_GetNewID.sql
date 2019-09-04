SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FS].[udf_GetNewID]
(
)
returns uniqueidentifier
as
begin
--- <Body>
	declare
		@newID uniqueidentifier

	select
		@newID = gni.Value
	from
		FS.GetNewID gni
--- </Body>

---	<Return>
	return
		@newID
end
GO
