SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_GetProjectedInventory]
	@PartCode varchar(25)
as
declare
	@LeadDays smallint
,	@Today datetime

select
	@LeadDays = vp.LeadDays
from
	FT.vwParts vp
where
	PartCode = @PartCode

select
	@Today = convert(datetime, convert(int, getdate()))

declare
	@NetMPS table
(	EntryDT datetime
,	Consumption numeric (20,6)
,	PostConsumptionAccum numeric (20,6)
,	id int identity unique (EntryDT, id))

insert
	@NetMPS
(	EntryDT
,	Consumption
,	PostConsumptionAccum)
select
	EntryDT = convert (datetime, convert (int, case when vnm.RequiredDT < @Today then @Today else vnm.RequiredDT end))
,	Consumption = vnm.RequiredQty + vnm.OnHandQty
,	PostConsumptionAccum = vnm.PostRequiredAccum + vnm.PostOnHandAccum
from
	FT.vwNetMPS vnm
where
	PartCode = @PartCode

declare
	@Consumption table
(	EntryDT datetime primary key
,	Consumption numeric(20,6)
,	PostConsumptionAccum numeric(20,6))

insert
	@Consumption
select
	EntryDT
,	sum(Consumption)
,	max(PostConsumptionAccum)
from
	@NetMPS
group by
	EntryDT

declare
	@Replenishments table
(	EntryDT datetime primary key
,	Replenishment numeric(20,6)
,	PostAccum numeric(20,6))

insert
	@Replenishments
select
	EntryDT = convert (datetime, convert (int, case when vfo.FirmDueDT < @Today then @Today else vfo.FirmDueDT end))
,	Replenishment = sum(vfo.FirmQty)
,	PostAccum = max(vfo.PostAccum)
from
	FT.vwFirmOrders vfo
where
	PartCode = @PartCode
group by
	convert (datetime, convert (int, case when vfo.FirmDueDT < @Today then @Today else vfo.FirmDueDT end))

select
	Calendar.EntryDT
,	BeginningOnHand = coalesce (vp.OnHand, 0)
,	Consumption = coalesce(Consumption.Consumption, 0)
,	Replenishment = coalesce(Replenishment.Replenishment, 0)
,	ProjectedOnHand =
		coalesce (vp.OnHand, 0) +
		coalesce((select max(PostAccum) from @Replenishments r where r.EntryDT <= Calendar.EntryDT), 0) -
		coalesce((select max(PostConsumptionAccum) from @Consumption c where c.EntryDT <= Calendar.EntryDT), 0)
from
	FT.fn_Calendar(@Today, null, 'day', 1, @LeadDays * 2) Calendar
	left join @Consumption Consumption on
		Calendar.EntryDT = Consumption.EntryDT
	left join FT.vwPOH vp on
		vp.Part = @PartCode
	left join @Replenishments Replenishment on
		Calendar.EntryDT = Replenishment.EntryDT
union
select
	null
,	coalesce (vp.OnHand, 0)
,	0
,	0
,	coalesce (vp.OnHand, 0)
from
	FT.vwPOH vp
where
	vp.Part = @PartCode
GO
