SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FS].[udf_GetFilePathLocator]
(	@folderPath nvarchar(max)
)
returns hierarchyid
as
begin
--- <Body>
	declare
		@outputPath hierarchyid

	select
		@outputPath = FS.udf_GetNewChildHierarchyID(path_locator)
	from
		dbo.RawEDIData re
	where
		re.file_stream.GetFileNamespacePath() = @folderPath
--- </Body>

---	<Return>
	return
		@outputPath
end
GO
