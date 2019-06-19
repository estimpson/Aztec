
/*
Create View.FxAztec.FXSYS.SPCalls_dbo_GetObjectBySerial.sql
*/

use FxAztec
go

--drop table FXSYS.SPCalls_dbo_GetObjectBySerial
if	objectproperty(object_id('FXSYS.SPCalls_dbo_GetObjectBySerial'), 'IsView') = 1 begin
	drop view FXSYS.SPCalls_dbo_GetObjectBySerial
end
go

create view FXSYS.SPCalls_dbo_GetObjectBySerial
as
select
	Serial = convert(int, substring(uc.InArguments, patindex('%@LookupSerial = %', uc.InArguments) + 16, patindex('%@TranDT = %', uc.InArguments) - (patindex('%@LookupSerial = %', uc.InArguments) + 16) - 2))
,	Result = convert(int, substring(uc.OutArguments, patindex('%@Result = %', uc.OutArguments) + 10, 99))
,	*
from
	FXSYS.USP_Calls uc
where
	uc.USP_Name = 'dbo.usp_GetObjectBySerial'
go

select
	*
from
	FXSYS.SPCalls_dbo_GetObjectBySerial scdgobs
order by
	scdgobs.BeginDT
go

