SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_Shipping_ShipoutShipper]
	@User varchar(5)
,	@ShipperID integer
,	@TranDT datetime = null out
,	@Result integer = null out
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
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Pre-shipout custom procedure call. */
--- <Call>	
set	@CallProcName = 'custom.usp_Shipping_PreShipout'
execute
	@ProcReturn = custom.usp_Shipping_PreShipout
	    @ShipperID = @ShipperID
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

/*	Update shipper header to show shipped status and date and time shipped. */
--- <Update rows="1">
set	@TableName = 'dbo.shipper'

update
	s
set	
	status = 'C'
,	date_shipped = @TranDT
,	time_shipped = @TranDT
from
	dbo.shipper s
where
	s.id = @ShipperID
	and s.status = 'D'

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

/*	Set shipper detail shipment date and week. */
--- <Update rows="*">
set	@TableName = 'dbo.shipper_detail'

update
	sd
set
	operator = @User
,	date_shipped = @TranDT
,	week_no = datepart(wk, @TranDT)
from
	dbo.shipper_detail sd
where
	sd.shipper = @ShipperID

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Generate audit trail records for inventory to be relieved. */
--- <Insert rows="1+">
set	@TableName = 'dbo.audit_trail'

insert	dbo.audit_trail
(
	serial, date_stamp, type, part, quantity
,	remarks, price, salesman, customer, vendor
,	po_number, operator, from_loc, to_loc, on_hand
,	lot, weight, status, shipper, unit
,	workorder, std_quantity, cost
,	custom1, custom2, custom3, custom4, custom5
,	plant, notes, gl_account, package_type, suffix
,	due_date, group_no, sales_order, release_no
,	std_cost, user_defined_status, engineering_level, parent_serial
,	destination, sequence, object_type, part_name, start_date
,	field1, field2, show_on_shipper, tare_weight
,	kanban_number, dimension_qty_string, dim_qty_string_other
,	varying_dimension_code 
)
select
	object.serial
,	shipper.date_shipped
,	coalesce(shipper.type, 'S')
,	object.part
,	coalesce(object.quantity, 1)
,	(case shipper.type
		when 'Q' then 'Shipping'
		when 'O' then 'Out Proc'
		when 'V' then 'Ret Vendor'
		else 'Shipping'
		end)
,	coalesce(shipper_detail.price, 0)
,	shipper_detail.salesman
,	destination.customer
,	destination.vendor
,	object.po_number
,	coalesce(so.LoadingOperator, shipper_detail.operator, '')
,	object.location
,	destination.destination
,	part_online.on_hand
,	object.lot
,	object.weight
,	object.status
,	convert (varchar, @ShipperID)
,	object.unit_measure
,	object.workorder
,	object.std_quantity
,	object.cost
,	object.custom1
,	object.custom2
,	object.custom3
,	object.custom4
,	object.custom5
,	object.plant
,	shipper_detail.note
,	shipper_detail.account_code
,	object.package_type
,	object.suffix
,	object.date_due
,	shipper_detail.group_no
,	convert (varchar, shipper_detail.order_no)
,	shipper_detail.release_no
,	object.std_cost
,	object.user_defined_status
,	object.engineering_level
,	object.parent_serial
,	shipper.destination
,	object.sequence
,	object.type
,	object.name
,	object.start_date
,	object.field1
,	object.field2
,	object.show_on_shipper
,	object.tare_weight
,	object.kanban_number
,	object.dimension_qty_string
,	object.dim_qty_string_other
,	object.varying_dimension_code
from
	object
	join shipper
		on shipper.id = @ShipperID
	left outer join shipper_detail
		on shipper_detail.shipper = @ShipperID
			and object.part = shipper_detail.part_original
			and coalesce(object.suffix,
				(	select
						min(sd.suffix)
					from
						shipper_detail sd
					where
						sd.shipper = @ShipperID
						and object.part = sd.part_original
					)
				,	0
				) = coalesce(shipper_detail.suffix, 0)
	join destination
		on shipper.destination = destination.destination
	left outer join part_online
		on object.part = part_online.part
	left join dbo.Shipping_Objects so
		on so.ShipperNumber = 'L' + convert(varchar(49), @ShipperID)
		and so.Serial = object.serial
where
	object.shipper = @ShipperID

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

/*	Call EDI shipout procedure. */
--- <Call>	
set	@CallProcName = 'dbo.edi_msp_shipout'
execute
	@ProcReturn = dbo.edi_msp_shipout
		@shipper = @ShipperID

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

/*	Relieve inventory. */
delete
	object
from
	object
	join shipper
		on object.shipper = shipper.id
