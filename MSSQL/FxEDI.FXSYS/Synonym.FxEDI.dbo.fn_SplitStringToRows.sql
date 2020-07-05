
/*
Create Synonym.FxEDI.dbo.fn_SplitStringToRows.sql
*/

use FxEDI
go

--	select objectpropertyex(object_id('dbo.fn_SplitStringToRows'), 'BaseType')
if	objectpropertyex(object_id('dbo.fn_SplitStringToRows'), 'BaseType') = 'TF' begin
	drop synonym dbo.fn_SplitStringToRows
end
go

create synonym dbo.fn_SplitStringToRows for FxSYS.dbo.fn_SplitStringToRows
go

