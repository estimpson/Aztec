SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create function [monitor].[udf_Trim]
(	@Value varchar (8000))
returns varchar (8000)
begin
	set	@Value = ltrim (rtrim (@Value))

	while	Replace (@Value, '  ', ' ') != @Value begin
		set	@Value = Replace (@Value, '  ', ' ')
	end

	return	@Value
end
GO
