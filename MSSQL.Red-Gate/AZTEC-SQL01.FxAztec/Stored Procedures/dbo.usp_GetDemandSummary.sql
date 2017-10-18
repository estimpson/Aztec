SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_GetDemandSummary]
	@D1 smallint
,	@D2 smallint
,	@D3 smallint
,	@FirmDays smallint = 0
,	@PartCodeP varchar(25) = '%'
,	@DescriptionP varchar(100) = '%'
,	@CrossRefP varchar(25) = '%'
,	@GroupTechP varchar(25) = '%'
,	@CommodityP varchar(25) = '%'
,	@PrimaryUsageGroupTechP varchar(25) = '%'
,	@PrimaryUsageMachineP varchar(25) = '%'
,	@PrimarySourceP varchar(25) = '%'
,	@PrimaryToolP varchar(25) = '%'
,	@PartTypeP varchar(25) = '%'
as
select
	PartCode
,   Description
,   CrossRef
,   GroupTechnology
,   Commodity
,   PrimaryUsageGroupTechnology
,   PrimaryUsageMachine
,   PrimarySource
,	PrimaryTool
,   PartType
,	UseDefaultFirmOrder = case when DefaultFirmOrder > '' then 1 else 0 end
,   DefaultFirmOrder
,	FirmQty
,	FirmDT
,	NewFirmQty
,   StandardPack
,   StandardUnit
,   QtyPast
,   Qty1
,   Qty2
,   Qty3
,   QtyFuture
,   Days
,   ShortageDT
from
	dbo.udf_DemandSummary(@D1, @D2, @D3, @FirmDays) Demand
where
	PartCode like coalesce (@PartCodeP, '%')
	and
		Description like coalesce (@DescriptionP, '%')
	and
		CrossRef like coalesce (@CrossRefP, '%')
	and
		GroupTechnology like coalesce (@GroupTechP, '%')
	and
		Commodity like coalesce (@CommodityP, '%')
	and
		PrimaryUsageGroupTechnology like coalesce (@PrimaryUsageGroupTechP, '%')
	and
		PrimaryUsageMachine like coalesce (@PrimaryUsageMachineP, '%')
	and
		PrimarySource like coalesce (@PrimarySourceP, '%')
	and
		PrimaryTool like coalesce (@PrimaryToolP, '%')
	and
		PartType like coalesce (@PartTypeP, '%')
order by
	Demand.PartCode
GO
