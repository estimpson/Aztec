SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_Purchasing_AddReceipt]
	@User varchar(5)
,	@PONumber int
,	@PartCode varchar(25) = null
,	@PODueDT datetime = null
,	@PORowID int = null
,	@QtyReceived numeric(20,6)
,	@TranDT datetime = null out
,	@Result int = null out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn int,
	@ProcResult int,
	@Error int,
	@RowCount int

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
/*	If this is a blanket PO, get part from header, set due date and row id to null. */
if	exists
		(	select
				*
			from
				dbo.po_header ph
			where
				ph.po_number = @PONumber
				and ph.type = 'B'
		) begin
	
	select
		@PartCode =
			(	select
					ph.blanket_part
				from
					dbo.po_header ph
				where
					ph.po_number = @PONumber
					and ph.type = 'B'
			)
	,	@PODueDT = null
	,	@PORowID = null
end

/*	Get all releases matching criteria. */
declare
	@POReleases table
(	ID int not null IDENTITY(1, 1) primary key
,	PONumber int
,	PartCode varchar(25)
,	DueDT datetime
,	RowID int
,	QtyDue numeric(20,6)
,	Unit char(2)
,	PriorAccum numeric(20,6)
,	QtyReceived numeric(20,6)
,	QtyOverReceived numeric(20,6)
)

insert
	@POReleases
(	PONumber
,	PartCode
,	DueDT
,	RowID
,	QtyDue
,	Unit
)
select
	PONumber = pd.po_number
,	PartCode = pd.part_number
,	DueDT = pd.date_due
,	RowID = pd.row_id
,	QtyDue = pd.standard_qty
,	Unit = coalesce(pd.unit_of_measure, pInv.standard_unit)
from
	dbo.po_detail pd
	left join dbo.part_inventory pInv
		on pInv.part = pd.part_number
where
	pd.status = 'A'
	and pd.po_number = @PONumber
	and pd.part_number = @PartCode
	and pd.date_due = coalesce(@PODueDT, pd.date_due)
    and pd.row_id = coalesce(@PORowID, pd.row_id)
order by
	pd.date_due
,	pd.row_id

update
	pr
set
	PriorAccum = coalesce
	(	(	select
				sum(pr2.QtyDue)
			from
				@POReleases pr2
			where
				pr2.ID < pr.ID
		)
	,	0
	)
from
	@POReleases pr

update
	pr
set
	QtyReceived =
		case
			when pr.PriorAccum > @QtyReceived then 0
			else
				case
					when @QtyReceived > pr.PriorAccum + pr.QtyDue then pr.QtyDue
					else @QtyReceived - pr.PriorAccum
				end
		end
from
	@POReleases pr

update
	pr
set
	QtyOverReceived =
		case
			when
				pr.PriorAccum + pr.QtyDue < @QtyReceived
				and not exists
					(	select
							*
						from
							@POReleases pr2
						where
							pr2.ID > pr.ID
					) then @QtyReceived - (pr.PriorAccum + pr.QtyDue)
			else 0
		end
from
	@POReleases pr

/*	Write changes to PO detail. */
--- <Update rows="1+">
set	@TableName = 'dbo.po_detail'

update
	pd
set
	received = pd.received + dbo.udf_GetQtyFromStdQty(pr.PartCode, pr.QtyReceived + pr.QtyOverReceived, pr.Unit)
,	balance = pd.balance - dbo.udf_GetQtyFromStdQty(pr.PartCode, pr.QtyReceived, pr.Unit)
,	standard_qty = pd.standard_qty - pr.QtyReceived
,	last_recvd_date = @TranDT
,	last_recvd_amount = pr.QtyReceived + pr.QtyOverReceived
from
	dbo.po_detail pd
	join @POReleases pr
		on pr.PONumber = pd.po_number
		and pr.PartCode = pd.part_number
		and pr.DueDT = pd.date_due
		and pr.RowID = pd.row_id
		and pr.QtyReceived + pr.QtyOverReceived > 0

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
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Write receipt history. */
--- <Insert>
set	@TableName = 'dbo.po_detail_history'

insert
	dbo.po_detail_history
