SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_MES_GetJobXRt]
(	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
)
returns
	@XRt table
(	RowID int not null IDENTITY(1, 1) primary key nonclustered
,	Hierarchy varchar(900) unique clustered
,	TopPart varchar(25)
,	ChildPart varchar(25)
,	BOMID int
,	Sequence tinyint
,	BOMLevel tinyint
,	Suffix int
,	XQty numeric(30,12)
,	XScrap numeric(30,12)
,	XSuffix numeric(30,12)
,	SubForBOMID int
,	SubRate numeric(20,6)
,	BOMStatus int
)
as
begin
--- <Body>
	insert
		@XRt
	select
		Hierarchy = '/0'
	,	TopPart = wod.PartCode
	,	ChildPart = wod.PartCode
	,	BOMID = null
	,	Sequence = 0
	,	BOMLevel = 0
	,	Suffix = null
	,	XQty = 1
	,	XScrap = 1
	,	XSuffix =  1
	,	SubForBOMID = null
	,	SubPercentage = null
	,	BOMStatus = 0
	from
		dbo.WorkOrderDetails wod
	where
		wod.WorkOrderNumber = @WorkOrderNumber
		and wod.Line = @WorkOrderDetailLine

	insert
		@XRt
	select
		Hierarchy = '/0/' + convert(varchar, wodbom.ChildPartSequence)
	,	TopPart = wod.PartCode
	,	ChildPart = wodbom.ChildPart
	,	BOMID = wodbom.RowID
	,	Sequence = wodbom.ChildPartSequence --row_number() over (order by wodbom.ChildPartSequence)
	,	BOMLevel = wodbom.ChildPartBOMLevel
	,	Suffix = wodbom.Suffix
	,	XQty = wodbom.XQty
	,	XScrap = wodbom.XScrap
	,	XSuffix =  1
	,	SubForBOMID = wodbom.SubForRowID
	,	SubPercentage = wodbom.SubPercentage
	,	BOMStatus = wodbom.Status
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = @WorkOrderNumber
			and wod.Line = @WorkOrderDetailLine
	where
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
		and wodbom.Status >= 0
		and wodbom.ChildPartBOMLevel = 1
	order by
		wodbom.ChildPartSequence

	insert
		@XRt
	select
		Hierarchy = xr.Hierarchy + '/' + convert(varchar, wodbom.ChildPartSequence)
	,	TopPart = wod.PartCode
	,	ChildPart = wodbom.ChildPart
	,	BOMID = wodbom.RowID
	,	Sequence = wodbom.ChildPartSequence --row_number() over (order by wodbom.ChildPartSequence)
	,	BOMLevel = wodbom.ChildPartBOMLevel
	,	Suffix = wodbom.Suffix
	,	XQty = wodbom.XQty
	,	XScrap = wodbom.XScrap
	,	XSuffix =  1
	,	SubForBOMID = wodbom.SubForRowID
	,	SubPercentage = wodbom.SubPercentage
	,	BOMStatus = wodbom.Status
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = @WorkOrderNumber
			and wod.Line = @WorkOrderDetailLine
		join @XRt xr
			on xr.BOMLevel = wodbom.ChildPartBOMLevel - 1
			and xr.Sequence =
			(	select
					max(xr1.Sequence)
				from
					@XRt xr1
				where
					xr1.Sequence < wodbom.ChildPartSequence
			)
	where
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
		and wodbom.Status >= 0
		and wodbom.ChildPartBOMLevel = 2
	order by
		wodbom.ChildPartSequence

	insert
		@XRt
	select
		Hierarchy = xr.Hierarchy + '/' + convert(varchar, wodbom.ChildPartSequence)
	,	TopPart = wod.PartCode
	,	ChildPart = wodbom.ChildPart
	,	BOMID = wodbom.RowID
	,	Sequence = wodbom.ChildPartSequence --row_number() over (order by wodbom.ChildPartSequence)
	,	BOMLevel = wodbom.ChildPartBOMLevel
	,	Suffix = wodbom.Suffix
	,	XQty = wodbom.XQty
	,	XScrap = wodbom.XScrap
	,	XSuffix =  1
	,	SubForBOMID = wodbom.SubForRowID
	,	SubPercentage = wodbom.SubPercentage
	,	BOMStatus = wodbom.Status
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = @WorkOrderNumber
			and wod.Line = @WorkOrderDetailLine
		join @XRt xr
			on xr.BOMLevel = wodbom.ChildPartBOMLevel - 1
			and xr.Sequence =
			(	select
					max(xr1.Sequence)
				from
					@XRt xr1
				where
					xr1.Sequence < wodbom.ChildPartSequence
			)
	where
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
		and wodbom.Status >= 0
		and wodbom.ChildPartBOMLevel = 3
	order by
		wodbom.ChildPartSequence

	insert
		@XRt
	select
		Hierarchy = xr.Hierarchy + '/' + convert(varchar, wodbom.ChildPartSequence)
	,	TopPart = wod.PartCode
	,	ChildPart = wodbom.ChildPart
	,	BOMID = wodbom.RowID
	,	Sequence = wodbom.ChildPartSequence --row_number() over (order by wodbom.ChildPartSequence)
	,	BOMLevel = wodbom.ChildPartBOMLevel
	,	Suffix = wodbom.Suffix
	,	XQty = wodbom.XQty
	,	XScrap = wodbom.XScrap
	,	XSuffix =  1
	,	SubForBOMID = wodbom.SubForRowID
	,	SubPercentage = wodbom.SubPercentage
	,	BOMStatus = wodbom.Status
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = @WorkOrderNumber
			and wod.Line = @WorkOrderDetailLine
		join @XRt xr
			on xr.BOMLevel = wodbom.ChildPartBOMLevel - 1
			and xr.Sequence =
			(	select
					max(xr1.Sequence)
				from
					@XRt xr1
				where
					xr1.Sequence < wodbom.ChildPartSequence
			)
	where
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
		and wodbom.Status >= 0
		and wodbom.ChildPartBOMLevel = 4
	order by
		wodbom.ChildPartSequence
--- </Body>

---	<Return>
	return
end
GO
