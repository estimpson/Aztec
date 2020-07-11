
/*
Create Synonym.FxAztec.FXSYS.usp_TableToHTML.sql
*/

use FxAztec
go

--	drop procedure FXSYS.usp_TableToHTML
--	select objectpropertyex(object_id('FXSYS.usp_TableToHTML'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.usp_TableToHTML'), 'BaseType') = 'P' begin
	drop synonym FXSYS.usp_TableToHTML
end
go

create synonym FXSYS.usp_TableToHTML for FxSYS.dbo.usp_TableToHTML
go

