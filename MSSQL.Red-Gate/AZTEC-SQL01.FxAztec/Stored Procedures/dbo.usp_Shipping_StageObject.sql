SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[usp_Shipping_StageObject]
	@User varchar(5)
,	@Shipper int
,	@BoxOrPalletSerial int
,	@PalletSerial int = null
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
/*	Check if object exists. */
if	not exists
		(	select
				*
			from
				dbo.object o
			where
				o.serial = @BoxOrPalletSerial
		) begin
			
	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Object %d does not exist', 16, 1, @ProcName, @BoxOrPalletSerial)
	rollback tran @ProcName
	return
end

/*	Check if this object is staged. */
if	exists
	(	select
  			*
  		from
  			dbo.object o
  		where
  			o.serial = @BoxOrPalletSerial
  			and o.shipper > 0
  	) begin
  	
  	/*	Check if object is staged to this shipper, done and set result to "NO_ACTION" (100). */
  	if	(	select
				o.shipper
			from
				dbo.object o
			where
				o.serial = @BoxOrPalletSerial
				and o.shipper > 0
		) = @Shipper begin
		set	@Result = 100
		rollback tran @ProcName
		return
	end
	else begin
		declare
			@otherShipper int
		
		select
			@otherShipper = 
			(	select
					o.shipper
				from
					dbo.object o
				where
					o.serial = @BoxOrPalletSerial
					and o.shipper > 0
			) 
			
		/*	Staged to something else, give error. */
		set	@Result = 999999
		RAISERROR ('Error encountered in %s.  Object %d is staged to another shipper %d', 16, 1, @ProcName, @BoxOrPalletSerial, @otherShipper)
		rollback tran @ProcName
		return
	end
end

/*	Check if object is valid...*/
declare
	@objectType char(1)

select
	@objectType = case when o.type is null then 'B' when o.type = 'S' then 'P' end
from
	dbo.object o
where
	o.serial = @BoxOrPalletSerial

/*		Object is approved (except return to vendor shipper)... */
if	exists
		(	select
				*
			from
				dbo.object oBox
			where
				(	(	oBox.serial = @BoxOrPalletSerial
						and @objectType = 'B')
					or
					(	oBox.parent_serial = @BoxOrPalletSerial
						and @objectType = 'P')
				)
				and oBox.status != 'A'
		)
  	and
  	(	select
  			coalesce(type, '')
  		from
  			dbo.shipper s
  		where
  			s.id = @Shipper
  	) != 'V' begin
  	
	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Object %d is not approved', 16, 1, @ProcName, @BoxOrPalletSerial, @otherShipper)
	rollback tran @ProcName
	return
end

/*		Object is valid part for this shipper (scheduled shippers only)... */
if	exists
	(	select
			*
		from
			dbo.object oBox
		where
			(	(	oBox.serial = @BoxOrPalletSerial
						and @objectType = 'B')
					or
					(	oBox.parent_serial = @BoxOrPalletSerial
						and @objectType = 'P')
				)
			and oBOx.part not in
				(	select
						sd.part_original
					from
						dbo.shipper_detail sd
					where
						sd.shipper = @Shipper
				)
	)
  	and
  	(	select
  			type
  		from
  			dbo.shipper s
  		where
  			s.id = @Shipper
  	) is null begin

	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Object %d is not valid for shipper %d, invalid part', 16, 1, @ProcName, @BoxOrPalletSerial, @Shipper)
	rollback tran @ProcName
	return
end

/*	Validate shipper... */
/*		Shipper is open. */
if	(	select
  			s.status
  		from
  			dbo.shipper s
  		where
  			s.id = @Shipper
  	) not in ('O', 'S') begin

	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Shipper %d is not open', 16, 1, @ProcName, @BoxOrPalletSerial, @Shipper)
	rollback tran @ProcName
	return
end
--- </Body>

/*		Shipper is not manual invoice. */
if	(	select
  			s.type
  		from
  			dbo.shipper s
  		where
  			s.id = @Shipper
  	) = 'M' begin

	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Shipper %d is a manual invoice', 16, 1, @ProcName, @BoxOrPalletSerial, @Shipper)
	rollback tran @ProcName
	return
end

