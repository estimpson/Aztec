
/*
Create Synonym.FxEDI.FXSYS.usp_PrintError.sql
*/

use FxEDI
go

--	drop procedure FXSYS.usp_PrintError
--	select objectpropertyex(object_id('FXSYS.usp_PrintError'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.usp_PrintError'), 'BaseType') = 'P' begin
	drop synonym FXSYS.usp_PrintError
end
go

create synonym FXSYS.usp_PrintError for FxSYS.dbo.usp_PrintError
go

