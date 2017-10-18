SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [FT].[vw_getdate]
AS
Select	ft.fn_TruncDate('wk',GETDATE() ) as CurrentSunday, 
		ft.fn_TruncDate('m',GETDATE() ) as FirstDOM,  
		ft.fn_TruncDate('dd',GETDATE() ) as CurrentDate,
		Dateadd(dd,1,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkMonday,
		Dateadd(dd,2,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkTuesday,
		Dateadd(dd,3,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkWednesday,
		Dateadd(dd,4,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkThursday,
		Dateadd(dd,5,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkFriday,
		Dateadd(dd,6,ft.fn_TruncDate('wk',GETDATE() )) as CurrentWkSaturday
GO
