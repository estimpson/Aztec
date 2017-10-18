SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDIToyota].[EXTDEF_TransModes]
as
select
	TransModeCode = code
,	TransModeDescription = description
from
	trans_mode
GO
