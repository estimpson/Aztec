
/*
Create Synonym.FxEDI.FXSYS.Rows.sql
*/

use FxEDI
go

--	drop table FXSYS.Rows
--	select objectpropertyex(object_id('FXSYS.Rows'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.Rows'), 'BaseType') = 'U' begin
	drop synonym FXSYS.Rows
end
go

create synonym FXSYS.Rows for FxSYS.dbo.Rows
go

