SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[Lesser]
(	@Value1 numeric(38,19)
,	@Value2 numeric(38,19)
)
returns numeric(38,19)
as
begin
--- <Body>

--- </Body>

---	<Return>
	return
		case
			when @Value2 is null then @Value1
			when @Value1 is null or @Value1 < @Value2 then @Value1
			else @Value2
		end
end
GO
