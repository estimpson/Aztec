SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[Setup_LocationLabelFormats]
as
select
	LabelName = rl.name
,	ReportName = rl.report
,	LabelType = rl.type
,	ObjectName = rl.object_name
,	LibraryName = rl.library_name
,	PrintPreview = rl.preview
,	PrintSetup = rl.print_setup
,	PrinterName = rl.printer
,	Copies = rl.copies
from
	dbo.report_library rl
where
	rl.report = 'Location Label'
GO
