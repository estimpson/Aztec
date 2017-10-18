/*
*/
drop table
	tempdb..OnHand
go
set nocount on

declare
	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float
,	@QtyRequested numeric(20,6)

set	@WorkOrderNumber = 'WO_0000000001'
set	@WorkOrderDetailLine = 1
set @QtyRequested = 140

create table
	tempdb..OnHand
(	Serial int primary key
,	Part varchar(25) not null
,	Suffix int null --If a process has multiple feed points for the same material, feed points are suffixed.
,	AllocationSequence tinyint default (0) --Determines the order in which inventory of the same part is allocated.
,	AllocationDT datetime not null --Within an allocation sequence, inventory is ordered by the order it was allocated.
--When inventory is counted before it is loaded this is used as a basis for what is available to backflush (Original - Issued = Available).  Otherwise, object quantity is used.
,	QtyOriginal numeric(20,6) --Counted quantity of available inventory prior to loading.
,	QtyIssued numeric(20,6) --Quantity issued since loading count.
,	QtyOnHand numeric(20,6) --Quantity onhand in inventory
,	QtyAvailable numeric(20,6) --QtyOriginal - QtyIssued or QtyOnHand
,	QtyToIssue numeric(20,6) default(0) not null --Calculated qty to be issued from this serial.
,	LowLevel tinyint --The lowest point in the BOM (of part being produced) where this part occurs.  Inventory is allocated top-down.
,	LastAllocation bit default(0)--If this is the last inventory allocated of a part, this part gets applicable overages.
)

insert
	tempdb..OnHand
(	Serial
,	Part
,	AllocationDT
,	QtyOnHand
,	LowLevel
)
select
	Serial = oAvailable.Serial
,	Part = oAvailable.PartCode
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
	)
,	QtyOnHand = coalesce(oAvailable.QtyAvailable, 0)
,	LowLevel = (select max(BOMLevel) from tempdb..XRt where ChildPart = oAvailable.PartCode)
from
	(	select
			Serial = o.serial
		,	PartCode = o.part
		,	LocationCode = o.location
		,	QtyAvailable = o.std_quantity
		from
			dbo.object o
		where
			o.status = 'A'
	) oAvailable
	left join dbo.MES_SetupBackflushingPrinciples msbp
		on msbp.Type = 3
		and msbp.ID = oAvailable.PartCode
	left join dbo.MES_StagingLocations msl
		on msbp.BackflushingPrinciple = 3 --StagingLocation
		and msl.PartCode = oAvailable.PartCode
		and msl.StagingLocationCode = oAvailable.LocationCode
	left join dbo.location lGroupTechActive
		join dbo.location lGroupMachines
			on lGroupTechActive.group_no = lGroupMachines.group_no
		on msbp.BackflushingPrinciple = 4 --GroupTechnology (sequence)
		and lGroupTechActive.code = oAvailable.LocationCode
		and lGroupTechActive.sequence > 0
	join dbo.machine m
		on m.machine_no = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
where
	exists
	(	select
	 		*
	 	from
	 		dbo.WorkOrderDetails wod
			join dbo.WorkOrderDetailBillOfMaterials wodbom
				on wod.WorkOrderNumber = wodbom.WorkOrderNumber
				and wod.Line = wodbom.WorkOrderDetailLine
				and wodbom.Status >= 0
			join dbo.WorkOrderHeaders woh
				on woh.WorkOrderNumber = wod.WorkOrderNumber
		where
			wod.WorkOrderNumber = @WorkOrderNumber
			and wod.Line = @WorkOrderDetailLine
			and wodbom.ChildPart = oAvailable.PartCode
			and woh.MachineCode = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
	)

/*	QtyAvailable is QtyOriginal - QtyIssued or QtyOnHand. */
update
	oh
set
	QtyAvailable = coalesce(oh.QtyOriginal - oh.QtyIssued, oh.QtyOnHand)
from
	tempdb..OnHand oh

/*	Determine if this object is the last object allocated. */
update
	oh
set
	LastAllocation = 1
from
	tempdb..OnHand oh
where
	not exists
	(	select
			*
		from
			tempdb..OnHand
		where
			Part = oh.Part
			and
			(	AllocationSequence > oh.AllocationSequence
				or
				(	AllocationSequence = oh.AllocationSequence
					and AllocationDT > oh.AllocationDT
			)	)
			and QtyAvailable > 0
	)

select
	*
from
	tempdb..OnHand
order by
	LowLevel
,	Part
,	AllocationSequence
,	AllocationDT
