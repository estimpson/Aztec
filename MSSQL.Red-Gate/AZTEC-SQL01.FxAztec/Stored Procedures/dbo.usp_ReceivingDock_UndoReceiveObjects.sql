SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_UndoReceiveObjects]
	@User varchar(5),
	@PONumber int,
	@POLineNo int,
	@PartCode varchar(25),
	@SerialNumber int,
	@TranDT datetime out,
	@Result int out
as
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn int,
	@ProcResult int,
	@Error int,
	@RowCount int

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--	Initializations.
--		Verify the receipt has not already been invoiced.
--if	exists
--	(
--		select
--			*
--		from
--			dbo.audit_trail at
--			join dbo.po_receiver_items pri on
--				at.po_number = pri.purchase_order
--				and
--					at.part = pri.item
--				and
--					at.shipper + 
--					case
--						when (select IsNull(value,'') from dbo.preferences_standard where preference = 'MonitorAppendDateToShipper') = 'Y' then '_' + Convert(char(6), at.date_stamp, 12)
--						else ''
--					end = pri.bill_of_lading
--		where
--			at.serial = @SerialNumber
--			and
--				at.type = 'R'
--			and
--				pri.invoice > ''
--	) begin
--	set	@Result = 999999
--	RAISERROR ('The receipt for serial %d has already been invoiced in Empower and cannot be undone.', 16, 1, @SerialNumber)
--	rollback tran @ProcName
--	return @Result
--end

--		Get receipt transaction datetime, quantity and standard quantity.
declare
	@ReceiptDT datetime
,	@ReceiptQty numeric(20,6)
,	@ReceiptStdQty numeric(20,6)

select
	@ReceiptDT = at.date_stamp
,	@ReceiptQty = at.quantity
,	@ReceiptStdQty = at.std_quantity
from
	audit_trail at
where
	at.serial = @SerialNumber
	and
		at.type = 'R'
	and
		at.date_stamp =
		(	select
				max(date_stamp)
			from
				dbo.audit_trail
			where
				serial = @SerialNumber and
				audit_trail.type = 'R')

if	@ReceiptQty is null begin
	set	@Result = 999999
	RAISERROR ('Error reading receipt quantity for serial %d in procedure %s.', 16, 1, @SerialNumber, @ProcName)
	rollback tran @ProcName
	return @Result
end

--	Remove inventory.
--			New audit trail record for reversal.
--- <Insert Rows="1">
set	@TableName = 'dbo.audit_trail'

insert	audit_trail
(	serial, date_stamp, type, part,
	quantity, remarks, price, vendor,
	po_number, operator, from_loc, to_loc,
	on_hand, lot, weight, status,
	shipper, unit, std_quantity, cost, control_number,
	custom1, custom2, custom3, custom4, custom5,
	plant, notes, gl_account, package_type,
	release_no, std_cost,
	user_defined_status,
	part_name, tare_weight, field1)
select	at.serial, @TranDT, 'R', at.part,
	-at.quantity, 'Receiving', at.price, at.vendor,
	at.po_number, @User, at.from_loc, at.to_loc,
	IsNull(po.on_hand, 0) - at.std_quantity, at.lot, at.weight, at.status,
	at.shipper, at.unit, -at.std_quantity, at.cost, at.control_number,
	at.custom1, at.custom2, at.custom3, at.custom4, at.custom5,
	at.plant, at.notes, at.gl_account, at.package_type,
	at.release_no, at.std_cost, at.user_defined_status,
	at.part_name, at.tare_weight, at.field1
from
	audit_trail at
	left join dbo.part_online po on
		at.part = po.part
where
	at.serial = @SerialNumber and
	at.type = 'R' and
	at.date_stamp =
	(	select
			max(date_stamp)
		from
			dbo.audit_trail
		where
			serial = @SerialNumber and
			audit_trail.type = 'R' )

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, 1)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--			Remove object records.
declare
	@PartClass char(1)

select
	@PartClass = coalesce(class, 'N')
from
	part
where
	part = @PartCode

--- <Delete Rows="1">
set	@TableName = 'dbo.object'
delete
	dbo.object
where
	serial = @SerialNumber
		
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
if	@RowCount != 1 
	and
		@PartClass != 'N' begin
	set	@Result = 900102
	RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, 1)
	rollback tran @ProcName
	return @Result
end
--- </Delete>
	
--			Update part online.
--- <Update>
set	@TableName = 'dbo.part_online'

update
	dbo.part_online
