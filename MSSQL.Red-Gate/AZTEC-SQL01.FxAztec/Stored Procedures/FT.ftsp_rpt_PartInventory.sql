SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [FT].[ftsp_rpt_PartInventory] 
as

-- [FT].[ftsp_rpt_PartInventory] 
select	
	p.part, 
	p.name,
	p.cross_ref,
	p.class,
	p.type, 
	sum(case when o.status = 'A' then std_quantity else 0 end) as ApprovedInv,
	sum(case when o.status = 'P' then std_quantity else 0 end) as OutsideProcessInv,
	sum(case when o.status not in ('P', 'A') then std_quantity else 0 end) as NonApprovedInv,
	sum(case when o.status = 'A' then std_quantity else 0 end)+sum(case when o.status = 'P' then std_quantity else 0 end)+sum(case when o.status not in ('P', 'A') then std_quantity else 0 end) as TotalInventory
from		
	part p
join		
	object o on p.part = o.part
group by
	p.part, 
	p.name,
	p.cross_ref,
	p.class,
	p.type
	
GO