(	po_number, vendor_code, part_number, description, unit_of_measure
, 	date_due, requisition_number, status, type, last_recvd_date
,	last_recvd_amount, cross_reference_part, account_code, notes, quantity
,	received, balance, active_release_cum, received_cum, price
,	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price
,	release_no, ship_to_destination, terms, week_no, plant
,	invoice_number, standard_qty, sales_order, dropship_oe_row_id, ship_type
,	dropship_shipper, price_unit, ship_via, release_type, alternate_price)
select
	pd.po_number, pd.vendor_code, pd.part_number, pd.description, pd.unit_of_measure
,	pd.date_due, pd.requisition_number, pd.status, pd.type, pd.last_recvd_date
,	pd.last_recvd_amount, pd.cross_reference_part, pd.account_code, pd.notes, pd.quantity
,	pd.received, pd.balance, pd.active_release_cum, pd.received_cum, pd.price
,	pd.row_id, pd.invoice_status, pd.invoice_date, pd.invoice_qty, pd.invoice_unit_price
,	pd.release_no, pd.ship_to_destination, pd.terms, pd.week_no, pd.plant
,	pd.invoice_number, pd.standard_qty, pd.sales_order, pd.dropship_oe_row_id, pd.ship_type
,	pd.dropship_shipper, pd.price_unit, pd.ship_via, pd.release_type, pd.alternate_price
from
	dbo.po_detail pd
	join @POReleases pr
		on pr.PONumber = pd.po_number
		and pr.PartCode = pd.part_number
		and pr.DueDT = pd.date_due
		and pr.RowID = pd.row_id
		and pr.QtyReceived + pr.QtyOverReceived > 0

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

/*	If blanket, delete completed releases. */
if	exists
		(	select
				*
			from
				dbo.po_header ph
			where
				ph.po_number = @PONumber
				and ph.type = 'B'
		) begin

	--- <Delete rows="*">
	set	@TableName = 'dbo.po_detail'
	
	delete
		pd
	from
		dbo.po_detail pd
		join @POReleases pr
			on pr.PONumber = pd.po_number
			and pr.PartCode = pd.part_number
			and pr.DueDT = pd.date_due
			and pr.RowID = pd.row_id
	where
		pd.balance <= 0
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end

/*	Update part-vendor relationship. */
--- <Update rows="1">
set	@TableName = 'dbo.part_vendor'

update
	pv
set
	accum_received = coalesce(accum_received, 0) + @QtyReceived
from
	dbo.part_vendor pv
where
	pv.part = @PartCode
	and	pv.vendor =
		(	select
				max(ph.vendor_code)
			from
				dbo.po_header ph
			where
				ph.po_number = @PONumber
		)

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	--- <Insert rows="1">
	set	@TableName = 'dbo.part_vendor'
	
	insert
		dbo.part_vendor
	(	part
	,	vendor
	,	vendor_part
	,	accum_received
	,	part_name
	,	note
	)
	select
		part = @PartCode
	,	vendor = ph.vendor_code
	,	vendor_part = coalesce(ph.blanket_vendor_part, '')
	,	accum_received = @QtyReceived
	,	part_name = coalesce(p.name, 'Non-recurring')
	,	note = 'Auto-created during receipt'
	from
		dbo.po_header ph
			left join dbo.part p
				on p.part = @PartCode
	where
		ph.po_number = @PONumber
	
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
--- </Update>
--- </Body>

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
	@User varchar(5) = 'EES'
,	@PONumber int = 320
,	@PartCode varchar(25) = 'DSM 9120'
,	@PODueDT datetime = '2013-04-12 00:00:00.000'
,	@PORowID int = 1
,	@QtyReceived numeric(20,6) = 4

begin transaction Test

declare
	@ProcReturn int
,	@TranDT datetime
,	@ProcResult int
,	@Error int

execute
	@ProcReturn = dbo.usp_Purchasing_AddReceipt
	@User = @User
,	@PONumber = @PONumber
,	@PartCode = @PartCode
,	@PODueDT = @PODueDT
,	@PORowID = @PORowID
,	@QtyReceived = @QtyReceived
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
