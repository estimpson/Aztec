
/*
Create ScalarFunction.FxSYS.dbo.udf_GetNewChildHierarchyID.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.udf_GetNewChildHierarchyID'), 'IsScalarFunction') = 1 begin
	drop function dbo.udf_GetNewChildHierarchyID
end
go

create function dbo.udf_GetNewChildHierarchyID
(	@ParentHierarchyID hierarchyid
)
returns hierarchyid
as
begin
--- <Body>
	declare
		@childHierarchyID hierarchyid
	,	@newID1 uniqueidentifier = dbo.udf_GetNewID()
	,	@newID2 uniqueidentifier = dbo.udf_GetNewID()
	,	@newID3 uniqueidentifier = dbo.udf_GetNewID()

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
		)--- </Body>

---	<Return>
	return
		@childHierarchyID
end
go

select dbo.udf_GetNewChildHierarchyID ('/')
go

