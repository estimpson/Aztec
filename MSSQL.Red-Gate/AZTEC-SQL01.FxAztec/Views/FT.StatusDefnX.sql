SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [FT].[StatusDefnX]
as
select
	StatusTable
,	StatusCode
,	StatusName
,	HelpText
from
	FT.StatusDefn sd
GO
