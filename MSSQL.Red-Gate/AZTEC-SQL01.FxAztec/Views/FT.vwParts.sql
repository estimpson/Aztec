SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwParts]
as
select
	PartCode = p.part
,	Description = p.name
,	CrossRef = p.cross_ref
,	GroupTechnology = p.group_technology
,	Commodity = c.id
,	PrimaryUsageGroupTechnology = (select max(group_no) from dbo.location where code in (select machine from dbo.part_machine where sequence = 1 and part in (select ParentPart from FT.vwBOM where ChildPart = p.part)))
,	PrimaryUsageMachine = (select max(machine) from dbo.part_machine where sequence = 1 and part in (select ParentPart from FT.vwBOM where ChildPart = p.part))
,	PrimarySource = coalesce
	(
		'Vendor:' + PartPurchasing.DefaultVendor,
		(select 'Machine:' + max(machine) from dbo.part_machine where part = p.part and sequence = 1)
	)
,	PrimaryTool = coalesce
	(
		(select 'Tool:' + max(nullif(process_id, 'NONE')) from dbo.part_machine where part = p.part and sequence = 1), ''
	)
,	DefaultFirmOrder = coalesce
	(
		'PO#:' + convert(varchar, PartPurchasing.DefaultPO),
		(select 'WO#:' + convert(varchar, max(workorder)) from dbo.workorder_detail where part = p.part)
	)
,	LeadDays = coalesce(PartPurchasing.LeadDays, 0)
,	PartType = pcd.class_name + ':' + ptd.type_name
,	StandardPack = coalesce
	(
		(select max(vendor_standard_pack) from dbo.part_vendor where part = p.part)
	,	pi.standard_pack
	)
,	StandardUnit = pi.standard_unit
,	StandardCost = ps.cost_cum
from
	dbo.part p
	join dbo.commodity c on
		p.commodity = c.id
	join dbo.part_class_definition pcd on
		p.class = pcd.class
	join dbo.part_type_definition ptd on
		p.type = ptd.type
	join dbo.part_inventory pi on
		p.part = pi.part
	join dbo.part_standard ps on
		p.part = ps.part
	left join
	(
		select
			ParCode = p.part
		,	DefaultVendor = min(coalesce(po.default_vendor, pd.vendor_code, ph.vendor_code, pv.vendor))
		,	DefaultPO = min(coalesce(po.default_po_number, pd.po_number, ph.po_number))
		,	LeadDays = min(pv.lead_time)
		from
			dbo.part p
			left join dbo.part_online po on
				po.part = p.part
			left join dbo.po_detail pd on
				pd.part_number = p.part
			left join dbo.po_header ph on
				ph.blanket_part = p.part
			left join dbo.part_vendor pv on
				pv.part = p.part and
				pv.vendor = coalesce (po.default_vendor, pd.vendor_code, ph.vendor_code, pv.vendor)
		group by
			p.part
	) PartPurchasing on p.part = PartPurchasing.ParCode
GO
