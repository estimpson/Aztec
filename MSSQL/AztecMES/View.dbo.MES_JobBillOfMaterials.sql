
/*
Create view fx21st.dbo.MES_JobBillOfMaterials
*/

--use fx21st
--go

--drop table dbo.MES_JobBillOfMaterials
if	objectproperty(object_id('dbo.MES_JobBillOfMaterials'), 'IsView') = 1 begin
	drop view dbo.MES_JobBillOfMaterials
end
go

create view dbo.MES_JobBillOfMaterials
as
select
	wodbom.WorkOrderNumber
,	WODID = wod.RowID
,	wodbom.WorkOrderDetailLine
,	wodbom.Line
,	wodbom.Status
,	wodbom.Type
,	wodbom.ChildPart
,	Description = (select name from dbo.part where part = wodbom.ChildPart)
,	Commodity = (select commodity from dbo.part where part = wodbom.ChildPart)
,	wodbom.ChildPartSequence
,	wodbom.ChildPartBOMLevel
,	wodbom.BillOfMaterialID
,	wodbom.Suffix
,	wodbom.QtyPer
,	wodbom.XQty
,	wodbom.XScrap
,	wodbom.SubForRowID
,	wodbom.SubPercentage
,	WODBOMID = wodbom.RowID
,	ConsumptionPrinciple = (select HelpText from FT.StatusDefn where StatusTable = 'dbo.WorkOrderDetailBillOfMaterials' and StatusCode = wodbom.status)
,	msbp.BackflushingPrinciple
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = wodbom.WorkOrderNumber
		and wod.Line = wodbom.WorkOrderDetailLine
	join dbo.MES_SetupBackflushingPrinciples msbp
		on msbp.Type = 3
		and msbp.ID = wodbom.ChildPart
where
	wodbom.Status >= 0
go

select
	*
from
	dbo.MES_JobBillOfMaterials mjbom
go
