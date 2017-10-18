SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDIToyota].[Carriers]
as
select
	CarrierName = name
,	SCAC = scac
,	DefaultTransMode = trans_mode
from
	carrier
GO
