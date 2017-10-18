
/*
Create view dbo.MES_JobObjects
*/

--use fx21st
--go

--drop table dbo.MES_JobObjects
if	objectproperty(object_id('dbo.MES_JobObjects'), 'IsView') = 1 begin
	drop view dbo.MES_JobObjects
end
go

create view dbo.MES_JobObjects
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
go

select
	mjo.Serial
,	mjo.WODID
,	mjo.WorkOrderNumber
,	mjo.WorkOrderDetailLine
,	mjo.Status
,	mjo.Type
,	mjo.PartCode
,	mjo.PackageType
,	mjo.OperatorCode
,	mjo.Quantity
,	mjo.LotNumber
,	mjo.BoxLabelFormat
,	mjo.CompletionDT
,	mjo.BackflushNumber
,	mjo.UndoBackflushNumber
from
	MES_JobObjects mjo
go
