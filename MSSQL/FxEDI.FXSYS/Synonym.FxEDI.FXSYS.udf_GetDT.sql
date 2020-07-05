
/*
Create Synonym.FxEDI.FXSYS.udf_GetDT.sql
*/

use FxEDI
go

--	select objectpropertyex(object_id('FXSYS.udf_GetDT'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.udf_GetDT'), 'BaseType') = 'fn' begin
	drop synonym FXSYS.udf_GetDT
end
go

create synonym FXSYS.udf_GetDT for FxSYS.dbo.udf_GetDT
go