where
	object.shipper = @ShipperID
	and isnull(shipper.type, '') <> 'O'

update
	object
set	
	location = shipper.destination
,	destination = shipper.destination
,	status = 'P'
from
	object
	join shipper
		on object.shipper = shipper.id
where
	object.shipper = @ShipperID
	and shipper.type = 'O'

/*	If this is an outside process shipper, auto-create firm PO line item for returning part(s). */
if	(	select
			s.type
		from
			dbo.shipper s
		where
			s.id = @ShipperID
	) = 'O' begin
	
	declare
		@vendorShipTo varchar(20)
	,	@rawPartCode varchar(25)
	,	@rawPartStandardQty numeric(20,6)
	
	select
		@vendorShipTo = s.destination
	from
		dbo.shipper s
	where
		id = @ShipperID
	
	declare
		shipperLines cursor local for
	select
		PartCode = part_original
	,	PackedQty = qty_packed
	from
		dbo.shipper_detail sd
	where
		sd.shipper = @ShipperID
		and sd.qty_packed > 0
	
	open shipperLines
	
	while
		1 = 1 begin
		
		fetch
			shipperLines
		into
			@rawPartCode
		,	@rawPartStandardQty
		
		if	@@FETCH_STATUS != 0 begin
			break
		end
	
		set	@CallProcName = 'dbo.usp_OutsideProcessing_AutocreateFirmPOLineItem'
		execute
			@ProcReturn = dbo.usp_OutsideProcessing_AutocreateFirmPOLineItem
			@User = @User
		,	@VendorShipFrom = @vendorShipTo
		,	@RawPartCode = @rawPartCode
		,	@RawPartStandardQty = @rawPartStandardQty
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
  
	/*	Update part_vendor table for outside processed part. */
	update
		part_vendor
	set	
		accum_shipped = coalesce(accum_shipped, 0) + coalesce
			(	(	select
						sum(object.std_quantity)
					from
						object
					where
						object.shipper = @ShipperID
						and object.part = pv.part
				)
			,	0
			)
	from
		part_vendor pv
	,	shipper s
	,	destination d
	where
		s.id = @ShipperID
		and s.type = 'O'
		and d.destination = s.destination
		and pv.vendor = d.vendor
end


--	7.	Adjust part online quantities for inventory.
update
	part_online
set	
	on_hand =
		(	select
				sum(std_quantity)
			from
				object
			where
				part_online.part = object.part
				and object.status = 'A'
		)
from
	part_online
	join shipper_detail
		on shipper_detail.shipper = @ShipperID
		   and shipper_detail.part_original = part_online.part

/*	Relieve order requirements. */
--- <Call>	
set	@CallProcName = 'dbo.msp_update_orders'
execute
	@ProcReturn = dbo.msp_update_orders
		@shipper = @ShipperID
	
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
--if	@ProcResult != 0 begin
--	set	@Result = 900502
--	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
--	rollback tran @ProcName
--	return	@Result
--end
--- </Call>

/*	Close bill of lading. */
declare
	@bol int
,	@bolCount int

select
	@bol = s.bill_of_lading_number
,	@bolCount = count(sBOLOpen.id)
from
	dbo.shipper s
		left join dbo.shipper sBOLOpen
			on sBOLOpen.bill_of_lading_number = s.bill_of_lading_number
			and sBOLOpen.status in ('S', 'O')
where
	s.id = @ShipperID
group by
	s.bill_of_lading_number

if	@bolCount = 0
	update
		bill_of_lading
	set	
		status = 'C'
	from
		bill_of_lading
		join shipper
			on shipper.id = @ShipperID
			and bill_of_lading.bol_number = shipper.bill_of_lading_number

/*	Assign invoice number. */
declare
	@invoiceNumber int
  
update
	parameters
set	
	next_invoice = next_invoice + 1

select
	@invoiceNumber = next_invoice - 1
from
	parameters

while
	exists
		(	select
				invoice_number
			from
				shipper
			where
				invoice_number = @invoiceNumber
		) begin

	select
		@invoiceNumber = @invoiceNumber + 1

end

update
	parameters
set	
	next_invoice = @invoiceNumber + 1

update
	shipper
set	
	invoice_number = @invoiceNumber
where
	id = @ShipperID
--- </Body>

/*	Post-shipout custom procedure call. */
--- <Call>	
set	@CallProcName = 'custom.usp_Shipping_PostShipout'
execute
	@ProcReturn = custom.usp_Shipping_PostShipout
	    @ShipperID = @ShipperID
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

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

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
	@ProcReturn = dbo.usp_Shipping_ShipoutShipper
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