/*	Begin staging...*/
/*		Create manual shipper line automatically if unscheduled shipper and line is needed. */
if	(	select
  			s.type
  		from
  			dbo.shipper s
  		where
  			s.id = @Shipper
  	) in ('O', 'Q', 'V', 'T')
  	and exists
	(	select
			*
		from
			dbo.object oBox
		where
			(	(	oBox.serial = @BoxOrPalletSerial
						and @objectType = 'B')
					or
					(	oBox.parent_serial = @BoxOrPalletSerial
						and @objectType = 'P')
				)
			and oBox.part not in
				(	select
						sd.part_original
					from
						dbo.shipper_detail sd
					where
						sd.shipper = @Shipper
				)
	) begin

	--- <Insert rows="1">
	set	@TableName = 'dbo.shipper_detail'
	
	insert
		dbo.shipper_detail
	(	shipper, part, qty_required, qty_packed, qty_original
	,	accum_shipped, order_no, customer_po, release_no, release_date
	,	type, price, account_code, salesman, tare_weight
	,	gross_weight, net_weight, date_shipped, assigned, packaging_job
	,	note, operator, boxes_staged, pack_line_qty, alternative_qty
	,	alternative_unit, week_no, taxable, price_type, cross_reference
	,	customer_part, dropship_po, dropship_po_row_id, dropship_oe_row_id, suffix
	,	part_name, part_original, total_cost, group_no, dropship_po_serial
	,	dropship_invoice_serial, stage_using_weight, alternate_price, old_suffix, old_shipper
	)
	select
		shipper = @Shipper, part = oBox.part, qty_required = 0, qty_packed = 0, qty_original = 0
	,	accum_shipped = null, order_no = 0, customer_po = null, release_no = null, release_date = null
	,	type = null, price = dbo.fn_PartCustomer_GetStandardPrice(oBox.part, s.customer, oBox.std_quantity), account_code = dbo.fn_PartMaster_GetSalesAccount(oBox.part), salesman = dbo.fn_CustomerMaster_GetCustomerSalesrep(s.customer), tare_weight = 0
	,	gross_weight = 0, net_weight = 0, date_shipped = null, assigned = null, packaging_job = null
	,	note = null, operator = @User, boxes_staged = 0, pack_line_qty = 0, alternative_qty = 0
	,	alternative_unit = oBox.unit_measure, week_no = dbo.fn_Accounting_FiscalWeek(null), taxable = null, price_type = null, cross_reference = p.cross_ref
	,	customer_part = null, dropship_po = null, dropship_po_row_id = null, dropship_oe_row_id = null, suffix = null
	,	part_name = p.name, part_original = oBox.part, total_cost = dbo.fn_PartCustomer_GetStandardPrice(oBox.part, s.customer, oBox.std_quantity) * oBox.std_quantity, group_no = null, dropship_po_serial = null
	,	dropship_invoice_serial = null, stage_using_weight = null, alternate_price = null, old_suffix = null, old_shipper = null
	from
		dbo.object oBox
		join dbo.shipper s
			on s.id = @Shipper
		left join dbo.part p
			on p.part = oBox.part
	where
		(	(	oBox.serial = @BoxOrPalletSerial
					and @objectType = 'B')
				or
				(	oBox.parent_serial = @BoxOrPalletSerial
					and @objectType = 'P')
			)
		and oBox.part not in
			(	select
					sd.part_original
				from
					dbo.shipper_detail sd
				where
					sd.shipper = @Shipper
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

/*	Add loose box(es) to shipper. */
--- <Update rows="*">
set	@TableName = 'dbo.object'

update
	oBox
set
	shipper = @Shipper
,	show_on_shipper = case when @PalletSerial is null then 'Y' else 'N' end
,	parent_serial = @PalletSerial
from
	dbo.object oBox
where
	oBox.serial = @BoxOrPalletSerial
	and @objectType = 'B'

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

/*	Add pallet's box(es) to shipper. */
--- <Update rows="*">
set	@TableName = 'dbo.object'

update
	oBox
set
	shipper = @Shipper
,	show_on_shipper = 'N'
from
	dbo.object oBox
where
	oBox.parent_serial = @BoxOrPalletSerial
	and @objectType = 'P'

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

/*	If staging pallet, add pallet to shipper. */
if	@objectType = 'P' begin

	--- <Update rows="1">
	set	@TableName = 'dbo.object'

	update
		oPallet
	set
		shipper = @Shipper
	,	show_on_shipper = 'Y'
	from
		dbo.object oPallet
	where
		oPallet.serial = @BoxOrPalletSerial
		and @objectType = 'P'

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
end

/*	Reconcile shipper. */
--- <Call>	
set	@CallProcName = 'dbo.msp_reconcile_shipper '
execute
	@ProcReturn = dbo.msp_reconcile_shipper 
		@shipper = @Shipper

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 999999
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_Shipping_StageBox
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
