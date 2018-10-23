SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[usp_ReceivingDock_ReceiveObject_againstReceiverObject]
	@User varchar (5),
	@ReceiverObjectID int,
	@TranDT datetime out,
	@Result integer out
as
/*
Example:
Initial queries {
}

Test syntax {
declare	@User varchar (5),
	@ReceiverObjectID int,
	@TranDT datetime

set	@User = 'ES'
set	@ReceiverObjectID = 99

begin transaction ReceiveObject

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

execute	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject
	@User = @User,
	@ReceiverObjectID = @ReceiverObjectID,
	@TranDT = @TranDT out,
	@Result = @ProcResult out

set	@Error = @@error

select	@ProcReturn, @ProcResult

select	*
from	dbo.ReceiverObjects ReceiverObjects
	join dbo.object object on object.serial = ReceiverObjects.Serial
where	ReceiverObjects.ReceiverObjectID = @ReceiverObjectID

select	*
from	dbo.ReceiverObjects ReceiverObjects
	join dbo.audit_trail audit_trail on audit_trail.serial = ReceiverObjects.Serial
where	ReceiverObjects.ReceiverObjectID = @ReceiverObjectID
go

rollback
go

}

Results {
See below...
}
*/
set nocount on
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

--	Argument Validation:
--		ReceiverObjectID is valid and not received.
if	(	select
			Status
		from
			dbo.ReceiverObjects ro
		where
			ReceiverObjectID = @ReceiverObjectID) != dbo.udf_StatusValue ('ReceiverObjects', 'New') begin
	set	@Result = 1000007
	RAISERROR ('Error encountered in %s.  Validation: ReceiverObjectID %d is already received.', 16, 1, @ProcName, @ReceiverObjectID)
	rollback tran @ProcName
	return @Result
end

declare
	@PONumber integer,
	@PartCode varchar(25),
	@PackageType varchar(20),
	@QtyObject numeric (20,6),
	@NewObjects integer,
	@Shipper varchar (20),
	@LotNumber varchar (20),
	@Location varchar (10),
	@SerialNumber integer
,	@ReceiverNumber varchar(50)
,	@ShipFrom varchar(10)

select
	@PONumber = rl.PONumber
,	@PartCode = rl.PartCode
,	@NewObjects = 1
,	@Shipper = rh.ConfirmedSID
,	@LotNumber = ro.Lot
,	@SerialNumber = ro.Serial
,	@PackageType = ro.PackageType
,	@QtyObject = ro.QtyObject
,	@Location = ro.Location
,	@ReceiverNumber = rh.ReceiverNumber
,	@ShipFrom = rh.ShipFrom
from
	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl on ro.ReceiverLineID = rl.ReceiverLineID
	join dbo.ReceiverHeaders rh on rl.ReceiverID = rh.ReceiverID
where
	ro.ReceiverObjectID = @ReceiverObjectID and
	ro.Status = dbo.udf_StatusValue ('ReceiverObjects', 'New')

if	@@RowCount != 1 begin
	set	@Result = 1000008
	RAISERROR ('Error encountered in %s.  Validation: ReceiverObjectID %d not found or invalid.', 16, 1, @ProcName, @ReceiverObjectID)
	rollback tran @ProcName
	return @Result
end
if	coalesce(@Shipper, '') !> '' begin
	set	@Result = 1000008
	RAISERROR ('Error encountered in %s.  Validation: Vendor ShipperID has not been entered yet.  Update Receiver Header and try again.', 16, 1, @ProcName, @ReceiverObjectID)
	rollback tran @ProcName
	return @Result
end

--- <Body>
/*	Perform receipt. */
--- <Call>	
set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObjects'
execute
	@ProcReturn = dbo.usp_ReceivingDock_ReceiveObjects
	@User = @User,
	@PONumber = @PONumber,
	@PartCode = @PartCode,
	@PackageType = @PackageType,
	@PerBoxQty = @QtyObject,
	@NewObjects = @NewObjects,
	@Shipper = @Shipper,
	@LotNumber = @LotNumber,
	@Location = @Location,
	@SerialNumber = @SerialNumber out,
	@TranDT = @TranDT out,
	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return @Result
end
--- </Call>

/*	Update object with supplier license plate. */
--- <Update rows="0..1">
set	@TableName = 'dbo.object'

update
	o
set
	o.SupplierLicensePlate =
		(	select
				ro.SupplierLicensePlate
			from
				dbo.ReceiverObjects ro
			where
				ro.ReceiverObjectID = @ReceiverObjectID
		)
from
	dbo.object o
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
if	@RowCount > 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 0..1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Update ReceiverObjects. */
--- <Update>
set	@TableName = 'dbo.ReceiverObjects'

update
	dbo.ReceiverObjects
set	Status = dbo.udf_StatusValue ('ReceiverObjects', 'Received'),
	Serial = @SerialNumber,
	ReceiveDT = @TranDT
where
	ReceiverObjectID = @ReceiverObjectID

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

/*	Update ReceiverLine. */
--- <Update>
set	@TableName = 'dbo.ReceiverLines'

update
	dbo.ReceiverLines
set
	Status = case RemainingBoxes when 1 then dbo.udf_StatusValue ('ReceiverLines', 'Received') else rl.Status end,
	ReceiptDT = case RemainingBoxes when 1 then @TranDT else ReceiptDT end,
	RemainingBoxes = RemainingBoxes - 1
