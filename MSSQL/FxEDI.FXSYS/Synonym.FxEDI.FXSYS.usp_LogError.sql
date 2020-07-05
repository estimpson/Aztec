
/*
Create Synonym.FxEDI.FXSYS.usp_LogError.sql
*/

use FxEDI
go

--	drop procedure FXSYS.usp_LogError
--	select objectpropertyex(object_id('FXSYS.usp_LogError'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.usp_LogError'), 'BaseType') = 'P' begin
	drop synonym FXSYS.usp_LogError
end
go

create synonym FXSYS.usp_LogError for FxSYS.dbo.usp_LogError
go

