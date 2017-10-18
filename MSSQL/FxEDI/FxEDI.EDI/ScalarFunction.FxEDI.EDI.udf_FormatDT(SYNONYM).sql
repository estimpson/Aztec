
/*
Create ScalarFunction.FxEDI.EDI.udf_FormatDT(SYNONYM).sql
*/

use FxEDI
go

if	objectpropertyex(object_id('EDI.udf_FormatDT'), 'BaseType') = 'FN' begin
	drop synonym EDI.udf_FormatDT
end
go

create synonym EDI.udf_FormatDT for FxUtilities.dbo.FormatDT
go

select
	objectpropertyex(object_id('EDI.udf_FormatDT'), 'BaseType')
