
/*
Create ScalarFunction.FxAztec.EDI.udf_FormatDT(SYNONYM).sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.udf_FormatDT'), 'IsScalarFunction') = 1 begin
	drop function EDI.udf_FormatDT
end
go

if	objectpropertyex(object_id('EDI.udf_FormatDT'), 'BaseType') = 'FN' begin
	drop synonym EDI.udf_FormatDT
end
go

create synonym EDI.udf_FormatDT for FxUtilities.dbo.FormatDT
go
