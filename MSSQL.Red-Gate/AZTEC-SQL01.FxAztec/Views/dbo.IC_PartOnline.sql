SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[IC_PartOnline]
as
select
	part.part
,	part.name
,	part.class
,	part.type
,	on_hand = po2.OnHand
,	po.min_onhand
,	po.max_onhand
,	re_order = po.max_onhand - po2.OnHand
,	on_order =
		(	select
				sum(mjl.QtyRequired - mjl.QtyCompleted)
			 from
				dbo.MES_JobList mjl
			 where
				mjl.PartCode = part.part
		) +
		(	select
				sum(quantity - received)
			from
				po_detail
			where
				po_detail.part_number = part.part
		)
,	supply = coalesce(pm.machine, po.default_vendor)
,	exhaust_date = nmps.DueDT
from
	dbo.part
	left join dbo.part_online po
		on po.part = part.part
	left join dbo.part_machine pm
		on pm.part = part.part
		and pm.sequence = 1
	left join
		(	select
				Part = p.part
			,	OnHand = coalesce(sum(o.std_quantity), 0)
			from
				dbo.part p
				left join dbo.object o
					on o.part = p.part
			group by
				p.part
		) po2
		on po2.Part = part.part
	left join
		(	select
				nm.Part
			,	DueDT = min(case when nm.Balance > 0 then nm.RequiredDT end)
			from
				dbo.NetMPS nm
			group by
				nm.Part
		) nmps
		on nmps.Part = part.part
GO
