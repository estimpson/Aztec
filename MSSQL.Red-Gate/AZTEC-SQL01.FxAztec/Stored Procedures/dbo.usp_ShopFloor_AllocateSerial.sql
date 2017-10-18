SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ShopFloor_AllocateSerial]
	@Operator varchar(5)
,	@Serial int
,	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailSequence int
,	@Suffix int
,	@QtyBreakout numeric(20,6) = null
,	@BreakoutSerial int = null out
,	@TranDT datetime out
,	@Result integer out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Perform breakout if necessary. */
if	@QtyBreakout > 0 begin
/*		Perform breakout (dbo.usp_InventoryControl_Breakout) */
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Breakout'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Breakout
		@Operator = @Operator
	,	@Serial = @Serial
	,	@QtyBreakout = @QtyBreakout
	,	@BreakoutSerial = @BreakoutSerial out
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
	
/*		Use breakout serial for remainder of transaction. */
	set @Serial = @BreakoutSerial
end

/*	Create material allocation record(s). (i1+) */
--- <Insert rows="1+">
set	@TableName = 'dbo.object'

insert
	dbo.WorkOrderDetailMaterialAllocations
(
	WorkOrderNumber
,	WorkOrderDetailLine
,	WorkOrderDetailBillOfMaterialLine
,	AllocationDT
,	Serial
,	Status
,	Type
,	QtyOriginal
,	QtyBegin
,	QtyIssued
,	QtyPer
,	AllowablePercentOverage
)
select
	WorkOrderNumber = wodbom.WorkOrderNumber
,	WorkOrderDetailLine = wodbom.WorkOrderDetailLine
,	WorkOrderDetailBillOfMaterialLine = wodbom.Line
,	AllocationDT = @TranDT
,	Serial = @Serial
,	Status = dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'New')
,	Type = dbo.udf_TypeValue('dbo.WorkOrderDetailMaterialAllocations', 'Serial')
,	QtyOriginal = (select max(std_quantity) from audit_trail where serial = @Serial and date_stamp = (select min(date_stamp) from dbo.audit_trail where serial = @Serial))
,	QtyBegin = 
	case
		when not exists (select * from dbo.WorkOrderDetailMaterialAllocations where Status = dbo.udf_TypeValue('dbo.WorkOrderDetailMaterialAllocations', 'Serial') and Serial = @Serial and AllocationEndDT is null)
			then o.std_quantity
	end
,	QtyIssued = 0
,	QtyPer = wodbom.QtyPer
,	AllowablePercentOverage = null
from
	dbo.WorkOrderDetails wod
	join dbo.WorkOrderDetailBillOfMaterials wodbom on
		wod.WorkOrderNumber = wodbom.WorkOrderNumber
		and
			wod.Line = wodbom.WorkOrderDetailLine
		and
			coalesce(wodbom.Suffix, -1) = coalesce(@Suffix, -1)
	join dbo.object o on
		o.serial = @Serial
		and
			o.status = 'A'
		and
			wodbom.ChildPart = o.part
where
	wod.WorkOrderNumber = @WorkOrderNumber
	and
		wod.Sequence = @WorkOrderDetailSequence
	and
		not exists
		(	select
				*
			from
				dbo.WorkOrderDetailMaterialAllocations wodma
				join dbo.WorkOrderDetailBillOfMaterials wodbom2 on
					wodma.WorkOrderNumber = wodbom2.WorkOrderNumber
					and
						wodma.WorkOrderDetailLine = wodbom2.WorkOrderDetailLine
					and
						wodma.WorkOrderDetailBillOfMaterialLine = wodbom2.Line
				join dbo.WorkOrderDetails wod2 on
					wodma.WorkOrderNumber = wod2.WorkOrderNumber
					and
						wodma.WorkOrderDetailLine = wod2.Line
			where
				wod2.WorkOrderNumber = @WorkOrderNumber
				and
					wod2.Sequence = @WorkOrderDetailSequence
				and
					coalesce(wodbom2.Suffix, -1) = coalesce(@Suffix, -1)
				and
					wodma.Serial = @Serial
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Read material location. */
declare
	@materialLocation varchar(10)

set
	@materialLocation = (select location from dbo.object where serial = @Serial)

/*	Transfer object to machine. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.object'

update
	o
set
	o.location = l.code
,	o.plant = l.plant
from
	dbo.object o
	join dbo.location l on
		l.code = (select MachineCode from dbo.WorkOrderHeaders woh where WorkOrderNumber = @WorkOrderNumber)
where
	o.serial = @Serial
	and
		o.status = 'A'

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Create allocation audit trail. (i1)*/
declare
	@tranType char(1)
,	@remarks varchar(10)

set	@tranType = 'T'
set	@remarks = 'ALLOCATE'

--- <Insert rows="1">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(
	serial, date_stamp, type, part, quantity
,	remarks, operator, from_loc, to_loc, on_hand
,	lot, weight, status, unit, workorder
,	std_quantity, cost
,	custom1, custom2, custom3, custom4, custom5
,	plant, package_type, suffix, std_cost
,	user_defined_status, engineering_level, parent_serial, origin
,	object_type, part_name, field1, field2, tare_weight
)
select
	serial = o.serial, date_stamp = @TranDT, type = @tranType, part = o.part, quantity = o.quantity
,	remarks = @remarks, operator = @Operator, from_loc = @materialLocation, to_loc = o.location, on_hand = (select on_hand from dbo.part_online where part = o.part)
,	lot = o.lot, weight = o.weight, status = o.status, unit = o.unit_measure, workorder = @WorkOrderNumber
,	std_quantity = o.std_quantity, cost = o.cost
,	custom1 = o.custom1, custom2 = o.custom2, custom3 = o.custom3, custom4 = o.custom4, custom5 = o.custom5
,	plant = o.plant, package_type = o.package_type, suffix = @Suffix, std_cost = ps.cost_cum
,	user_defined_status = o.user_defined_status, engineering_level = o.engineering_level, parent_serial = o.parent_serial, origin = o.origin
,	object_type = o.type, part_name = p.name, field1 = o.field1, field2 = o.field2, tare_weight = o.tare_weight
from
	dbo.object o
	left join dbo.part p on
		o.part = p.part
	left join dbo.part_standard ps on
		o.part = ps.part
where
	serial = @Serial
	and
		status = 'A'
	
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ShopFloor_AllocateSerial
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
