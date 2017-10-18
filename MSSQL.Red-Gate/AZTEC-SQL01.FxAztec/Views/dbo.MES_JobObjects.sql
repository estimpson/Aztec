SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_JobObjects]
as
select
	woo.Serial
,	WODID = wod.RowID
,	woo.WorkOrderNumber
,	woo.WorkOrderDetailLine
,	woo.Status
,	woo.Type
,	woo.PartCode
,	woo.PackageType
,	woo.OperatorCode
,	woo.Quantity
,	woo.LotNumber
,	BoxLabelFormat = coalesce(od.box_label, oh.box_label, pp.label_format, pi.label_format)
,	woo.CompletionDT
,	woo.BackflushNumber
,	woo.UndoBackflushNumber
from
	dbo.WorkOrderObjects woo
	join dbo.WorkOrderHeaders woh
		on woh.WorkOrderNumber = woo.WorkOrderNumber
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = woo.WorkOrderNumber
		and wod.Line = woo.WorkOrderDetailLine
	left join dbo.order_header oh
		on oh.order_no = wod.SalesOrderNumber 
	left join dbo.order_detail od
		on od.id =
		(	select
				min(od1.id)
			from
				dbo.order_detail od1
			where
				od1.order_no = wod.SalesOrderNumber
				and od1.part_number = wod.PartCode
		)
	join dbo.part_inventory pi
		on pi.part = woo.PartCode
	left join dbo.part_packaging pp
		on pp.part = wod.PartCode
		and pp.code = coalesce
		(	woo.PackageType
		,	oh.package_type
		,	(	select
					min(code)
				from
					dbo.part_packaging pp2
				where
					pp2.part = wod.PartCode
					and
					(	pp2.code = woo.PackageType
						or pp2.quantity = coalesce(oh.standard_pack, pi.standard_pack)
					)
			)
		)
where
	woo.Status in
		(	select
				sd.StatusCode
			from
				FT.StatusDefn sd
			where
				sd.StatusTable = 'dbo.WorkOrderObjects'
				and sd.StatusName in ('New', 'Completed')
		)
GO
