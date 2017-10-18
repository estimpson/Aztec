SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ShopFloor_EndSerialAllocation]
	@Operator varchar(5)
,	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailSequence int
,	@Suffix float
,	@Serial int
,	@IsEmpty bit
,	@QtyRemaining numeric(20,6) = null
,	@ChangeReason varchar(max) = null
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
/*	Get remaining quantity of object. */
declare
	@StdQtyObject numeric(20,6)

set	@StdQtyObject =
	(
		select
			std_quantity
		from
			dbo.object o
		where
			serial = @Serial
	)

/*	If object is empty... */
if	@IsEmpty = 1 begin

/*		If quantity remaining... */
	if	@StdQtyObject > 0 begin

/*			Record quantity discrepancy (dbo.usp_InventoryControl_QuantityDiscrepancy) */
		declare
			@DeltaQtyEmpty numeric(20,6)
		
		set	@DeltaQtyEmpty = -@StdQtyObject
		
		--- <Call>	
		set	@CallProcName = 'dbo.usp_InventoryControl_QuantityDiscrepancy'
		execute
			@ProcReturn = dbo.usp_InventoryControl_QuantityDiscrepancy 
		    @Operator = @Operator
		,   @Serial = @Serial
		,   @DeltaQty = @DeltaQtyEmpty
		,   @Notes = 'Object is empty and allocation is being ended.'
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
	end
	
/*		Create delete audit trail. (i1) */
	declare
		@DeleteATType char(1)
	,	@DeleteATRemarks char(1)

	set	@DeleteATType = 'D'
	set @DeleteATRemarks = 'Delete'

	--- <Insert rows="1">
	set	@TableName = 'dbo.audit_trail'

	insert
		dbo.audit_trail
	(
		serial
	,   date_stamp
	,   type
	,   part
	,   quantity
	,   remarks
	,   price
	,   salesman
	,   customer
	,   vendor
	,   po_number
	,   operator
	,   from_loc
	,   to_loc
	,   on_hand
	,   lot
	,   weight
	,   status
	,   shipper
	,   flag
	,   activity
	,   unit
	,   workorder
	,   std_quantity
	,   cost
	,   control_number
	,   custom1
	,   custom2
	,   custom3
	,   custom4
	,   custom5
	,   plant
	,   invoice_number
	,   notes
	,   gl_account
	,   package_type
	,   suffix
	,   due_date
	,   group_no
	,   sales_order
	,   release_no
	,   dropship_shipper
	,   std_cost
	,   user_defined_status
	,   engineering_level
	,   posted
	,   parent_serial
	,   origin
	,   destination
	,   sequence
	,   object_type
	,   part_name
	,   start_date
	,   field1
	,   field2
	,   show_on_shipper
	,   tare_weight
	,   kanban_number
	,   dimension_qty_string
	,   dim_qty_string_other
	,   varying_dimension_code
	)
	select
		serial = o.serial
	,   date_stamp = @TranDT
	,   type = @DeleteATType
	,   part = o.part
	,   quantity = o.quantity
	,   remarks = @DeleteATRemarks
	,   price = 0
	,   salesman = ''
	,   customer = o.customer
	,   vendor = ''
	,   po_number = o.po_number
	,   operator = @Operator
	,   from_loc = o.location
	,   to_loc = o.location
	,   on_hand = dbo.udf_GetPartQtyOnHand(o.part)
	,   lot = o.lot
	,   weight = o.weight
	,   status = o.status
	,   shipper = o.shipper
	,   flag = ''
	,   activity = ''
	,   unit = o.unit_measure
	,   workorder = o.workorder
	,   std_quantity = o.std_quantity
	,   cost = o.cost
	,   control_number = ''
	,   custom1 = o.custom1
	,   custom2 = o.custom2
	,   custom3 = o.custom3
	,   custom4 = o.custom4
	,   custom5 = o.custom5
	,   plant = o.plant
	,   invoice_number = ''
	,   notes = 'Object empty.'
	,   gl_account = ''
	,   package_type = o.package_type
	,   suffix = o.suffix
	,   due_date = o.date_due
	,   group_no = ''
	,   sales_order = ''
	,   release_no = ''
	,   dropship_shipper = 0
	,   std_cost = o.std_cost
	,   user_defined_status = o.user_defined_status
	,   engineering_level = o.engineering_level
	,   posted = o.posted
	,   parent_serial = o.parent_serial
	,   origin = o.origin
	,   destination = o.destination
	,   sequence = o.sequence
	,   object_type = o.type
	,   part_name = (select name from part where part = o.part)
	,   start_date = o.start_date
	,   field1 = o.field1
	,   field2 = o.field2
	,   show_on_shipper = o.show_on_shipper
	,   tare_weight = o.tare_weight
	,   kanban_number = o.kanban_number
	,   dimension_qty_string = o.dimension_qty_string
	,   dim_qty_string_other = o.dim_qty_string_other
	,   varying_dimension_code = o.varying_dimension_code
	from
		dbo.object o
	where
		serial = @Serial

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

/*		Delete depleted object. (d1) */
	--- <Delete rows="1">
	set	@TableName = 'dbo.object'
	
	delete
		o
	from
		dbo.object o
	where
		o.serial = @Serial
		and
			o.std_quantity = 0
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end

/*	Else... */
else	begin

/*		If quantity remaining is changed... */
	if	@StdQtyObject != @QtyRemaining begin
	
