SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[fn_MES_GetJobBackflushDetails_1]
(	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
,	@QtyRequested numeric(20,6)
)
returns
	@InventoryAllocation table
(	RowID int not null IDENTITY(1, 1) primary key
,	Serial int
,	Part varchar(25)
,	BackflushingPrinciple int
,	BOMStatus int
,	BOMLevel tinyint
,	Sequence tinyint
,	Suffix int
,	AllocationDT datetime
,	BillOfMaterialID int
,	QtyOriginal float
,	QtyAvailable float
,	QtyPer int
,	QtyRequired float
,	QtyIssue float default 0
,	QtyOverage float default 0
,	PriorAccum float
,	Concurrence tinyint
,	LastAllocation tinyint
)
as
begin
--- <Body>
	declare
		@XRt table
	(	RowID int primary key nonclustered
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

	insert
		@XRt
	select
		*
	from
		dbo.fn_MES_GetJobXRt(@WorkOrderNumber, @WorkOrderDetailLine) fmgjxr

	insert
		@InventoryAllocation
	(	Serial
	,	Part
	,	BackflushingPrinciple
	,	BOMStatus
	,	BOMLevel
	,	Sequence
	,	Suffix
	,	AllocationDT
	,	BillOfMaterialID
	,	QtyOriginal
	,	QtyAvailable
	,	QtyPer
	,	QtyRequired
	)
	select
		Serial = coalesce(oAvailable.Serial, -1)
	,	Part = xr.ChildPart
	,	BackflushingPrinciple = coalesce(msbpX.BackflushingPrinciple, -1)
	,	BOMStatus = xr.BOMStatus
	,	BOMLevel = xr.BOMLevel
	,	Sequence = xr.Sequence
	,	Suffix = coalesce (xr.Suffix, -1)
	,	AllocationDT = coalesce
		(	(	select
					max(atTransfer.date_stamp)
				from
					dbo.audit_trail atTransfer
				where
					atTransfer.Serial = oAvailable.Serial
					and atTransfer.type = 'T'
			)
		,	(	select
					max(atBreak.date_stamp)
				from
					dbo.audit_trail atBreak
				where
					atBreak.Serial = oAvailable.Serial
					and atBreak.type = 'B'
			)
		,	getdate()
		)
	,	BillOfMaterialID = xr.BOMID
	,	QtyOriginal = null
	,	QtyAvailable = coalesce(oAvailable.QtyAvailable, 0)
	,	QtyPer = null
	,	QtyRequired = @QtyRequested * xr.XQty * xr.XScrap * xr.XSuffix
	from
		@XRt xr
		left join dbo.MES_SetupBackflushingPrinciples msbpX
			on msbpX.Type = 3
			and msbpX.ID = xr.ChildPart
		left join
		(	select
				Serial = o.serial
			,	Part = o.part
			,	LocationCode = o.location
			,	QtyAvailable = o.std_quantity
			from
				dbo.object o
			where
				o.status = 'A'
		) oAvailable
				left join dbo.MES_SetupBackflushingPrinciples msbp
					on msbp.Type = 3
					and msbp.ID = oAvailable.Part
				left join dbo.MES_StagingLocations msl
					on msbp.BackflushingPrinciple = 3 --StagingLocation
					and msl.PartCode = oAvailable.Part
					and msl.StagingLocationCode = oAvailable.LocationCode
				left join dbo.location lGroupTechActive
					join dbo.location lGroupMachines
						on lGroupTechActive.group_no = lGroupMachines.group_no
					on msbp.BackflushingPrinciple = 4 --GroupTechnology (sequence)
					and lGroupTechActive.code = oAvailable.LocationCode
					and lGroupTechActive.sequence > 0
				left join dbo.location lPlant
					join dbo.location lPlantMachines -- All the machines within the inventory's plant.
						on coalesce(lPlantMachines.plant, 'N/A') = coalesce(lPlant.plant, 'N/A')
					on msbp.BackflushingPrinciple = 5 --(select dbo.udf_TypeValue('dbo.MES_SetupBackflushingPrinciples', 'BackflushingPrinciple, 'Plant'))
					and lPlant.code = oAvailable.LocationCode
				join dbo.WorkOrderDetails wod
					join dbo.WorkOrderHeaders woh
						on woh.WorkOrderNumber = wod.WorkOrderNumber
					on wod.WorkOrderNumber = @WorkOrderNumber
					and wod.Line = @WorkOrderDetailLine
					and woh.MachineCode = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
				join dbo.machine m
					on m.machine_no = coalesce(lGroupMachines.code, lPlantMachines.code, msl.MachineCode, oAvailable.LocationCode)
					and m.machine_no = woh.MachineCode
			on oAvailable.Part = xr.ChildPart
			and coalesce(null, -1) = coalesce(xr.Suffix, -1)
			and xr.BOMLevel >= 1
			and msbp.BackflushingPrinciple != 0 --(select dbo.udf_TypeValue('dbo.MES_SetupBackflushingPrinciples', 'BackflushingPrinciple', 'No Backflush'))
	order by
		Part
	,	Suffix
	,	AllocationDT

	update
		ia
	set
		Concurrence = (select count(*) from @InventoryAllocation iaP where iaP.Serial = ia.Serial and iaP.Part = ia.Part)
	from
		@InventoryAllocation ia

	update
		ia
	set
		PriorAccum = coalesce((select sum(QtyAvailable / Concurrence) from @InventoryAllocation iaP where iaP.Part = ia.Part and iap.RowID < ia.RowID and coalesce(iaP.Suffix, -1) = coalesce(ia.Suffix, -1)), 0)
	,	LastAllocation = coalesce((select min(0) from @InventoryAllocation iaP where iaP.Part = ia.Part and iap.RowID > ia.RowID and coalesce(iaP.Suffix, -1) = coalesce(ia.Suffix, -1)), 1)
	from
		@InventoryAllocation ia
	
	declare
		@NetMPS table
	(	RowID int not null IDENTITY(1, 1) primary key
	,	Hierarchy varchar(1000)
	,	Suffix int
	,	Part varchar(25)
	,	Sequence int
	,	BOMLevel int
	,	XQty float
	,	XScrap float
	,	XSuffix float
	,	SubRate float
	,	Children int
	,	Leaf bit
	,	QtyAvailable float default 0
	,	QtyRequired float default 0
	,	QtySub float default 0
	,	QtySubbed float default 0
	,	QtyDefaultUsage float default 0
	,	QtyUsed float default 0
	,	QtyXUsed float default 0e
	,	QtyNetDefaultUsage float default 0
	,	QtyEffective float default 0
	,	QtySubUsed float default 0
	,	QtyXSubUsed float default 0
	,	QtyFinalNet float default 0
	--,	unique (BOMLevel, Hierarchy, RowID)
	--,	unique (Hierarchy, BOMLevel, RowID)
	)

	insert
		@NetMPS
	(	Hierarchy
	,	Suffix
	,	Part
	,	Sequence
	,	BOMLevel
	,	XQty
	,	XScrap
	,	XSuffix
	,	SubRate
	,	Children
	,	Leaf
	,	QtyAvailable
	,	QtyRequired
	,	QtySub
	)
	select
		Hierarchy = xr.Hierarchy
	,	Suffix = xr.Suffix
	,	Part = xr.ChildPart
	,	Sequence = xr.Sequence
	,	BOMLevel = xr.BOMLevel
	,	XQty = xr.XQty
	,	XScrap = xr.XScrap
	,	XSuffix = xr.XSuffix
	,	SubRate = xr.SubRate
	,	Children = (select count(*) from @XRt xr1 where xr1.Hierarchy like xr.Hierarchy + '%' and xr1.BOMLevel > xr.BOMLevel)
	,	Leaf =
			case
				when (select count(*) from @XRt xr1 where xr1.Hierarchy like xr.Hierarchy + '%' and xr1.BOMLevel > xr.BOMLevel) = 0 then 1
				else 0
			end
	,	QtyAvailable = coalesce(ma.QtyAvailable / ma.Concurrence / (xr.XQty * xr.XScrap * xr.XSuffix), 0) --Weight for dups in BOM
	,	QtyRequired = @QtyRequested
	,	QtySub = @QtyRequested * xr.SubRate
	from
		@XRt xr
		left join
			(	select
					Part = ia.Part
				,	Suffix = ia.Suffix
				,	QtyAvailable = sum(ia.QtyAvailable / ia.Concurrence)
				,	Concurrence = max(ia.Concurrence)
				from
					@InventoryAllocation ia
				group by
					ia.Part
				,	ia.Suffix
			) ma
			on xr.ChildPart = ma.Part
			and coalesce(xr.Suffix, -1) = coalesce(ma.Suffix, -1)
	order by
		xr.Sequence

	update
		nm
	set
		QtySubbed = coalesce((select sum(QtySub / XQty / XScrap / XSuffix) from @NetMPS nm1 where nm1.Hierarchy like nm.Hierarchy + '%' and nm1.BOMLevel = nm.BOMLevel + 1) * XQty * XScrap * XSuffix, 0)
	from
		@NetMPS nm

	/*	Calculate default usage.*/
	update
		nm
	set
		QtyDefaultUsage = QtyRequired - QtySubbed
	,	QtyNetDefaultUsage = QtyRequired - QtySubbed
	from
		@NetMPS nm

	declare
		@BOMLevel int
	,	@LastBOMLevel int

	set	@BOMLevel = 0

	select
		@LastBOMLevel = max(BOMLevel)
	from
		@NetMPS nm

	while
		@BOMLevel <= @LastBOMLevel begin

		update
			nm
		set
			QtyUsed = coalesce(case when QtyNetDefaultUsage > QtyAvailable then QtyAvailable else QtyNetDefaultUsage end, 0)
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel
		
		update
			nm
		set
			QtyAvailable = QtyAvailable - QtyUsed
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel
		
		update
			nm
		set
			QtyXUsed =  coalesce
			(	(	select
						sum(nmX.QtyUsed)
					from
						@NetMPS nmX
					where
						nm.Hierarchy like nmX.Hierarchy + '%'
						and nmX.BOMLevel < nm.BOMLevel
				)
			,	0
			)
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel + 1
		
		update
			nm
		set
			QtyNetDefaultUsage = QtyDefaultUsage - QtyUsed - QtyXUsed
		from
			@NetMPS nm

		set	@BOMLevel = @BOMLevel + 1
	end

	/*	Using quantity assigned during default usage, calculate effective quantity. */
	while
		@BOMLevel >= 0 begin
		
		update
			nm
		set
			QtyEffective = QtyUsed + coalesce
			(	(	select
						min(nmY.QtyEffective)
					from
						@NetMPS nmY
					where
						nmY.Hierarchy like nm.Hierarchy + '%'
						and nmY.BOMLevel = nm.BOMLevel + 1
				)
			,	0
			)
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel

		set	@BOMLevel = @BOMLevel - 1
	end

	update
		nm
	set
		QtyFinalNet = QtyRequired - QtyEffective
	from
		@NetMPS nm

	/*	Assign usage from net of effective quantity. */
	while
		@BOMLevel <= @LastBOMLevel begin

		update
			nm
		set
			QtySubUsed = coalesce(case when QtyFinalNet > QtyAvailable then QtyAvailable else QtyFinalNet end, 0)
		,	QtyAvailable = QtyAvailable - coalesce(case when QtyFinalNet > QtyAvailable then QtyAvailable else QtyFinalNet end, 0)
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel
		
		update
			nm
		set
			QtyXSubUsed =  coalesce
			(	(	select
						sum(nmX.QtySubUsed)
					from
						@NetMPS nmX
					where
						nm.Hierarchy like nmX.Hierarchy + '%'
						and nmX.BOMLevel < nm.BOMLevel
				)
			,	0
			)
		from
			@NetMPS nm
		where
			BOMLevel = @BOMLevel + 1
		
		update
			nm
		set
			QtyFinalNet = QtyRequired - QtyEffective - QtyXUsed - QtySubUsed - QtyXSubUsed
		from
			@NetMPS nm

		set	@BOMLevel = @BOMLevel + 1
	end

	/*	Calculate issues. */
	update
		ia
	set
		QtyIssue =
			case
				when nmIssues.QtyIssue > ia.PriorAccum + ia.QtyAvailable then ia.QtyAvailable
				when nmIssues.QtyIssue > ia.PriorAccum then nmIssues.QtyIssue - ia.PriorAccum
				else 0
			end
	,	QtyOverage =
			case
				when ia.LastAllocation = 1 then nmIssues.QtyOverage
				else 0
			end
	from
		@InventoryAllocation ia
		join
		(	select
				nm.Part
			,	nm.Sequence
			,	nm.Suffix
			,	QtyIssue = sum((nm.QtyUsed + nm.QtySubUsed) * nm.XQty * nm.XScrap * nm.XSuffix)
			,	QtyOverage = sum(nm.Leaf * nm.QtyFinalNet * nm.XQty * nm.XScrap * nm.XSuffix)
			from
				@NetMPS nm
			group by
				nm.Part
			,	nm.Sequence
			,	nm.Suffix
		) nmIssues
			on nmIssues.Part = ia.Part
			and coalesce(nmIssues.Suffix, -1) = coalesce(ia.Suffix, -1)
--- </Body>

---	<Return>
	return
end
GO
