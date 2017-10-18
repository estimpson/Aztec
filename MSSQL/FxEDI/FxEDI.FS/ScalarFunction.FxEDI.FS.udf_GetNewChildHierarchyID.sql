
/*
Create ScalarFunction.FxEDI.FS.udf_GetNewChildHierarchyID.sql
*/

use FxEDI
go

if	objectproperty(object_id('FS.udf_GetNewChildHierarchyID'), 'IsScalarFunction') = 1 begin
	drop function FS.udf_GetNewChildHierarchyID
end
go

create function FS.udf_GetNewChildHierarchyID
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
go

select
	FS.udf_GetNewChildHierarchyID(0xFE62E62FE602A18FCE925028E89136FA37AE3426E0)