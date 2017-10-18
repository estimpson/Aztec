SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [FT].[SecurityAccess]
as
select
	SecurityID
,	ResourceID
,	Status = 0
,	Type = 0
from
	dbo.ufn_GetUserAccess()


GO
