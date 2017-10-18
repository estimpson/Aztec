SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[udf_GetShipmentPullSignalCalendar]
(	@StartDT datetime,
	@ShipTo varchar(10),
	@ShipFrom varchar(10),
	@ShipmentType char(1))
returns @OrderQuantitiesBucketed table
(	OrderNo numeric(8,0),
	PartNumber varchar(25),
	CustomerPart varchar(30),
	Suffix integer,
	PastQty numeric(20,6),
	PastHorizonType tinyint,
	Day1Qty numeric(20,6),
	Day1HorizonType tinyint,
	Day2Qty numeric(20,6),
	Day2HorizonType tinyint,
	Day3Qty numeric(20,6),
	Day3HorizonType tinyint,
	Day4Qty numeric(20,6),
	Day4HorizonType tinyint,
	Day5Qty numeric(20,6),
	Day5HorizonType tinyint,
	Day6Qty numeric(20,6),
	Day6HorizonType tinyint,
	Day7Qty numeric(20,6),
	Day7HorizonType tinyint,
	FutureQty numeric(20,6),
	FutureHorizonType tinyint,
	PastSequence int,
	Day1Sequence int,
	Day2Sequence int,
	Day3Sequence int,
	Day4Sequence int,
	Day5Sequence int,
	Day6Sequence int,
	Day7Sequence int,
	FutureSequence int)
as
begin
	insert	@OrderQuantitiesBucketed
	select	OrderNo,
		PartNumber,
		CustomerPart,
		Suffix,
		PastQty = Coalesce(Sum(case when ShipPulls.DueDT < @StartDT then OrderQty - ScheduledQty end), 0),
		PastHorizonType = Min(case when ShipPulls.DueDT < @StartDT then ShipPulls.HorizonType end),
		Day1Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 0 and ShipPulls.DueDT < @StartDT + 1 then OrderQty - ScheduledQty end), 0),
		Day1HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 0 and ShipPulls.DueDT < @StartDT + 1 then ShipPulls.HorizonType end),
		Day2Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 1 and ShipPulls.DueDT < @StartDT + 2 then OrderQty - ScheduledQty end), 0),
		Day2HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 1 and ShipPulls.DueDT < @StartDT + 2 then ShipPulls.HorizonType end),
		Day3Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 2 and ShipPulls.DueDT < @StartDT + 3 then OrderQty - ScheduledQty end), 0),
		Day3HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 2 and ShipPulls.DueDT < @StartDT + 3 then ShipPulls.HorizonType end),
		Day4Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 3 and ShipPulls.DueDT < @StartDT + 4 then OrderQty - ScheduledQty end), 0),
		Day4HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 3 and ShipPulls.DueDT < @StartDT + 4 then ShipPulls.HorizonType end),
		Day5Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 4 and ShipPulls.DueDT < @StartDT + 5 then OrderQty - ScheduledQty end), 0),
		Day5HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 4 and ShipPulls.DueDT < @StartDT + 5 then ShipPulls.HorizonType end),
		Day6Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 5 and ShipPulls.DueDT < @StartDT + 6 then OrderQty - ScheduledQty end), 0),
		Day6HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 5 and ShipPulls.DueDT < @StartDT + 6 then ShipPulls.HorizonType end),
		Day7Qty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 6 and ShipPulls.DueDT < @StartDT + 7 then OrderQty - ScheduledQty end), 0),
		Day7HorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 6 and ShipPulls.DueDT < @StartDT + 7 then ShipPulls.HorizonType end),
		FutureQty = Coalesce(Sum(case when ShipPulls.DueDT >= @StartDT + 7 then OrderQty - ScheduledQty end), 0),
		FutureHorizonType = Min(case when ShipPulls.DueDT >= @StartDT + 7 then ShipPulls.HorizonType end),
		PastSequence = Min(case when ShipPulls.DueDT < @StartDT then ShipPulls.Sequence end),
		Day1Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 0 and ShipPulls.DueDT < @StartDT + 1 then ShipPulls.Sequence end),
		Day2Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 1 and ShipPulls.DueDT < @StartDT + 2 then ShipPulls.Sequence end),
		Day3Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 2 and ShipPulls.DueDT < @StartDT + 3 then ShipPulls.Sequence end),
		Day4Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 3 and ShipPulls.DueDT < @StartDT + 4 then ShipPulls.Sequence end),
		Day5Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 4 and ShipPulls.DueDT < @StartDT + 5 then ShipPulls.Sequence end),
		Day6Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 5 and ShipPulls.DueDT < @StartDT + 6 then ShipPulls.Sequence end),
		Day7Sequence = Min(case when ShipPulls.DueDT >= @StartDT + 6 and ShipPulls.DueDT < @StartDT + 7 then ShipPulls.Sequence end),
		FutureSequence = Min(case when ShipPulls.DueDT >= @StartDT + 7 then ShipPulls.Sequence end)
	from	dbo.udf_GetShipmentPullSignals(@ShipTo, @ShipFrom, @ShipmentType) ShipPulls
	group by
		OrderNo,
		PartNumber,
		CustomerPart,
		Suffix
	order by
		PartNumber
	
	return
end
GO
