SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_DemandSummary]
(	@D1 smallint
,	@D2 smallint
,	@D3 smallint
,	@FirmDays smallint
)
returns @DemandSummary table
(	PartCode varchar(25)
,	Description varchar(100)
,	CrossRef varchar(50)
,	GroupTechnology varchar(25)
,	Commodity varchar(25)
,	PrimaryUsageGroupTechnology varchar(25)
,	PrimaryUsageMachine varchar(15)
,	PrimarySource varchar(23)
,	PrimaryTool varchar(60)
,	PartType varchar(51)
,	DefaultFirmOrder varchar(34)
,	FirmQty numeric(20,6)
,	FirmDT datetime
,	NewFirmQty numeric(20,6)
,	StandardPack numeric(20,6)
,	StandardUnit char(2)
,	QtyPast numeric(20,6)
,	Qty1 numeric(20,6)
,	Qty2 numeric(20,6)
,	Qty3 numeric(20,6)
,	QtyFuture numeric(20,6)
,	Days int
,	ShortageDT datetime
)
as
begin
	declare
		@Today datetime
	
	set	@Today = FT.fn_TruncDate('day', getdate())
		
	insert
		@DemandSummary
	(
		PartCode
	,	Description
	,	CrossRef
	,	GroupTechnology
	,	Commodity
	,	PrimaryUsageGroupTechnology
	,	PrimaryUsageMachine
	,	PrimarySource
	,	PrimaryTool
	,	PartType
	,	DefaultFirmOrder
	,	FirmQty
	,	FirmDT
	,	NewFirmQty
	,	StandardPack
	,	StandardUnit
	,	QtyPast
	,	Qty1
	,	Qty2
	,	Qty3
	,	QtyFuture
	,	Days
	,	ShortageDT
	)
	select
		vp.PartCode
	,   Description
	,   CrossRef
	,   GroupTechnology
	,   Commodity
	,   PrimaryUsageGroupTechnology
	,   PrimaryUsageMachine
	,   PrimarySource = case when PrimarySource like 'Machine:%' then substring(PrimarySource, 9, 15) else PrimarySource end
	,	PrimaryTool = case when PrimaryTool like 'Tool:%' then substring (PrimaryTool, 6, 60) else PrimaryTool end
	,   PartType
	,   DefaultFirmOrder
	,	FirmQty
	,	FirmDT = @Today + vp.LeadDays
	,	NewFirmQty = coalesce(case when FirmQty > QFirm then FirmQty else QFirm end, 0)
	,   StandardPack
	,   StandardUnit
	,   Demand.QP
	,   Demand.Q1
	,   Demand.Q2
	,   Demand.Q3
	,   Demand.QF
	,   Demand.Days
	,	Shortage.ShortageDT
	from
		FT.vwParts vp
		join
		(
			select
				PartCode = Part
			,	QP = coalesce(sum (case when datediff(day, getdate(), RequiredDT) < 0 then Balance end),0)
			,	Q1 = coalesce(sum (case when datediff(day, getdate(), RequiredDT) between 0 and @D1 then Balance end),0)
			,	Q2 = coalesce(sum (case when datediff(day, getdate(), RequiredDT) between @D1 + 1 and @D2 then Balance end),0)
			,	Q3 = coalesce(sum (case when datediff(day, getdate(), RequiredDT) between @D2 + 1 and @D3 then Balance end),0)
			,	QF = coalesce(sum (case when datediff(day, getdate(), RequiredDT) > @D3 then Balance end),0)
			,	QFirm = coalesce(sum (case when datediff(day, getdate(), RequiredDT) <= coalesce(nullif(@FirmDays, 0), vp.LeadDays) then Balance end),0)
			,	Days = datediff(day, getdate(), min(case when Balance > 0 then RequiredDT end))
			from
				FT.NetMPS nm
				join FT.vwParts vp on
					nm.Part = vp.PartCode
			group by
				Part
		) Demand on
			vp.PartCode = Demand.PartCode
		left join
		(	select
				PartCode
			,	FirmQty = max(PostAccum)
			from
				FT.vwFirmOrders vfo
			group by
				PartCode
		) FirmOrders on
			vp.PartCode = FirmOrders.PartCode
		left join
		(	select
				vnm.PartCode
			,	ShortageDT = min (case when vnm.RequiredDT < getdate() + vp.LeadDays then vnm.RequiredDT end)
			from
				FT.vwNetMPS vnm
				join FT.vwParts vp on
					vnm.PartCode = vp.PartCode
				left join FT.vwFirmOrders vfo on
					vnm.PartCode = vfo.PartCode and
					vnm.RequiredDT <= vfo.FirmDueDT and
					vnm.PostRequiredAccum > vfo.PostAccum
			where
				vnm.RequiredQty > 0
			group by
				vnm.PartCode
		) Shortage on
			vp.PartCode = Shortage.PartCode
	return
end
GO
