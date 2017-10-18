
/*
Create ScalarFunction.Fx.dbo.udf_GetBaseUserDefinedStatus.sql
*/

--use Fx
--go

if	objectproperty(object_id('udf_GetBaseUserDefinedStatus'), 'IsScalarFunction') = 1 begin
	drop function udf_GetBaseUserDefinedStatus
end
go

create function udf_GetBaseUserDefinedStatus
(	@Status char(1)
)
returns varchar(30)
as
begin
--- <Body>
	declare
		@userDefinedStatus varchar(30)

	select
		@userDefinedStatus = uds.display_name
	from
		dbo.user_defined_status uds
	where
		type = @Status
		and base = 'Y'
--- </Body>

---	<Return>
	return
		@userDefinedStatus
end
go

