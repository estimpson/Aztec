SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_ManualAdd]
	@Operator varchar(5)
,	@Serial int = null
,	@ManualAddQuantity numeric(20,6) = null
,	@ManualAddLot varchar(20) = null
,	@ManualAddCustom1 varchar(50) = null
,	@ManualAddCustom2 varchar(50) = null
,	@ManualAddCustom3 varchar(50) = null
,	@ManualAddCustom4 varchar(50) = null
,	@ManualAddCustom5 varchar(50) = null
,	@Notes varchar(254)
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
/*	Create manual add audit trail. (i1) */
declare
	@ManualAddATType char(1)
,	@ManualAddATRemarks varchar(10)

set	@ManualAddATType = 'A'
set @ManualAddATRemarks = 'Manual Add'

--- <Insert rows="1">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(	serial
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
,   type = @ManualAddATType
,   part = o.part
,   quantity = dbo.udf_GetQtyFromStdQty(o.part, coalesce(@ManualAddQuantity, o.std_quantity), coalesce(nullif(o.unit, ''), pi.standard_unit))
,   remarks = @ManualAddATRemarks
,   price = 0
,   salesman = ''
,   customer = o.customer
,   vendor = ''
,   po_number = o.po_number
,   operator = @Operator
,   from_loc = o.from_loc
,   to_loc = o.from_loc
,   on_hand = dbo.udf_GetPartQtyOnHand(o.part)
,   lot = coalesce(@ManualAddLot, o.lot)
,   weight = dbo.fn_Inventory_GetPartNetWeight(o.part, coalesce(@ManualAddQuantity, o.std_quantity))
,   status = o.status
,   shipper = o.shipper
,   flag = ''
,   activity = ''
,   unit = coalesce(nullif(o.unit, ''), pi.standard_unit)
,   workorder = o.workorder
,   std_quantity = coalesce(@ManualAddQuantity, o.std_quantity)
,   cost = o.cost
,   control_number = ''
,   custom1 = coalesce(@ManualAddCustom1, o.custom1)
,   custom2 = coalesce(@ManualAddCustom1, o.custom2)
,   custom3 = coalesce(@ManualAddCustom1, o.custom3)
,   custom4 = coalesce(@ManualAddCustom1, o.custom4)
,   custom5 = coalesce(@ManualAddCustom1, o.custom5)
,   plant = o.plant
,   invoice_number = ''
,   notes = @Notes
,   gl_account = ''
,   package_type = o.package_type
,   suffix = o.suffix
,   due_date = o.due_date
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
,   object_type = o.object_type
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
	dbo.audit_trail o
	left join dbo.part_inventory pi
		on pi.part = o.part
where
	o.serial = @Serial
	and o.ID = (select min(LastTransID) from dbo.InventoryControl_CycleCount_GetSerialInfo(@Serial))

/*	Refactor for non-recovery operations. */

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

/*	Add object. (u1) */
--- <Insert rows="1">
set	@TableName = 'dbo.object'

insert
	dbo.object
(	serial
,   part
,   location
,   last_date
,   unit_measure
,   operator
,   status
,   destination
,   station
,   origin
,   cost
,   weight
,   parent_serial
,   note
,   quantity
,   last_time
,   date_due
,   customer
,   sequence
,   shipper
,   lot
,   type
,   po_number
,   name
,   plant
,   start_date
,   std_quantity
,   package_type
,   field1
,   field2
,   custom1
,   custom2
,   custom3
,   custom4
,   custom5
,   show_on_shipper
,   tare_weight
,   suffix
,   std_cost
,   user_defined_status
,   workorder
,   engineering_level
,   kanban_number
,   dimension_qty_string
,   dim_qty_string_other
,   varying_dimension_code
,   posted
)
select
	serial = @Serial
,   part = at.part
,   location = at.from_loc
,   last_date = @TranDT
,   unit_measure = at.unit
,   operator = @Operator
,   status = at.status
,   destination = at.destination
,   station = null
,   origin = at.origin
,   cost = at.cost
,   weight = dbo.fn_Inventory_GetPartNetWeight(at.part, coalesce(@ManualAddQuantity, at.std_quantity))
,   parent_serial = null
,   note = @Notes
,   quantity = dbo.udf_GetQtyFromStdQty(at.part, coalesce(@ManualAddQuantity, at.std_quantity), at.unit)
,   last_time = @TranDT
,   date_due = at.due_date
,   customer = at.customer
,   sequence = at.sequence
,   shipper = null
,   lot = at.lot
,   type = at.object_type
,   po_number = at.po_number
,   name = at.part_name
,   plant = at.plant
,   start_date = at.start_date
,   std_quantity = coalesce(@ManualAddQuantity, at.std_quantity)
,   package_type = at.package_type
,   field1 = at.field1
,   field2 = at.field2
,   custom1 = at.custom1
,   custom2 = at.custom2
,   custom3 = at.custom3
,   custom4 = at.custom4
,   custom5 = at.custom5
,   show_on_shipper = 'N'
,   tare_weight = at.tare_weight
,   suffix = at.suffix
,   std_cost = at.std_cost
,   user_defined_status = at.user_defined_status
,   workorder = at.workorder
,   engineering_level = at.engineering_level
,   kanban_number = at.kanban_number
,   dimension_qty_string = at.dimension_qty_string
,   dim_qty_string_other = at.dim_qty_string_other
,   varying_dimension_code = at.varying_dimension_code
,   posted = at.posted
from
	dbo.audit_trail at
where
	at.serial = @Serial
	and at.date_stamp = @TranDT	

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

/*	Record part on hand. (dbo.usp_InventoryControl_UpdatePartOnHand) */
declare
	@partCode varchar(25)

set	@partCode =
	(
		select
			part
		from
			dbo.object o
		where
			serial = @Serial
	)

--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_UpdatePartOnHand'
execute
	@ProcReturn = dbo.usp_InventoryControl_UpdatePartOnHand
	@PartCode = @partCode
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
--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

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
	@ProcReturn = dbo.usp_InventoryControl_ManualAdd
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