/*			Record quantity discrepancy (dbo.usp_InventoryControl_QuantityDiscrepancy) */
		declare
			@DeltaQtyChange numeric(20,6)
		
		set	@DeltaQtyChange = @StdQtyObject - @QtyRemaining
		
		--- <Call>	
		set	@CallProcName = 'dbo.usp_InventoryControl_QuantityDiscrepancy'
		execute
			@ProcReturn = dbo.usp_InventoryControl_QuantityDiscrepancy 
		    @Operator = @Operator
		,   @Serial = @Serial
		,   @DeltaQty = @DeltaQtyChange
		,   @Notes = 'Object is empty and allocation is being ended.'
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
	end
	
/*		Return object to primary location. (u1) */
	--- <Update rows="1">
	set	@TableName = 'dbo.object'
	
	update
		o
	set
		location = (select primary_location from dbo.part_inventory where part = o.part)
	,	plant = (select plant from location where code = (select primary_location from dbo.part_inventory where part = o.part))
	from
		dbo.object o
	where
		serial = @Serial
	
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
		
/*		Create end-allocation audit trail. (i1) */
	declare
		@EndAllocATType char(1)
	,	@EndAllocATRemarks char(1)

	set	@EndAllocATType = 'T'
	set @EndAllocATRemarks = 'End Alloc'

	--- <Insert rows="1">
	set	@TableName = 'dbo.audit_trail'

	insert
		dbo.audit_trail
	(
		serial
	,   date_stamp
	,   type
	,   part
	,   quantity
	,   remarks
	,   price
	,   salesman
	,   customer
	,   vendor
	,   po_number
	,   operator
	,   from_loc
	,   to_loc
	,   on_hand
	,   lot
	,   weight
	,   status
	,   shipper
	,   flag
	,   activity
	,   unit
	,   workorder
	,   std_quantity
	,   cost
	,   control_number
	,   custom1
	,   custom2
	,   custom3
	,   custom4
	,   custom5
	,   plant
	,   invoice_number
	,   notes
	,   gl_account
	,   package_type
	,   suffix
	,   due_date
	,   group_no
	,   sales_order
	,   release_no
	,   dropship_shipper
	,   std_cost
	,   user_defined_status
	,   engineering_level
	,   posted
	,   parent_serial
	,   origin
	,   destination
	,   sequence
	,   object_type
	,   part_name
	,   start_date
	,   field1
	,   field2
	,   show_on_shipper
	,   tare_weight
	,   kanban_number
	,   dimension_qty_string
	,   dim_qty_string_other
	,   varying_dimension_code
	)
	select
		serial = o.serial
	,   date_stamp = @TranDT
	,   type = @EndAllocATType
	,   part = o.part
	,   quantity = o.quantity
	,   remarks = @EndAllocATRemarks
	,   price = 0
	,   salesman = ''
	,   customer = o.customer
	,   vendor = ''
	,   po_number = o.po_number
	,   operator = @Operator
	,   from_loc = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber)
	,   to_loc = o.location
	,   on_hand = dbo.udf_GetPartQtyOnHand(o.part)
	,   lot = o.lot
	,   weight = o.weight
	,   status = o.status
	,   shipper = o.shipper
	,   flag = ''
	,   activity = ''
	,   unit = o.unit_measure
	,   workorder = o.workorder
	,   std_quantity = o.std_quantity
	,   cost = o.cost
	,   control_number = ''
	,   custom1 = o.custom1
	,   custom2 = o.custom2
	,   custom3 = o.custom3
	,   custom4 = o.custom4
	,   custom5 = o.custom5
	,   plant = o.plant
	,   invoice_number = ''
	,   notes = @ChangeReason
	,   gl_account = ''
	,   package_type = o.package_type
	,   suffix = o.suffix
	,   due_date = o.date_due
	,   group_no = ''
	,   sales_order = ''
	,   release_no = ''
	,   dropship_shipper = 0
	,   std_cost = o.std_cost
	,   user_defined_status = o.user_defined_status
	,   engineering_level = o.engineering_level
	,   posted = o.posted
	,   parent_serial = o.parent_serial
	,   origin = o.origin
	,   destination = o.destination
	,   sequence = o.sequence
	,   object_type = o.type
	,   part_name = (select name from part where part = o.part)
	,   start_date = o.start_date
	,   field1 = o.field1
	,   field2 = o.field2
	,   show_on_shipper = o.show_on_shipper
	,   tare_weight = o.tare_weight
	,   kanban_number = o.kanban_number
	,   dimension_qty_string = o.dimension_qty_string
	,   dim_qty_string_other = o.dim_qty_string_other
	,   varying_dimension_code = o.varying_dimension_code
	from
		dbo.object o
	where
		serial = @Serial

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

end

/*	End allocation record(s). (u1+) */
--- <Update rows="1+">
set	@TableName = 'dbo.WorkOrderDetailMaterialAllocations'

update
	wodma
set
	AllocationEndDT = @TranDT
,	QtyEnd = @StdQtyObject
,	QtyEstimatedEnd = @QtyRemaining
,	ChangeReason = @ChangeReason
,	Status =
	case
		@IsEmpty
		when 1 then dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'Depleted')
		else dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'Completed')
	end
from
	dbo.WorkOrderDetailMaterialAllocations wodma
	join dbo.WorkOrderDetailBillOfMaterials wodbom on
		wodbom.WorkOrderNumber = @WorkOrderNumber
		and
			wodma.WorkOrderDetailBillOfMaterialLine = wodbom.WorkOrderDetailLine
		and
			wodbom.Suffix = @Suffix
	join dbo.WorkOrderDetails wod on
		wod.WorkOrderNumber = @WorkOrderNumber
		and
			wod.Sequence = @WorkOrderDetailSequence
where
	wodma.WorkOrderNumber = @WorkOrderNumber
	and
		wodma.Serial = @Serial
	and
		wodma.Status = dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'New')

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

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
	@ProcReturn = dbo.usp_ShopFloor_EndSerialAllocation
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