from
	dbo.ReceiverLines rl
	join dbo.ReceiverObjects ro on rl.ReceiverLineID = ro.ReceiverLineID
where
	ro.ReceiverObjectID = @ReceiverObjectID

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

/*	Update ReceiverHeader. */
--- <Update>
set	@TableName = 'dbo.ReceiverHeader'

update
	dbo.ReceiverHeaders
set
	Status =
		case
			when coalesce(ReceiverLines.RemainingBoxes, 0) = 0 then dbo.udf_StatusValue ('ReceiverHeaders', 'Received')
			when rh.Status < dbo.udf_StatusValue ('ReceiverHeaders', 'Arrived') then dbo.udf_StatusValue ('ReceiverHeaders', 'Arrived')
			else rh.Status
		end,
	ReceiveDT = case coalesce(ReceiverLines.RemainingBoxes, 0) when 0 then @TranDT else rh.ReceiveDT end
from
	dbo.ReceiverHeaders rh
	join
	(	select
			ReceiverID = rl.ReceiverID
		,	RemainingBoxes = sum(RemainingBoxes)
		from
			dbo.ReceiverLines rl
			join dbo.ReceiverObjects ro on
				rl.ReceiverLineID = ro.ReceiverLineID
		where
			ro.ReceiverObjectID = @ReceiverObjectID
		group by
			rl.ReceiverID) ReceiverLines on
		rh.ReceiverID = ReceiverLines.ReceiverID

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

/*	Special processing for Outside Process. */
if	(	select
			rh.Type
		from
			dbo.ReceiverHeaders rh
			join
			(	select
					ReceiverID = rl.ReceiverID
				,	RemainingBoxes = sum(RemainingBoxes)
				from
					dbo.ReceiverLines rl
					join dbo.ReceiverObjects ro on
						rl.ReceiverLineID = ro.ReceiverLineID
				where
					ro.ReceiverObjectID = @ReceiverObjectID
				group by
					rl.ReceiverID) ReceiverLines on
				rh.ReceiverID = ReceiverLines.ReceiverID
	) = 3 begin -- 'Outside Process'
	
/*	Backflush materials for outside process. */
/*		Create back flush header.  */
	--- <Insert rows="1">
	set	@TableName = 'dbo.BackflushHeaders'
	
	insert
		dbo.BackflushHeaders
	(	TranDT
	,	WorkOrderNumber
	,	WorkOrderDetailLine
	,	MachineCode
	,	PartProduced
	,	SerialProduced
	,	QtyProduced
	)
	select
		@TranDT
	,	WorkOrderNumber = null
	,	WorkOrderDetailLine = null
	,	MachineCode = @ShipFrom
	,	PartCode = @PartCode
	,	SerialProduced = @SerialNumber
	,	QtyProduced = @QtyObject

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

	declare
		@NewBackflushNumber varchar(50)

	set	@NewBackflushNumber =
		(	select
	 			bh.BackflushNumber
	 		from
	 			dbo.BackflushHeaders bh
	 		where
	 			bh.RowID = scope_identity()
		 )
	
	/*	Perform back flush.  */
	--- <Call>	
	set	@CallProcName = 'dbo.usp_ReceivingDock_Backflush'
	
	execute @ProcReturn = dbo.usp_ReceivingDock_Backflush
		@Operator = @User
	,	@BackflushNumber = @NewBackflushNumber
	,	@ReceiverObjectID = @ReceiverObjectID
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

	set @Error = @@Error
	if @ProcResult != 0 
		begin
			set @Result = 999999
			raiserror ('An error result was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
			rollback tran @ProcName
			return	@Result
		end
	if @ProcReturn != 0 
		begin
			set @Result = 999999
			raiserror ('An error was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
			rollback tran @ProcName
			return	@Result
		end
	if @Error != 0 
		begin
			set @Result = 999999
			raiserror ('An error occurred during the execution of the procedure %s', 16, 1, 'ProdControl_BackFlush')
			rollback tran @ProcName
			return	@Result
		end
	--- </Call>
end

/*	If material has been delivered to an outside processor, autocreate PO line. */
if	exists
	(	select
			*
		from
			dbo.ReceiverHeaders rh
				join dbo.ReceiverLines rl
						join dbo.ReceiverObjects ro
							on rl.ReceiverLineID = ro.ReceiverLineID
							and ro.ReceiverObjectID = @ReceiverObjectID
					on rh.ReceiverID = rl.ReceiverID
			join dbo.OutsideProcessing_BlanketPOs opbpo
				on opbpo.InPartCode = ro.PartCode
	) begin
	
	--- <Call>
	declare
		@vendorShipTo varchar(20)
	,	@rawPartCode varchar(25)
	,	@rawPartStandardQty numeric(20,6)
	
	select
		@vendorShipTo = rh.Plant
	,	@rawPartCode = ro.PartCode
	,	@rawPartStandardQty = ro.QtyObject
	from
		dbo.ReceiverHeaders rh
			join dbo.ReceiverLines rl
					join dbo.ReceiverObjects ro
						on rl.ReceiverLineID = ro.ReceiverLineID
						and ro.ReceiverObjectID = @ReceiverObjectID
				on rh.ReceiverID = rl.ReceiverID
		join dbo.OutsideProcessing_BlanketPOs opbpo
			on opbpo.InPartCode = ro.PartCode
	
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
--- </Body>

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
set	@Result = 0
return @Result
GO
