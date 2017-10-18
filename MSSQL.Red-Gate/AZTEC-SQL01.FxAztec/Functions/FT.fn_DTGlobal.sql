SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[fn_DTGlobal]
(	@GlobalName varchar (25) )
returns datetime
as
begin
---	<Body>
	declare	@ReturnDT datetime

	select	@ReturnDT = Value
	from	FT.DTGlobals
	where	Name = @GlobalName
---	<Body>

---	<Return>
	return	@ReturnDT
---	</Return>
end
GO
