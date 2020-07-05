
/*
Create Synonym.FxEDI.FXSYS.usp_LongPrint.sql
*/

use FxEDI
go

--	drop procedure FXSYS.usp_LongPrint
--	select objectpropertyex(object_id('FXSYS.usp_LongPrint'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.usp_LongPrint'), 'BaseType') = 'P' begin
	drop synonym FXSYS.usp_LongPrint
end
go

create synonym FXSYS.usp_LongPrint for FxSYS.dbo.usp_LongPrint
go

