
/*
Create Synonym.FxEDI.FXSYS.USP_Calls.sql
*/

use FxEDI
go

--	drop table FXSYS.USP_Calls
--	select objectpropertyex(object_id('FXSYS.USP_Calls'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.USP_Calls'), 'BaseType') = 'U' begin
	drop synonym FXSYS.USP_Calls
end
go

create synonym FXSYS.USP_Calls for FxSYS.dbo.USP_Calls
go

