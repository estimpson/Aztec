SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_InventoryControl_MaterialIssue]
	@Operator varchar(5)
,	@Serial int
,	@QtyIssue numeric(20,6)
,	@MachineCode varchar(5) = null
,	@WorkOrderNumber varchar(50) = null
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
set
	@MachineCode = coalesce
	(
		@MachineCode
	,	(
			select
				MachineCode
			from
				dbo.WorkOrderHeaders
			where
				WorkOrderNumber = @WorkOrderNumber
		)
	)

---	</ArgumentValidation>

--- <Body>
/*	Create material issue audit trail. (i1) */
declare
	@materialIssueATType char(1)
,	@materialIssueATRemarks char(1)

set	@materialIssueATType = 'M'
set @materialIssueATRemarks = 'Mat Issue'

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
,   type = @materialIssueATType
,   part = o.part
,   quantity = dbo.udf_GetQtyFromStdQty(o.part, @QtyIssue, o.unit_measure)
,   remarks = @materialIssueATRemarks
,   price = 0
,   salesman = ''
,   customer = o.customer
,   vendor = ''
,   po_number = o.po_number
,   operator = @Operator
,   from_loc = o.location
,   to_loc = @MachineCode
,   on_hand = dbo.udf_GetPartQtyOnHand(o.part) - @QtyIssue
,   lot = o.lot
,   weight = dbo.fn_Inventory_GetPartNetWeight(o.part, @QtyIssue)
,   status = o.status
,   shipper = o.shipper
,   flag = ''
,   activity = ''
,   unit = o.unit_measure
,   workorder = o.workorder
,   std_quantity = @QtyIssue
,   cost = o.cost
,   control_number = ''
,   custom1 = o.custom1
,   custom2 = o.custom2
,   custom3 = o.custom3
,   custom4 = o.custom4
,   custom5 = o.custom5
,   plant = o.plant
,   invoice_number = ''
,   notes = @Notes
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
,   part_name = (SELECT name FROM part WHERE part = o.part)
,   start_date = o.start_date
,   field1 = o.field1
,   field2 = o.field2
,   show_on_shipper = o.show_on_shipper
,   tare_weight = o.tare_weight
,   kanban_number = o.kanban_number
,   dimension_qty_string = o.dimension_qty_string
,   dim_qty_string_other = o.dim_qty_string_other
,   varying_dimension_code = o.varying_dimension_code
FROM
	dbo.object o
WHERE
	serial = @Serial

SELECT
	@Error = @@Error,
	@RowCount = @@Rowcount

IF	@Error != 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	ROLLBACK TRAN @ProcName
	RETURN
END
IF	@RowCount != 1 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	ROLLBACK TRAN @ProcName
	RETURN
END
--- </Insert>

/*	Adjust object quantity. (u1) */
--- <Update rows="1">
SET	@TableName = 'dbo.object'

UPDATE
	o
SET
	std_quantity = std_quantity - @QtyIssue
,	quantity = quantity - dbo.udf_GetQtyFromStdQty(o.part, @QtyIssue, o.unit_measure)
,	weight = dbo.fn_Inventory_GetPartNetWeight(o.part, std_quantity - @QtyIssue)
,	last_date = @TranDT
,	last_time = @TranDT
FROM
	dbo.object o
WHERE
	serial = @Serial

SELECT
	@Error = @@Error,
	@RowCount = @@Rowcount

IF	@Error != 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	ROLLBACK TRAN @ProcName
	RETURN
END
IF	@RowCount != 1 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	ROLLBACK TRAN @ProcName
	RETURN
END
--- </Update>

/*	Record part on hand. (dbo.usp_InventoryControl_UpdatePartOnHand) */
DECLARE
	@partCode VARCHAR(25)

SET	@partCode =
	(
		SELECT
			part
		FROM
			dbo.object o
		WHERE
			serial = @Serial
	)

--- <Call>	
SET	@CallProcName = 'dbo.usp_InventoryControl_UpdatePartOnHand'
EXECUTE
	@ProcReturn = dbo.usp_InventoryControl_UpdatePartOnHand
	@PartCode = @partCode
,	@TranDT = @TranDT OUT
,	@Result = @ProcResult OUT

SET	@Error = @@Error
IF	@Error != 0 BEGIN
	SET	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	ROLLBACK TRAN @ProcName
	RETURN	@Result
END
IF	@ProcReturn != 0 BEGIN
	SET	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	ROLLBACK TRAN @ProcName
	RETURN	@Result
END
IF	@ProcResult != 0 BEGIN
	SET	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	ROLLBACK TRAN @ProcName
	RETURN	@Result
END
--- </Call>

--- </Body>

---	<Return>
SET	@Result = 0
RETURN
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
	@ProcReturn = dbo.usp_InventoryControl_MaterialIssue
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
