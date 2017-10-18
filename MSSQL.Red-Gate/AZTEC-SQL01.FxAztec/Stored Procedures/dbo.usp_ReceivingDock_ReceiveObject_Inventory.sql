SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_ReceiveObject_Inventory]
	@User varchar(5)
,	@PONumber int
,	@PartCode varchar(25)
,	@PODueDT datetime
,	@PORowID int
,	@PackageType varchar(20)
,	@PerBoxQty numeric(20,6)
,	@NewObjects int
,	@Shipper varchar(20)
,	@LotNumber varchar(20)
,	@Location varchar(10) = null
,	@UserDefinedStatus varchar(30) = null
,	@IntercompanyReceipt bit
,	@TransferReceipt bit
,	@SerialNumber int out
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
/*	Empty location is null. */
set @Location = nullif(@Location, '')

declare
	@atType char(1)
,	@atRemarks varchar(10)

set @atType = case when @TransferReceipt = 1 then 'T' else 'R' end
set @atRemarks = case when @TransferReceipt = 1 then 'Transfer' else 'Receipt' end

/*	Handle intercompany and transfer receipts by setting the appropriate object properties. */
if	@IntercompanyReceipt = 1
	or @TransferReceipt = 1 begin
	
	--- <Update rows="1">
	set	@TableName = 'dbo.object'
	
	update
		o
	set
		location = @Location
	,	operator = @User
	,	last_date = @TranDT
	,	last_time = @TranDT
	,	cost = coalesce(pd.price, o.cost)
	,	std_cost = coalesce(ps.cost_cum, pd.price, o.std_cost)
	,	lot = @LotNumber
	from
		dbo.object o
		left join dbo.po_detail pd
			on pd.po_number = @PONumber
			and pd.part_number = @PartCode
			and pd.date_due = @PODueDT
			and pd.row_id = @PORowID
		left join dbo.part_standard ps
			on ps.part = @PartCode
	where
		o.serial = @SerialNumber
	
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

		/*	Create audit trail for receipt of existing serial (intercompany). */
	--- <Insert>
	set	@TableName = 'dbo.audit_trail'

	insert
		audit_trail
	(	serial, date_stamp, type, part
	,	quantity, remarks, price, vendor
	,	po_number, operator, from_loc, to_loc
	,	on_hand, lot
	,	weight
	,	status
	,	shipper, unit, std_quantity, cost, control_number
	,	custom1, custom2, custom3, custom4, custom5
	,	plant, notes, gl_account, package_type
	,	release_no, std_cost
	,	user_defined_status
	,	part_name, tare_weight, field1
	)
	select
		o.serial, @TranDT, @atType, pd.part_number
	,	dbo.udf_GetQtyFromStdQty(o.part, @PerBoxQty, o.unit_measure), @atRemarks, pd.price, ph.vendor_code
	,	convert(varchar, @PONumber), @User, ph.vendor_code, o.location
	,	dbo.udf_GetPartQtyOnHand(o.part), @LotNumber
	,	dbo.fn_Inventory_GetPartNetWeight(o.part, @PerBoxQty)
	,	case
			when coalesce(pv.outside_process, 'N') = 'Y' and l.code in (select code from vendor where coalesce(outside_processor,'N') = 'Y') then 'P'
			else coalesce(o.status, 'A')
		end
	,	@Shipper, pd.unit_of_measure, @PerBoxQty, pd.price, convert(varchar, pd.requisition_id)
	,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
	,	l.plant, null /*note*/, pp.gl_account_code, @PackageType
	,	convert(varchar, pd.release_no), o.cost
	,	case
			when coalesce(p.quality_alert, 'N') = 'Y' then 'On Hold'
			else coalesce(o.user_defined_status, 'A', 'Approved')
		end
	,	coalesce(o.name, pd.description), coalesce(o.tare_weight, pm.weight), '' /*field1*/
	from
		dbo.object o
		left join dbo.po_detail pd
			on pd.po_number = @PONumber
			and pd.part_number = @PartCode
			and pd.date_due = @PODueDT
			and pd.row_id = @PORowID
		left join dbo.po_header ph
			on pd.po_number = ph.po_number
		left join part p
			on pd.part_number = p.part
		left join part_inventory pi
			on pd.part_number = pi.part
		left join location l
			on pi.primary_location = l.code
		left outer join part_purchasing pp
			on pd.part_number = pp.part
		left outer join part_vendor pv
			on pd.part_number = pv.part
			and ph.vendor_code = pv.vendor
		left join dbo.package_materials pm
			on pm.code = @PackageType
		cross join parameters
	where
		o.serial = @SerialNumber

	select
		@Error = @@Error
	,	@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return @Result
	end
	if	@RowCount != @NewObjects begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NewObjects)
		rollback tran @ProcName
		return @Result
	end
	--- </Insert>
