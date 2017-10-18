SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_CreateReceiverLines_fromPlantTReceiverHeader]
	@ReceiverID int
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
declare
	@shipFromPlant varchar(20)
,	@shipToPlant varchar (20)
,	@days int; set @days = 40

select
	@shipFromPlant = rh.ShipFrom
,	@shipToPlant = rh.Plant
from
	dbo.ReceiverHeaders rh
where
	rh.ReceiverID = @ReceiverID
---	</ArgumentValidation>

--- <Body>
/*	Recreate objects that were shipped out. */
if	exists
	(	select
			*
		from
			dbo.audit_trail at
				join dbo.shipper s
					on s.id =
						case when at.shipper not like '%[^0-9]%' then convert(int, at.shipper) end
					and s.plant = @shipFromPlant
			left join dbo.part p
				on p.part = at.part
		where
			at.to_loc = @shipToPlant
			and at.type = 'S'
			and at.date_stamp > getdate() - @days
			and not exists
				(	select
						*
					from
						dbo.audit_trail at2
					where
						at2.serial = at.serial
						and at2.id > at.id
						and at2.type = 'R'
						--and at2.date_stamp > at.date_stamp
				)
			and not exists
				(	select
						*
					from
						dbo.object o
					where
						o.serial = at.serial
				)
	) begin

	--- <Insert rows="1+">
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
		serial = at.serial
	,   part = at.part
	,   location = 'x' + at.to_loc
	,   last_date = @TranDT
	,   unit_measure = at.unit
	,   operator = at.operator
	,   status = at.status
	,   destination = at.destination
	,   station = null
	,   origin = at.origin
	,   cost = at.cost
	,   weight = dbo.fn_Inventory_GetPartNetWeight(at.part, at.std_quantity)
	,   parent_serial = at.parent_serial
	,   note = at.notes
	,   quantity = dbo.udf_GetQtyFromStdQty(at.part, at.std_quantity, at.unit)
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
	,   std_quantity = at.std_quantity
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
			join dbo.shipper s
				on s.id =
					case when at.shipper not like '%[^0-9]%' then convert(int, at.shipper) end
				and s.plant = @shipFromPlant
	where
		at.to_loc = @shipToPlant
		and at.type = 'S'
			and at.date_stamp > getdate() - @days
			and not exists
				(	select
						*
					from
						dbo.audit_trail at2
					where
						at2.serial = at.serial
						and at2.id > at.id
						and at2.type = 'R'
						--and at2.date_stamp > at.date_stamp
				)
			and not exists
				(	select
						*
					from
						dbo.object o
					where
						o.serial = at.serial
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
end

/*	Calculate expected returning objects. */
declare
	@ExpectedObjects table
(	Serial int primary key
,	PartCode varchar(25)
,	Quantity numeric(20,6)
,	PackageType varchar(20)
,	[LineNo] int
)

insert
	@ExpectedObjects
(	Serial
,	PartCode
,	Quantity
,	PackageType
,	[LineNo]
)
select
	at.serial
,	at.part
,	at.std_quantity
,	at.package_type
,	[LineNo] = row_number() over (partition by at.part order by at.serial)
from
	dbo.audit_trail at
		join dbo.shipper s
			on s.id =
				case when at.shipper not like '%[^0-9]%' then convert(int, at.shipper) end
			and s.plant = @shipFromPlant
	join dbo.part p
		on p.part = at.part
where
	at.to_loc = @shipToPlant
	and at.type = 'S'
	and at.date_stamp > getdate() - 90
	and not exists
		(	select
				*
			from
				dbo.audit_trail at2
			where
				at2.serial = at.serial
				and at2.id > at.id
				and at2.type = 'R'
				--and at2.date_stamp > at.date_stamp
		)

/*	Calculate the expected quantity based on material at the outside processor. */
declare
	@ExpectedReceiptQty table
(
	PartCode varchar(25) primary key
,	PackageType varchar(20)  
,	IntransitQuantity numeric(20,6) null
,	Boxes int not null
)

insert
	@ExpectedReceiptQty
(	PartCode
,	PackageType
,	IntransitQuantity
,	Boxes
)
select
	PartCode = eo.PartCode
,	PackageType = max(eo.PackageType)
,	IntransitQuantity = sum(eo.Quantity)
,	Boxes = count(*)
from
	@ExpectedObjects eo
group by
	eo.PartCode

/*	Create default part-vendor relationships. */
if	exists
		(	select
				*
			from
				@ExpectedReceiptQty erq
				join dbo.part p
					on p.part = erq.PartCode
				join dbo.part_inventory pInv
					on pInv.part = erq.PartCode
				left join dbo.part_packaging pp
					on pp.part = erq.PartCode
					and pp.code = erq.PackageType
			where
				not exists
					(	select
							*
						from
							dbo.part_vendor pv
						where
							pv.part = erq.PartCode
							and pv.vendor = @shipFromPlant
					)
		) begin
 
	--- <Insert rows="1+">
	set	@TableName = 'dbo.part_vendor'
	
	insert
		dbo.part_vendor
	(	part
	,	vendor
	,	vendor_part
	,	vendor_standard_pack
	,	accum_received
	,	accum_shipped
	,	outside_process
	,	qty_over_received
	,	receiving_um
	,	part_name
	,	note
	)
	select
		part = erq.PartCode
	,	vendor = @shipFromPlant
	,	vendor_part = erq.PartCode
	,	vendor_standard_pack = coalesce(pp.quantity, pInv.standard_pack)
	,	accum_received = 0
	,	accum_shipped = erq.IntransitQuantity
	,	outside_process = 'N'
	,	qty_over_received = 0
	,	receiving_um = pInv.standard_unit
	,	part_name = p.name
	,	note = 'Intercompany'
	from
		@ExpectedReceiptQty erq
		join dbo.part p
			on p.part = erq.PartCode
		join dbo.part_inventory pInv
			on pInv.part = erq.PartCode
		left join dbo.part_packaging pp
			on pp.part = erq.PartCode
			and pp.code = erq.PackageType
	where
		not exists
			(	select
					*
				from
					dbo.part_vendor pv
				where
					pv.part = erq.PartCode
					and pv.vendor = @shipFromPlant
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
end
 
/*	Create PO headers if necessary. */
if	exists
		(	select
				*
			from
				@ExpectedReceiptQty erq
				join dbo.vendor v
					on v.code = @shipFromPlant
				join dbo.destination_shipping ds
					on ds.destination = @shipFromPlant
				join dbo.part p
					on p.part = erq.PartCode
				join dbo.part_inventory pInv
					on pInv.part = erq.PartCode
				left join dbo.part_packaging pp
					on pp.part = erq.PartCode
					and pp.code = erq.PackageType
			where
				not exists
					(	select
							*
						from
							dbo.po_header ph
						where
							ph.blanket_part = erq.PartCode
							and ph.vendor_code = @shipFromPlant
					)
		) begin

	--- <Insert rows="1+">
	set	@TableName = 'dbo.po_header'
	
	insert
	dbo.po_header
	(	po_number
	,	vendor_code
	,	po_date
	,	terms
	,	fob
	,	ship_via
	,	ship_to_destination
	,	status
	,	type
	,	description
	,	plant
	,	freight_type
	,	buyer
	,	notes
	,	blanket_part
	,	blanket_vendor_part
	,	std_unit
	,	ship_type
	,	release_control
	,	trusted
	,	currency_unit
	)
	select
		po_number = NextPO + row_number() over (order by erq.PartCode)
	,	vendor_code = @shipFromPlant
	,	po_date = getdate()
	,	terms = v.terms
	,	fob = ds.fob
	,	ship_via = ds.scac_code
	,	ship_to_destination = @shipToPlant
	,	status = 'A'
	,	type = 'B'
	,	description = p.name
	,	plant = @shipFromPlant
	,	freight_type = ds.freight_type
	,	buyer = v.buyer
	,	notes = 'Intercompany PO'
	,	blanket_part = erq.PartCode
	,	blanket_vendor_part = erq.PartCode
	,	std_unit = pInv.standard_unit
	,	ship_type = 'Transfer'
	,	release_control = 'A'
	,	trusted = 'Y'
	,	currency_unit = v.default_currency_unit
	from
		@ExpectedReceiptQty erq
		join dbo.vendor v
			on v.code = @shipFromPlant
		join dbo.destination_shipping ds
			on ds.destination = @shipFromPlant
		join dbo.part p
			on p.part = erq.PartCode
		join dbo.part_inventory pInv
			on pInv.part = erq.PartCode
		left join dbo.part_packaging pp
			on pp.part = erq.PartCode
			and pp.code = erq.PackageType
		cross join
			(	select
					NextPO = p.purchase_order
				from
					dbo.parameters p with (tablockx)
			) parm
	where
		not exists
			(	select
					*
				from
					dbo.po_header ph
				where
					ph.blanket_part = erq.PartCode
					and ph.vendor_code = @shipFromPlant
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
	
	/*	Set next PO Number. */
	update
		p
	set
		purchase_order = p.purchase_order + @RowCount
	from
		dbo.parameters p
end      

/*	Create PO line item for items to be received against.*/
declare
	@expectedRows int

set	@expectedRows =
		(	select
				count(*)
			from
				@ExpectedReceiptQty erq
		)

--- <Update rows=@expectedRows>
set	@TableName = 'dbo.po_detail'

update
	pd
set
	quantity = pd.received + erq.IntransitQuantity
,	balance = erq.IntransitQuantity
,	standard_qty = pd.received + erq.IntransitQuantity
from
	dbo.po_detail pd
	join dbo.po_header ph
		on ph.po_number = pd.po_number
		and ph.ship_type = 'TRANSFER'
		and ph.status != 'C'
	join @ExpectedReceiptQty erq
		on erq.PartCode = ph.blanket_part
where
	ph.vendor_code = @shipFromPlant
	and pd.date_due =
		(	select
				min(pd2.date_due)
			from
				dbo.po_detail pd2
			where
				pd2.po_number = pd.po_number
				and pd2.part_number = pd.part_number
		)
	and pd.row_id =
		(	select
				min(pd2.row_id)
			from
				dbo.po_detail pd2
			where
				pd2.po_number = pd.po_number
				and pd2.part_number = pd.part_number
				and pd2.date_due = pd.date_due
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @expectedRows begin
	--- <Insert rows=@expctedRows - @RowCount>
	set	@TableName = 'dbo.po_detail'
	
	insert
		dbo.po_detail
	(	po_number
	,	vendor_code
	,	part_number
	,	description
	,	unit_of_measure
	,	date_due
	,	status
	,	type
	,	account_code
	,	quantity
	,	received
	,	balance
	,	price
	,	alternate_price
	,	row_id
	,	release_no
	,	ship_to_destination
	,	terms
	,	week_no
	,	plant
	,	standard_qty
	,	ship_type
	)
	select
		po_number = ph.po_number
	,	vendor_code = ph.vendor_code
	,	part_number = ph.blanket_part
	,	description = p.name
	,	unit_of_measure = pv.receiving_um
	,	date_due = FT.fn_TruncDate('day', @TranDT)
	,	status = 'A'
	,	type = 'B'
	,	account_code = pp.gl_account_code
	,	quantity = dbo.udf_GetQtyFromStdQty(ph.blanket_part, erq.IntransitQuantity, pv.receiving_um)
	,	received = 0
	,	balance = dbo.udf_GetQtyFromStdQty(ph.blanket_part, erq.IntransitQuantity, pv.receiving_um)
	,	price = ph.price
	,	alternate_price = ph.price
	,	row_id = coalesce((select max(row_id) + 1 from dbo.po_detail pd where pd.po_number = ph.po_number), 1)
	,	release_no = ph.release_no
	,	ship_to_destination = @shipToPlant
	,	terms = ph.terms
	,	week_no = datediff(week, parm.fiscal_year_begin, @TranDT)
	,	plant = ph.plant
	,	standard_qty = erq.IntransitQuantity
	,	ship_type = ph.ship_type
	from
		dbo.po_header ph
		join @ExpectedReceiptQty erq
			on erq.PartCode = ph.blanket_part
		join dbo.part p
			on p.part = ph.blanket_part
		join dbo.part_purchasing pp
			on pp.part = ph.blanket_part
		join dbo.part_vendor pv
			on pv.vendor = ph.vendor_code
			and pv.part = ph.blanket_part
		cross join dbo.parameters parm
	where
		ph.ship_type = 'TRANSFER'
		and ph.status != 'C'
		and not exists
			(	select
					*
				from
					dbo.po_detail pd
				where
					pd.po_number = ph.po_number
					and pd.part_number = ph.blanket_part
			)
	
	select
		@Error = @@Error,
		@RowCount = @RowCount + @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != @expectedRows begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @expectedRows)
		rollback tran @ProcName
		return
	end
	--- </Insert>
end
--- </Update>

/*	Build requirements summary. */
declare
	@Requirements table
(	ReceiverID int
,	PartCode varchar(25)
,	PONumber integer
,	POLineNo integer
,	POLineDueDate datetime
,	PackageType varchar(20)
,	POBalance numeric(20, 6)
,	StdPackQty numeric(20, 6)
)

insert
	@Requirements
(	ReceiverID
,	PartCode
,	PONumber
,	POLineNo
,	POLineDueDate
,	PackageType
,	POBalance
,	StdPackQty
)
select
	ReceiverID = @ReceiverID,
	PartCode = pd.part_number,
	PONumber = pd.po_number,
	POLineNo = pd.row_id,
	POLineDueDate = pd.date_due,
	PackageType =
	(	select
			min(part_packaging.code)
		from
			dbo.part_packaging part_packaging
		where
			part_packaging.part = pd.part_number
		and	part_packaging.quantity = PartSupplierStdPack.StdPack),
	POBalance = pd.balance,
	StdPackQty = coalesce(PartSupplierStdPack.StdPack, pd.balance)
from
	dbo.po_detail pd
		join dbo.po_header ph on
			pd.po_number = ph.po_number
		join dbo.destination d on
			d.destination = @shipFromPlant
			and
				d.vendor = pd.vendor_code
	left join
	(	select
			Part = p.part,
			SupplierCode = pv.vendor,
			StdPack = coalesce (nullif(pv.vendor_standard_pack, 0.0), nullif(pi.standard_pack, 0.0), -1)
		from
			dbo.part p
			left join dbo.part_inventory pi on
				p.part = pi.part
			left join dbo.part_vendor pv on
				p.part = pv.part
	) PartSupplierStdPack on
		pd.part_number = PartSupplierStdPack.Part
		and
			pd.vendor_code = PartSupplierStdPack.SupplierCode
where
	pd.balance > 0

--		Load to temp table to generate line no's.
select
	ReceiverID
,	[LineNo] = identity(int, 1, 1)
,	PartCode
,	PONumber
,	POLineNo
,	POLineDueDate
,	PackageType
,	Boxes
,	StdPackQty
,	PriorAccum = convert(numeric(20,6), 0)
,	PostAccum = convert(numeric(20,6), 0)
into
	#ReceiverLines
from
	(
		select
			r.ReceiverID
		,	r.PartCode
		,	r.PONumber
		,	r.POLineNo
		,	r.POLineDueDate
		,	r.PackageType
		,	Boxes = ceiling(r.POBalance / r.StdPackQty)
		,	r.StdPackQty
		from
			@Requirements r
		where
			r.POBalance > 0
	) Requirements
order by
	PartCode
,	PONumber
,	POLineNo
,	Boxes desc

update
	#ReceiverLines
set
	PostAccum =
		(	select
				sum(Boxes * StdPackQty)
			from
				#ReceiverLines rl2
			where
				PartCode = rl.PartCode
				and [LineNo] <= rl.[LineNo]
		)
from
	#ReceiverLines rl

update
	#ReceiverLines
set
	PriorAccum = PostAccum - (Boxes * StdPackQty)

--	Recalculate Receiver Objects and Receiver Lines.
--		Remove old receiver objects (not yet received against).
--- <Delete>
set	@TableName = 'dbo.ReceiverObjects'

delete
	dbo.ReceiverObjects
from
	dbo.ReceiverObjects rlo
		join dbo.ReceiverLines rl
			on rlo.ReceiverLineID = rl.ReceiverLineID
			and rl.ReceiverID = @ReceiverID
where
	 rlo.Status = 0	

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Delete>

--		Remove old receiver line (not yet received against).
--- <Delete>
set	@TableName = 'dbo.ReceiverLines'

delete
	dbo.ReceiverLines
from
	dbo.ReceiverLines rl
where
	ReceiverID = @ReceiverID
	and not exists
		(	select
				*
			from
				dbo.ReceiverObjects ro
			where
				ReceiverLineID = rl.ReceiverLineID
		)

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
--- </Delete>

--		Set quantity remaining on lines that have been partially received.
--- <Update>
set	@TableName = 'dbo.ReceiverLines'

update
	dbo.ReceiverLines
set
	RemainingBoxes =
		case
			when erq.PartCode is null then 0
			else erq.Boxes
		end
,	StdPackQty =
		case
			when erq.PartCode is null then 0
			when rl2.PostAccum > erq.IntransitQuantity then ceiling (erq.IntransitQuantity - rl2.PriorAccum)
			else rl2.StdPackQty
		end
,	[LineNo] =
		(	select
				count(1)
			from
				dbo.ReceiverLines
			where
				ReceiverID = @ReceiverID
				and [LineNo] <= rl.[LineNo]
		)
from
	dbo.ReceiverLines rl
	join #ReceiverLines rl2
		on rl.PartCode = rl2.PartCode
		and	rl.PONumber = rl2.PONumber
		and	rl.POLineNo = rl2.POLineNo
		and	rl.POLineDueDate = rl2.POLineDueDate
	left join @ExpectedReceiptQty erq
		on rl.PartCode = erq.PartCode
		and	rl2.PriorAccum < erq.IntransitQuantity
where
	rl.ReceiverID = @ReceiverID

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

--		Create new receiver lines.
--- <Insert>
set	@TableName = 'dbo.ReceiverLines'

insert
	dbo.ReceiverLines
(	ReceiverID,
	[LineNo],
	PartCode,
	PONumber,
	POLineNo,
	POLineDueDate,
	PackageType,
	RemainingBoxes,
	StdPackQty)
select
	rl.ReceiverID,
	rl.[LineNo] + coalesce(
		(	select
				max([LineNo])
			from
				dbo.ReceiverLines
			where
				ReceiverID = @ReceiverID), 0
		),
	rl.PartCode,
	rl.PONumber,
	rl.POLineNo,
	rl.POLineDueDate,
	rl.PackageType,
	RemainingBoxes = rl.Boxes,
	StdPackQty = rl.StdPackQty
from
	#ReceiverLines rl
	join @ExpectedReceiptQty erq
		on rl.PartCode = erq.PartCode
		and	rl.PriorAccum <= erq.IntransitQuantity
where
	not exists
	(	select
			*
		from
			dbo.ReceiverLines rl2
		where
			rl.ReceiverID = rl2.ReceiverID
			and	rl.PartCode = rl2.PartCode
			and	rl.PONumber = rl2.PONumber
			and	rl.POLineNo = rl2.POLineNo
			and	rl.POLineDueDate = rl2.POLineDueDate
	)


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

--		Create new receiver objects.
--- <Insert>
set	@TableName = 'dbo.ReceiverLines'

insert
	dbo.ReceiverObjects
(	ReceiverLineID
,	[LineNo]
,	Status
,	PONumber
,	POLineNo
,	POLineDueDate
,	Serial
,	PartCode
,	PartDescription
,	EngineeringLevel
,	QtyObject
,	PackageType
,	Location
,	Plant
,	DrAccount
,	CrAccount)
select
	rl.ReceiverLineID
,	[LineNo] = eo.[LineNo] +
		coalesce
		(	(	select
					max([LineNo])
				from
					dbo.ReceiverObjects
				where
					ReceiverLineID = rl.ReceiverLineID
			)
		,	0
		)
,	0
,	rl.PONumber
,	rl.POLineNo
,	rl.POLineDueDate
,	Serial = eo.Serial
,	rl.PartCode
,	PartDescription = p.name
,	EngineeringLevel = p.engineering_level
,	eo.Quantity
,	eo.PackageType
,	case coalesce(p.class, 'N') when 'N' then '' else coalesce((select max(plant) from po_header where po_number =rl.PONumber),pi.primary_location) end
,	coalesce((select max(plant) from po_header where po_number =rl.PONumber),l.plant)
,	p.gl_account_code
,	pp.gl_account_code
from
	dbo.ReceiverLines rl
	join #ReceiverLines rl2
		on rl.PartCode = rl2.PartCode
		and	rl.PONumber = rl2.PONumber
		and	rl.POLineNo = rl2.POLineNo
		and	rl.POLineDueDate = rl2.POLineDueDate
	join @ExpectedReceiptQty erq
		on rl.PartCode = erq.PartCode
		and	rl2.PriorAccum <= erq.IntransitQuantity
	join @ExpectedObjects eo
		on eo.PartCode = rl.PartCode
		and eo.[LineNo] <= rl.RemainingBoxes
	left join dbo.part p on rl.PartCode = p.part
	left join dbo.part_inventory pi on rl.PartCode = pi.part
	left join dbo.location l on pi.primary_location = l.code
	left join dbo.part_purchasing pp on rl.PartCode = pp.part
where
	rl.ReceiverID = @ReceiverID

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
--- </Body>

--		Done with temporary receiver lines.
drop table #ReceiverLines

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
	@ReceiverID int

set	@ReceiverID = 127

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromPlantTReceiverHeader
	@ReceiverID = @ReceiverID
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.ReceiverLines rl
where
	rl.ReceiverID = @ReceiverID

select
	ro.*
from
	dbo.ReceiverObjects ro
		join dbo.ReceiverLines rl
			on ro.ReceiverLineID = rl.ReceiverLineID
where
	rl.ReceiverID = @ReceiverID
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
