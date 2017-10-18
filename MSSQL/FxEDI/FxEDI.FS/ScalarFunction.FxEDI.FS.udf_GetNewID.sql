
/*
Create ScalarFunction.FxEDI.FS.udf_GetNewID.sql
*/

use FxEDI
go

if	objectproperty(object_id('FS.udf_GetNewID'), 'IsScalarFunction') = 1 begin
	drop function FS.udf_GetNewID
end
go

create function FS.udf_GetNewID
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
go

