SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_Transfer_Box]
	@Operator varchar(5)
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@DisableLocationValidation int = 0 -- disable when transfering to an operator (in-transit)
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
	@RowCount integer,
	@FirstNewSerial integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>


---	<ArgumentValidation>
-- Valid operator.
if	not exists
	(	select	1
		from	employee
		where	operator_code = @Operator) begin

	set	@Result = 60000
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Operator %s not found.', 16, 1, @ProcName, @Operator)
	return	@Result
end

if @DisableLocationValidation < 1 begin
	-- Valid location.
	if	not exists
		(	select	1
			from	location
			where	code = @Location) begin

		set	@Result = 60001
		rollback tran @ProcName
		RAISERROR ('Error in procedure %s. %s is not a valid location.', 16, 1, @ProcName, @Location)
		return	@Result
	end
end

-- Serial number exists.
if not exists
	(	select	1 
		from	object
		where	serial = @Serial) begin
	
	set	@Result = 60002
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Serial %d not found.', 16, 1, @ProcName, @Serial)
	return	@Result
end

-- Is a box serial number.
if not exists
	(	select	1
		from	object
		where	serial = @Serial
				and isnull(type, 'S') = 'S') begin
	
	set	@Result = 60003
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Serial %d is a pallet.', 16, 1, @ProcName, @Serial)
	return	@Result
end

-- Is not on a pallet.
if not exists
	(	select	1
		from	object
		where	serial = @Serial
				and parent_serial is null) begin
				
	set	@Result = 60004
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Serial %d is on a pallet.', 16, 1, @ProcName, @Serial)
	return	@Result
end

-- Is not already at the location.
if exists
	(	select	1
		from	object
		where	serial = @Serial
				and location = @Location) begin

	set	@Result = 60001
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Box %d is already at location %s.', 16, 1, @ProcName, @Serial, @Location)
	return	@Result
end
---	</ArgumentValidation>


--- <Body>
-- Store original location
declare @LocationOriginal varchar(10)
select
	@LocationOriginal = o.location
from
	object o
where
	o.serial = @Serial
	

--- <Update object's location>
set	@TableName = 'dbo.object'
update 
	o
set
	o.location = @Location
from
	object o
where
	o.serial = @Serial
	
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999997
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999998
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update object's location>

		
--- <Create transfer record>
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
,   type = 'T'
,   part = o.part
,   quantity = o.quantity
,   remarks = 'Transfer'
,   price = 0
,   salesman = ''
,   customer = ''
,   vendor = ''
,   po_number = ''
,   operator = @Operator
,   from_loc = @LocationOriginal
,   to_loc = o.location
,   on_hand = dbo.udf_GetPartQtyOnHand(o.part)
,   lot = o.Lot
,   weight = o.weight
,   status = o.status
,   shipper = o.origin
,   flag = ''
,   activity = ''
,   unit = o.unit_measure
,   workorder = o.workorder
,   std_quantity = o.std_quantity
,   cost = o.Cost
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
,   suffix = null
,   due_date = null
,   group_no = ''
,   sales_order = ''
,   release_no = ''
,   dropship_shipper = 0
,   std_cost = o.std_cost
,   user_defined_status = o.user_defined_status
,   engineering_level = ''
,   posted = null
,   parent_serial = o.parent_serial
,   origin = o.origin
,   destination = ''
,   sequence = null
,   object_type = null
,   part_name = (select name from part where part = o.part)
,   start_date = null
,   field1 = o.field1
,   field2 = o.field2
,   show_on_shipper = o.show_on_shipper
,   tare_weight = null
,   kanban_number = null
,   dimension_qty_string = null
,   dim_qty_string_other = null
,   varying_dimension_Code = null
from
	object o
where
	o.serial = @Serial

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 100020
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 100021
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Create transfer record>
--- </Body>



--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	Success.
set	@Result = 0
return
	@Result


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
	@Operator varchar(5) = 'RCR'
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@TranDT datetime out
,	@Result integer out

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_JobComplete
	@Operator = @Operator
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@TranDT datetime out
,	@Result integer out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.audit_trail at
where
	at.serial = @Serial

select
	*
from
	dbo.BackflushHeaders bh
where
	bh.SerialProduced = @NewSerial

select
	*
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = (select bh.BackflushNumber from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)

select
	*
from
	dbo.audit_trail at
where
	at.serial in
		(	select
				bd.SerialConsumed
			from
				dbo.BackflushDetails bd
			where
				bd.BackflushNumber = (select bh.BackflushNumber from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)
		)
	and at.type = 'M'
	and at.date_stamp = (select bh.TranDT from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)
go

select
	*
from
	FT.SPLogging
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
