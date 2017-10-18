
/*
Create Procedure.Fx.dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject
end
go

create procedure dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject
	@User varchar (5)
,	@ReceiverObjectID int
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
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

declare
	@PONumber integer,
	@POLineNo integer,
	@PartCode varchar(25),
	@SerialNumber integer

--	Argument Validation:
--		ReceiverObjectID is valid and not received.
if
	(	select
			Status
		from
			dbo.ReceiverObjects ro
		where
			ReceiverObjectID = @ReceiverObjectID) != dbo.udf_StatusValue ('ReceiverObjects', 'Received') begin
	set	@Result = 1000007
	RAISERROR ('Error encountered in %s.  Validation: ReceiverObjectID %d is not yet received.', 16, 1, @ProcName, @ReceiverObjectID)
	rollback tran @ProcName
	return @Result
end

select
	@PONumber = rl.PONumber
,	@POLineNo = rl.POLineNo
,	@PartCode = rl.PartCode
,	@SerialNumber = ro.Serial
from
	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl on ro.ReceiverLineID = rl.ReceiverLineID
	join dbo.ReceiverHeaders rh on rl.ReceiverID = rh.ReceiverID
where
	ro.ReceiverObjectID = @ReceiverObjectID

if
	@@RowCount != 1 begin
	set	@Result = 1000008
	RAISERROR ('Error encountered in %s.  Validation: ReceiverObjectID %d not found or invalid.', 16, 1, @ProcName, @ReceiverObjectID)
	rollback tran @ProcName
	return @Result
end

--- <Call>	
set	@CallProcName = 'dbo.usp_ReceivingDock_UndoReceiveObjects'
execute
	@ProcReturn = dbo.usp_ReceivingDock_UndoReceiveObjects
	@User = @User,
	@PONumber = @PONumber,
	@POLineNo = @POLineNo,
	@PartCode = @PartCode,
	@SerialNumber = @SerialNumber,
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

--		D.	Update ReceiverObjects.
--- <Update>
set	@TableName = 'dbo.ReceiverObjects'

update
	dbo.ReceiverObjects
set
	Status = dbo.udf_StatusValue ('ReceiverObjects', 'New'),
	Serial = null,
	ReceiveDT = null
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

--		E.	Update ReceiverLine.
--- <Update>
set	@TableName = 'dbo.ReceiverLines'

update
	dbo.ReceiverLines
set
	Status = dbo.udf_StatusValue ('ReceiverLines', 'New'),
	ReceiptDT = null,
	RemainingBoxes = RemainingBoxes + 1
from
	dbo.ReceiverLines rl
	join dbo.ReceiverObjects ro on
		rl.ReceiverLineID = ro.ReceiverLineID
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

/*	Special processing for Outside Process to undo backflush. */
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

	declare
		@backflushNumber varchar(50)
	
	set	@backflushNumber =
			(	select
					max(bh.BackflushNumber)
				from
					dbo.BackflushHeaders bh
				where
					bh.SerialProduced = @SerialNumber
					and bh.Status = 0 --(select dbo.udf_StatusValue ('dbo.BackflushHeaders', 'New'))
			)
	  
	--- <Call>	
	set	@CallProcName = 'dbo.usp_ReceivingDock_UndoBackflush'
	execute
		@ProcReturn = dbo.usp_ReceivingDock_UndoBackflush
			@Operator = @User
		,	@BackflushNumber = @backflushNumber
		,	@ReceiverObjectID = @ReceiverObjectID
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

/*	If material has been delivered to an outside processor, undo autocreate PO line. */
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
	
	set	@CallProcName = 'dbo.usp_OutsideProcessing_UndoAutocreateFirmPOLineItem'
	execute
		@ProcReturn = dbo.usp_OutsideProcessing_UndoAutocreateFirmPOLineItem
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

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
set	@Result = 0
return @Result

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
	@ProcReturn = dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject
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
go

