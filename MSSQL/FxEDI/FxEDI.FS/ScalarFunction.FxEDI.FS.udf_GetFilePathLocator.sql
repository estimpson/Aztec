/*
Create ScalarFunction.FxEDI.FS.udf_GetFilePathLocator.sql
*/

use FxEDI
go

if	objectproperty(object_id('FS.udf_GetFilePathLocator'), 'IsScalarFunction') = 1 begin
	drop function FS.udf_GetFilePathLocator
end
go

create function FS.udf_GetFilePathLocator
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
go

select
	FS.udf_GetFilePathLocator('\RawEDIData\Outbound')
