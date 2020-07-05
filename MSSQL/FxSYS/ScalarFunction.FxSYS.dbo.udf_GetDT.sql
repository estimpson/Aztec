
/*
Create ScalarFunction.FxSYS.dbo.udf_GetDT.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.udf_GetDT'), 'IsScalarFunction') = 1 begin
	drop function dbo.udf_GetDT
end
go

create function dbo.udf_GetDT
(	@Format varchar(12)
,	@VarcharValue varchar(12)
)
returns datetime
as
begin
--- <Body>
	declare
		@Result datetime

	set	@Result =
		case @Format
			when 'CCYYMMDDHHMM'
				then convert(datetime, substring(@VarcharValue, 1, 8) + ' ' + substring(@VarcharValue, 9, 2) + ':' + substring(@VarcharValue, 11, 2))
			when 'CCYYMMDD'
				then convert(datetime, @VarcharValue)
			when 'YYMMDD'
				then convert(datetime, @VarcharValue)
			when 'CCYYWW'
				then dateadd
					(	wk
					,	convert(int, substring(@VarcharValue, 5, 2))
					,	convert(datetime, left(@VarcharValue, 4)+'0101')
					) +
					(	1 - datepart(dw, convert(datetime, left(@VarcharValue, 4)+'0101'))
					)
		end
--- </Body>

---	<Return>
	return
		@Result
end
go

select
	dbo.udf_GetDT('CCYYMMDDHHMM', '201906240536')
,	dbo.udf_GetDT('CCYYMMDD', '20190624')
,	dbo.udf_GetDT('YYMMDD', '190624')
,	dbo.udf_GetDT('CCYYWW', '201925')
