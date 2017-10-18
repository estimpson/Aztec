SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReportLibrary_ReportTypeList]
as
select
	ReportType = rl.report
,   Description = rl.description
,	ReportCount =
		(	select
				count(*)
			from
				dbo.report_library rlib
			where
				rlib.report = rl.report
		)
from
	dbo.report_list rl
GO
