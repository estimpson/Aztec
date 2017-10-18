SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[usp_ReceivingDock_ReceiveRMAObjects]
	@User varchar(5)
,	@RMA_ID int
,	@RMA_LineID int
,	@RMA_Reason varchar(254)
,	@PartCode varchar(25)
,	@PackageType varchar(20)
,	@PerBoxQty numeric(20,6)
,	@NewObjects int
,	@Shipper varchar(20)
,	@LotNumber varchar(20)
,	@Location varchar(10)
,	@UserDefinedStatus varchar(30)
,	@SerialNumber int out
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
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Generate inventory. */
/*		Get serial number(s). */
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

select
	Serial = @NewSerial + RowNumber - 1
into
	#NewSerials
from
	dbo.udf_Rows (@NewObjects)

/*		Create objects. */
--- <Insert>
set	@TableName = 'dbo.object'

insert
	object
(	serial, part, lot, location
,	last_date, unit_measure, operator
,	status
,	origin, cost, note
,	name, plant, quantity, last_time
,	package_type, std_quantity
,	custom1, custom2, custom3, custom4, custom5
,	user_defined_status
,	std_cost, field1)
select
	ns.Serial, @PartCode, @LotNumber, l.code
,	@TranDT, sd.alternative_unit, @User
,	uds.type
,	@Shipper, sd.price, @RMA_Reason /*note*/
,	p.name, l.plant, dbo.udf_GetStdQtyFromQty(@PartCode, @PerBoxQty, sd.alternative_unit), @TranDT
,	@PackageType, @PerBoxQty
,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
,	uds.display_name
,	sd.price, null /*field1*/
from
	#NewSerials ns
	join dbo.shipper_detail sd on
		sd.shipper = @RMA_ID
		and sd.suffix = @RMA_LineID
		and sd.part_original = @PartCode
	join dbo.shipper s on
		s.id = @RMA_ID
	join part p on
		p.part = @PartCode
	join part_inventory pi on
		pi.part = @PartCode
	join location l on
		coalesce (@Location, pi.primary_location) = l.code
	join dbo.user_defined_status uds
		on uds.display_name = coalesce (@UserDefinedStatus, 'On Hold')

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
	set	@Result = 900102
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NewObjects)
	rollback tran @ProcName
	return @Result
end
--- </Insert>

/*		Create audit trail. */
--- <Insert>
set	@TableName = 'dbo.audit_trail'

insert
	audit_trail
(	serial, date_stamp, type, part
,	quantity, remarks
,	operator, from_loc, to_loc
,	on_hand, lot
,	weight
,	status
,	shipper, unit, std_quantity, cost
,	custom1, custom2, custom3, custom4, custom5
,	plant, notes, gl_account, package_type
,	release_no, std_cost
,	user_defined_status
,	part_name, tare_weight, field1)
select
	ns.Serial, @TranDT, 'U', @PartCode
,	o.quantity, 'RMA'
,	@User, convert(varchar, s.id), pi.primary_location
,	coalesce(po.on_hand, 0) + ((ns.Serial - @NewSerial + 1) * @PerBoxQty), @LotNumber
,	coalesce (o.weight, pi.unit_weight * @PerBoxQty)
,	o.status
,	@Shipper, o.unit_measure, @PerBoxQty, o.cost
,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
,	l.plant, o.note /*note*/, sd.account_code, @PackageType
,	convert(varchar, sd.release_no), o.std_cost
,	o.user_defined_status
,	o.name, coalesce(o.tare_weight, pm.weight), '' /*field1*/
from
	#NewSerials ns
	left join object o on
		ns.Serial = o.serial
	join dbo.shipper_detail sd on
		sd.shipper = @RMA_ID
		and sd.suffix = @RMA_LineID
		and sd.part_original = @PartCode
	join dbo.shipper s on
		s.id = @RMA_ID
	left join part p on
		p.part = @PartCode
	left join part_inventory pi on
		pi.part = @PartCode
	left join location l on
		pi.primary_location = l.code
	left outer join part_online po on
		po.part = @PartCode
	left join dbo.package_materials pm on
		pm.code = @PackageType
	cross join parameters

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

/*	Update part on hand.*/
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
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

/*	Update RMA Line and RMA Header. */
/*		RMA Line.*/
--- <Update rows="1">
set	@TableName = 'dbo.shipper_detail'

update
	sd
set
	qty_packed = coalesce(sd.qty_packed, 0) - @PerBoxQty * @NewObjects
,	alternative_qty = dbo.udf_GetStdQtyFromQty(@PartCode, coalesce(sd.qty_packed, 0) - @PerBoxQty * @NewObjects, sd.alternative_unit)
from
	dbo.shipper_detail sd
where
	sd.shipper = @RMA_ID
	and sd.suffix = @RMA_LineID
	and sd.part_original = @PartCode

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

/*	RMA Header */
--- <Update rows="*">
set	@TableName = 'dbo.shipper'

update
	s
set
	status =
		case
			when exists
				(	select
						*
					from
						dbo.shipper_detail
					where
						shipper = @RMA_ID
						and abs(qty_packed) < abs(qty_required)
				) then 'O'
			else 'S'
		end
from
	dbo.shipper s
where
	s.id = @RMA_ID

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

set	@SerialNumber = @NewSerial
--- </Body>

if	@TranCount = 0 begin
	commit tran @ProcName
end

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
	@ProcReturn = dbo.usp_ReceivingDock_ReceiveRMAObjects
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
