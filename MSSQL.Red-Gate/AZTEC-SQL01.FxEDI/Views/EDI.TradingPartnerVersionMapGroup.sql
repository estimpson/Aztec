SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [EDI].[TradingPartnerVersionMapGroup]
as
Select 
	distinct
	ed.TradingPartner,
	ed.version,
	ed.Type,
	tp.EDIMapCode
From
	EDI.EDIdocuments ed
join
	EDI.TradingPartners tp on tp.TradingPartnerCode = TradingPartner



GO
