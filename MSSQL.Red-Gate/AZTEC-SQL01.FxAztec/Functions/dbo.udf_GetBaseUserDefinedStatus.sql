SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetBaseUserDefinedStatus]
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
GO
