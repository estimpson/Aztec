

/*
Create view fx21st.custom.MES_MoldingJobColorLetDown
*/

--use fx21st
--go

--drop table custom.MES_MoldingJobColorLetDown
if	objectproperty(object_id('custom.MES_MoldingJobColorLetDown'), 'IsView') = 1 begin
	drop view custom.MES_MoldingJobColorLetDown
end
go

create view custom.MES_MoldingJobColorLetDown
as
select
	mjbomBase.WorkOrderNumber
,	mjbomBase.WODID
,	mjbomBase.WorkOrderDetailLine
,	mcl.BaseMaterialCode
,	mcl.ColorantCode
,	StdLetDownRate = mcl.LetDownRate
,	JobLetDownRate = mjbomColorant.XQty / (mjbomBase.XQty + mjbomColorant.XQty)
,	PieceWeight = (mjbomBase.XQty + mjbomColorant.XQty)
,	BaseMaterialWeight = mjbomBase.XQty
,	ColorantWeight = mjbomColorant.XQty
,	BaseMaterialWODBOMID = mjbomBase.WODBOMID
,	BaseMaterialBOMID = mjbomBase.BillOfMaterialID
,	ColorantMaterialWODBOMID = mjbomColorant.WODBOMID
,	ColorantMaterialBOMID = mjbomColorant.BillOfMaterialID
from
	dbo.MES_JobBillOfMaterials mjbomBase
	join custom.MoldingColorLetdown mcl
		join dbo.MES_JobBillOfMaterials mjbomColorant
			on mjbomColorant.ChildPart = mcl.ColorantCode
		on mcl.BaseMaterialCode = mjbomBase.ChildPart
		and mjbomColorant.WODID = mjbomBase.WODID
go

select
	*
from
	custom.MES_MoldingJobColorLetDown mmjcld
where
	WODID = 28