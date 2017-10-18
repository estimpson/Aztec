
/*
Create Procedure.FxEDI.EDI.usp_CommandShell_Execute(SYNONYM).sql
*/

use FxEDI
go

if	objectpropertyex(object_id('EDI.usp_CommandShell_Execute'), 'BaseType') = 'P' begin
	drop synonym EDI.usp_CommandShell_Execute
	--drop procedure EDI.usp_CommandShell_Execute
end
go

create synonym EDI.usp_CommandShell_Execute for FxUtilities.dbo.usp_CommandShell_Execute
go

