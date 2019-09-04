SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FS].[udf_GetNewChildHierarchyID]
(	@ParentHierarchyID hierarchyid
)
returns hierarchyid
as
begin
--- <Body>
	declare
		@childHierarchyID hierarchyid
    ,	@newID1 uniqueidentifier = FS.udf_GetNewID()
	,	@newID2 uniqueidentifier = FS.udf_GetNewID()
	,	@newID3 uniqueidentifier = FS.udf_GetNewID()

	set	@childHierarchyID =
		convert
		(	hierarchyid
		,	@ParentHierarchyID.ToString() +
				convert
				(	varchar(20)
				,	convert
					(	bigint
					,	substring
						(	convert
							(	binary(16)
							,	@newID1
							)
						,	1
						,	6
						)
					)
				) + '.' +
				convert
				(	varchar(20)
				,	convert
					(	bigint
					,	substring
						(	convert
							(	binary(16)
							,	@newID2
							)
						,	7
						,	6
						)
					)
				) + '.' +
				convert
				(	varchar(20)
				,	convert
					(	bigint
					,	substring
						(	convert
							(	binary(16)
							,	@newID3
							)
						,	13
						,	4
						)
					)
				) + '/'
		)
--- </Body>

---	<Return>
	return
		@childHierarchyID

end
GO