end
/*	Handle new-inventory receipts by creating object(s). */
else begin
	
	/*	Get first serial number. */
	--- <Call>
	declare
		@NewSerial int

	set	@CallProcName = 'monitor.usp_NewSerialBlock'
	execute
		@ProcReturn = monitor.usp_NewSerialBlock
		@SerialBlockSize = @NewObjects
	,	@FirstNewSerial = @NewSerial out
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
	
	/*		Create inventory. */
	select
		Serial = @NewSerial + RowNumber - 1
	into
		#NewSerials
	from
		dbo.udf_Rows (@NewObjects)

	--- <Insert rows=@NewObjects>
	set	@TableName = 'dbo.object'

	insert
		object
	(	serial, part, lot, location
	,	last_date, unit_measure, operator
	,	status
	,	origin, cost, note, po_number
	,	name, plant, quantity, last_time
	,	package_type, std_quantity
	,	custom1, custom2, custom3, custom4, custom5
	,	user_defined_status
	,	std_cost, field1
	)
	select
		ns.Serial, pd.part_number, @LotNumber, l.code
	,	@TranDT, coalesce(pd.unit_of_measure, pInv.standard_unit), @User
	,	case
			when coalesce(pv.outside_process, 'N') = 'Y' and l.code in (select code from vendor where coalesce(outside_processor,'N') = 'Y') then 'P'
			else uds.type
		end
	,	@Shipper, pd.price, null /*note*/, convert(varchar, @PONumber)
	,	p.name, l.plant, dbo.udf_GetQtyFromStdQty(pd.part_number, @PerBoxQty, coalesce(pd.unit_of_measure, pInv.standard_unit)), @TranDT
	,	@PackageType, @PerBoxQty
	,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
	,	uds.display_name
	,	coalesce(ps.cost_cum, pd.price), '' /*field1*/
	from
		#NewSerials ns
		left join dbo.po_detail pd
			on pd.po_number = @PONumber
			and pd.part_number = @PartCode
			and pd.date_due = @PODueDT
			and pd.row_id = @PORowID
		left join dbo.po_header ph
			on pd.po_number = ph.po_number
		left join dbo.part_vendor pv
			on pd.part_number = pv.part
			and ph.vendor_code = pv.vendor
		join dbo.part p
			on pd.part_number = p.part
		join dbo.part_inventory pInv
			on pd.part_number = pInv.part
		left join dbo.part_standard ps
			on ps.part = pd.part_number
		join dbo.location l
			on coalesce (@Location, pInv.primary_location) = l.code
		join dbo.user_defined_status uds
			on uds.display_name = coalesce
				(	@UserDefinedStatus
				,	case
						when coalesce(pv.outside_process, 'N') = 'Y' then 'Approved'
						when coalesce(p.quality_alert, 'N') = 'Y' then 'On Hold'
						else 'Approved'
					end
				)
	where
		exists
			(	select
					*
				from
					dbo.part p
				where
					p.part = @PartCode
					and p.class != 'N'
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
	if	@RowCount != @NewObjects
		and exists
			(	select
					*
				from
					dbo.part p
				where
					p.part = @PartCode
					and p.class != 'N'
			) begin
		set	@Result = 900102
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NewObjects)
		rollback tran @ProcName
		return @Result
	end
	--- </Insert>

	/*	Write audit trail. */
	--- <Insert>
	set	@TableName = 'dbo.audit_trail'

	insert
		audit_trail
	(	serial, date_stamp, type, part
	,	quantity, remarks, price, vendor
	,	po_number, operator, from_loc, to_loc
	,	on_hand, lot
	,	weight
	,	status
	,	shipper, unit, std_quantity, cost, control_number
	,	custom1, custom2, custom3, custom4, custom5
	,	plant, notes, gl_account, package_type
	,	release_no, std_cost
	,	user_defined_status
	,	part_name, tare_weight, field1)
	select
		ns.Serial, @TranDT, @atType, pd.part_number
	,	dbo.udf_GetQtyFromStdQty(@PartCode, @PerBoxQty, coalesce(o.unit_measure, pd.unit_of_measure, pInv.standard_unit)), @atRemarks, pd.price, ph.vendor_code
	,	convert(varchar, @PONumber), @User, ph.vendor_code, coalesce(o.location, @Location, 'NONINV')
	,	dbo.udf_GetPartQtyOnHand(@PartCode), @LotNumber
	,	coalesce (o.weight, dbo.fn_Inventory_GetPartNetWeight(@PartCode, @PerBoxQty))
	,	case
			when coalesce(pv.outside_process, 'N') = 'Y' and l.code in (select code from vendor where coalesce(outside_processor,'N') = 'Y') then 'P'
			else uds.type
		end
	,	@Shipper, coalesce(o.unit_measure, pd.unit_of_measure, pInv.standard_unit), @PerBoxQty, pd.price, convert(varchar, pd.requisition_id)
	,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
	,	l.plant, null /*note*/, pp.gl_account_code, @PackageType
	,	convert(varchar, pd.release_no), coalesce(ps.cost_cum, pd.price)
	,	uds.display_name
	,	coalesce(o.name, pd.description), coalesce(o.tare_weight, pm.weight), '' /*field1*/
	from
		#NewSerials ns
		left join dbo.object o on
			ns.Serial = o.serial
		left join dbo.po_detail pd on
			pd.po_number = @PONumber
			and pd.part_number = @PartCode
			and pd.date_due = @PODueDT
			and pd.row_id = @PORowID
		join dbo.po_header ph on
			pd.po_number = ph.po_number
		left join dbo.part p on
			pd.part_number = p.part
		left join dbo.part_inventory pInv on
			pd.part_number = pInv.part
		left join dbo.location l on
			l.code = coalesce(o.location, @Location, pInv.primary_location)
		left outer join dbo.part_online po on
			pd.part_number = po.part
		left outer join dbo.part_purchasing pp on
			pd.part_number = pp.part
		left outer join dbo.part_vendor pv on
			pd.part_number = pv.part
			and ph.vendor_code = pv.vendor
		left join dbo.package_materials pm on
			pm.code = @PackageType
		left join dbo.part_standard ps
			on ps.part = pd.part_number
		cross join parameters
		join dbo.user_defined_status uds
			on uds.display_name = coalesce
				(	@UserDefinedStatus
				,	case
						when coalesce(pv.outside_process, 'N') = 'Y' then 'Approved'
						when coalesce(p.quality_alert, 'N') = 'Y' then 'On Hold'
						else 'Approved'
					end
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
	if	@RowCount != @NewObjects begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NewObjects)
		rollback tran @ProcName
		return @Result
	end
	--- </Insert>

	set	@SerialNumber = @NewSerial
end

/*	Record part on hand. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_UpdatePartOnHand'
execute
	@ProcReturn = dbo.usp_InventoryControl_UpdatePartOnHand
	@PartCode = @PartCode
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
if	@ProcResult not in (0, 100) begin
	set	@Result = 900502
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
	@ProcReturn int
,	@TranDT datetime
,	@ProcResult int
,	@Error int

execute
	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObject_Inventory
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