set
	on_hand =
	(	select
			Sum(std_quantity)
		from
			dbo.object
		where
			part = part_online.part and
			status = 'A')
where
	part = @PartCode

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--	Restore Purchase Order using data from History.
--- <Update>
set	@TableName = 'dbo.po_detail'

update
	po_detail
set	po_detail.received = po_detail.received - po_detail_history.last_recvd_amount
,	po_detail.balance = po_detail.balance + po_detail_history.last_recvd_amount
,	po_detail.standard_qty = po_detail.standard_qty + po_detail_history.last_recvd_amount
,	po_detail.last_recvd_date = @TranDT
,	po_detail.last_recvd_amount = - po_detail_history.last_recvd_amount
from
	po_detail
	join po_detail_history on
		po_detail_history.po_number = @PONumber
		and
			po_detail_history.part_number = @PartCode
		and
			po_detail_history.row_id = po_detail.row_id
		and
			po_detail_history.date_due = po_detail.date_due
		and
			po_detail_history.last_recvd_date = @ReceiptDT
where
	po_detail.po_number = @PONumber
	and
		po_detail.part_number = @PartCode

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--- <Insert>
set	@TableName = 'po_detail'

insert
	po_detail
(	po_number, vendor_code, part_number, description, unit_of_measure
, 	date_due, requisition_number, status, type, last_recvd_date
,	last_recvd_amount, cross_reference_part, account_code, notes, quantity
,	received, balance, active_release_cum, received_cum, price
,	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price
,	release_no, ship_to_destination, terms, week_no, plant
,	invoice_number, standard_qty, sales_order, dropship_oe_row_id, ship_type
,	dropship_shipper, price_unit, ship_via, release_type, alternate_price)
select
	po_number, vendor_code, part_number, description, unit_of_measure
,	date_due, requisition_number, 'A', type, @TranDT
,	- last_recvd_amount, cross_reference_part, account_code, notes, quantity
,	received - last_recvd_amount, balance + last_recvd_amount, active_release_cum, received_cum, price
,	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price
,	release_no, ship_to_destination, terms, week_no, plant
,	invoice_number, standard_qty + last_recvd_amount, sales_order, dropship_oe_row_id, ship_type
,	dropship_shipper, price_unit, ship_via, release_type, alternate_price
from
	po_detail_history pdh
where
	po_number = @PONumber
	and
		part_number = @PartCode
	and
		last_recvd_date = @ReceiptDT
	and
		not exists
		(	select
				*
			from
				po_detail
			where
				po_number = @PONumber
				and
					part_number = @PartCode
				and
					row_id = pdh.row_id
				and
					date_due = pdh.date_due)

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--	Create undo-receipt history.
--- <Insert>
set	@TableName = 'po_detail_history'

insert
	po_detail_history
(	po_number, vendor_code, part_number, description, unit_of_measure,
	date_due, requisition_number, status, type, last_recvd_date,
	last_recvd_amount, cross_reference_part, account_code, notes, quantity,
	received, balance, active_release_cum, received_cum, price,
	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price,
	release_no, ship_to_destination, terms, week_no, plant,
	invoice_number, standard_qty, sales_order, dropship_oe_row_id, ship_type,
	dropship_shipper, price_unit, ship_via, release_type, alternate_price)
select
	po_number, vendor_code, part_number, description, unit_of_measure,
	date_due, requisition_number, status, type, last_recvd_date,
	last_recvd_amount, cross_reference_part, account_code, notes, quantity,
	received, balance, active_release_cum, received_cum, price,
	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price,
	release_no, ship_to_destination, terms, week_no, plant,
	invoice_number, standard_qty, sales_order, dropship_oe_row_id, ship_type,
	dropship_shipper, price_unit, ship_via, release_type, alternate_price
from
	dbo.po_detail pdh
where
	po_number = @PONumber and
	part_number = @PartCode and
	last_recvd_date = @TranDT

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into / updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

--	Update Part-Vendor relationship.
--- <Update>
set	@TableName = 'dbo.part_vendor'

update
	part_vendor
set
	accum_received = coalesce(accum_received, 0) - @ReceiptStdQty
where
	part = @PartCode and
	vendor =
	(	select
			max(vendor_code)
		from
			dbo.po_detail
		where
			po_number = @PONumber and
			part_number = @PartCode and
			row_id = @POLineNo)

select
	@Error = @@Error
,	@RowCount = @@Rowcount


if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
set	@Result = 0
return @Result

GO
