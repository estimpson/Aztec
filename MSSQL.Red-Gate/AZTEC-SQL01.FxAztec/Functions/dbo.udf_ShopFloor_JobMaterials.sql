SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_ShopFloor_JobMaterials]
(
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailSequence int
)
returns @JobBOM table
(
	WODLine float
,	BOMLine float
,	BOMStatus int
,	BOMType int
,	BOMPartCode varchar(25)
,	ChildPartSequence int
,	ChildPartBOMLevel int
,	BillOfMaterialID int
,	Suffix int
,	QtyPer numeric(20,6)
,	XQty numeric(20,6)
,	XScrap numeric(20,6)
,	SubForRowID int
,	SubPercentage numeric(20,6)
,	AlternatePercentage numeric(20,6)
,	AdjustedAllocRate as (XQty * XScrap * case when SubForRowID > 0 then SubPercentage else 1 end * (1 - AlternatePercentage))
,	AdjustedConsupmtionRate as (XQty * case when SubForRowID > 0 then SubPercentage else 1 end * (1 - AlternatePercentage))
,	ProductionBalance numeric(20,6)
,	AllocatedQty numeric(20,6)
)
as
begin
--- <Body>
	insert
		@JobBOM
	(
		WODLine
	,	BOMLine
	,	BOMStatus
	,	BOMType
	,	BOMPartCode
	,	ChildPartSequence
	,	ChildPartBOMLevel
	,	BillOfMaterialID
	,	Suffix
	,	QtyPer
	,	XQty
	,	XScrap
	,	SubForRowID
	,	SubPercentage
	,	AlternatePercentage
	,	ProductionBalance
	)
	select
		WODLine = wodbom.WorkOrderDetailLine
	,	BOMLine = wodbom.Line
	,	BOMStatus = wodbom.Status
	,	BOMType = wodbom.Type
	,	BOMPartCode = wodbom.ChildPart
	,	ChildPartSequence = wodbom.ChildPartSequence
	,	ChildPartBOMLevel = wodbom.ChildPartBOMLevel
	,	BillOfMaterialID = wodbom.BillOfMaterialID
	,	Suffix = wodbom.Suffix
	,	QtyPer = wodbom.QtyPer
	,	XQty = wodbom.XQty
	,	XScrap = wodbom.XScrap
	,	SubForRowID = wodbom.SubForRowID
	,	SubPercentage = wodbom.SubPercentage
	,	AlternatePercentage = coalesce(Subs.AlternatePercentage, 0)
	,	ProductionBalance = case when wod.QtyRequired - QtyCompleted > 0 then wod.QtyRequired - QtyCompleted else 0 end
	from
		dbo.WorkOrderDetails wod
		join dbo.WorkOrderDetailBillOfMaterials wodbom on
			wod.WorkOrderNumber = wodbom.WorkOrderNumber
			and
				wod.Line = wodbom.WorkOrderDetailLine
/*			and
				wodbom.Status in
				(
					dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Used')
				,	dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use First')
				,	dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Use Last')
				,	dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Split')
				)
*/		join dbo.part_inventory pi on
			wodbom.ChildPart = pi.part
		left join
		(
			select
				SubForRowID
			,	AlternatePercentage = case when sum(SubPercentage) > 1 then 1 else sum(SubPercentage) end
			from
				dbo.WorkOrderDetails wod2
				join dbo.WorkOrderDetailBillOfMaterials wodbom2 on
					wod2.WorkOrderNumber = wodbom2.WorkOrderNumber
					and
						wod2.Line = wodbom2.WorkOrderDetailLine
			where
				wod2.WorkOrderNumber = @WorkOrderNumber
				and
					wod2.Sequence = @WorkOrderDetailSequence
			group by
				SubForRowID
		) Subs on
			wodbom.RowID = Subs.SubForRowID
	where
		wod.WorkOrderNumber = @WorkOrderNumber
		and
			wod.Sequence = @WorkOrderDetailSequence
	order by
		wodbom.ChildPartSequence

--- </Body>

---	<Return>
	return

	/*
		left join
		(
			select
				WorkOrderDetailLine
			,	WorkOrderDetailBillOfMaterialLine
			,	Serial
			,	QtyAvailable = (select std_quantity from dbo.object where serial = wodma.Serial)
			from
				dbo.WorkOrderDetailMaterialAllocations wodma
			where
				wodma.WorkOrderNumber = @WorkOrderNumber
				and
					wodma.Status = dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'New')
		) Alloc on
			wodbom.WorkOrderDetailLine = Alloc.WorkOrderDetailLine
			and
				wodbom.Line = Alloc.WorkOrderDetailBillOfMaterialLine
	*/
end
GO
