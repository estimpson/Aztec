SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FXSYS].[SPCalls_dbo_GetObjectBySerial]
as
select
	Serial = convert(int, substring(uc.InArguments, patindex('%@LookupSerial = %', uc.InArguments) + 16, patindex('%@TranDT = %', uc.InArguments) - (patindex('%@LookupSerial = %', uc.InArguments) + 16) - 2))
,	Result = convert(int, substring(uc.OutArguments, patindex('%@Result = %', uc.OutArguments) + 10, 99))
,	*
from
	FXSYS.USP_Calls uc
where
	uc.USP_Name = 'dbo.usp_GetObjectBySerial'
GO
