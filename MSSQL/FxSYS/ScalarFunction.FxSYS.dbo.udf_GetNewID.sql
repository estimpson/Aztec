
/*
Create ScalarFunction.FxSYS.dbo.udf_GetNewID.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.udf_GetNewID'), 'IsScalarFunction') = 1 begin
	drop function dbo.udf_GetNewID
end
go

create function dbo.udf_GetNewID
(	--@parm parmdatatype
)
returns uniqueidentifier
as
begin
--- <Body>
	declare
		@newID uniqueidentifier =
			(	select
					max(gni.Value)
				from
					dbo.GetNewID gni
			)


--- </Body>

---	<Return>
	return
		@newID
end
go

select dbo.udf_GetNewID()