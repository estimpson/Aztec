SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [FxFS].[udf_GetFilePathLocator]
(	@folderPath nvarchar(max)
)
returns hierarchyid
as
begin
--- <Body>
	declare
		@outputPath hierarchyid

	select
		@outputPath = FxFS.udf_GetNewChildHierarchyID(path_locator)
	from
		dbo.RawEDIData red
	where
		red.file_stream.GetFileNamespacePath() = @folderPath
		and red.is_directory = 1
--- </Body>

---	<Return>
	return
		@outputPath
end
GO
