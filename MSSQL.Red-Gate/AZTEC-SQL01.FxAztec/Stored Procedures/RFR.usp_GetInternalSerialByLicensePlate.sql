SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [RFR].[usp_GetInternalSerialByLicensePlate]
	@User varchar(5)
,	@LicensePlate varchar(50)
,	@Serial int out
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on

	--- <TIC>
	declare
		@cDebug int = @Debug + 2 -- Proc level

	if	@Debug & 0x01 = 0x01 begin
		declare
			@TicDT datetime = getdate()
		,	@TocDT datetime
		,	@TimeDiff varchar(max)
		,	@TocMsg varchar(max)
		,	@cDebugMsg varchar(max)

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
	end
	--- </TIC>

	--- <SP Begin Logging>
	declare
		@LogID int

	insert
		FXSYS.USP_Calls
	(	USP_Name
	,	BeginDT
	,	InArguments
	)
	select
		USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
	,	BeginDT = getdate()
	,	InArguments =
			'@User = ' + coalesce('''' + @User + '''', 'null')
			+ ', @LicensePlate = ' + coalesce('''' + @LicensePlate + '''', 'null')
			+ ', @TranDT = ' + coalesce(convert(varchar, @TranDT, 121), 'null')
			+ ', @Result = ' + coalesce(convert(varchar, @Result), 'null')
			+ ', @Debug = ' + coalesce(convert(varchar, @Debug), 'null')
			+ ', @DebugMsg = ' + coalesce('''' + @DebugMsg + '''', 'null')

	set	@LogID = scope_identity()
	--- </SP Begin Logging>

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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. RFR.usp_Test
	--- </Error Handling>

	/*	Record initial transaction count. */
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount

	begin try

		---	<ArgumentValidation>

		---	</ArgumentValidation>

		--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
		if	@TranCount = 0 begin
			begin tran @ProcName
		end
		else begin
			save tran @ProcName
		end
		set	@TranDT = coalesce(@TranDT, GetDate())
		--- </Tran>

		--- <Body>
		/*	Split License Plate into Supplier Code and Supplier Serial. */
		set @TocMsg = 'Split License Plate into Supplier Code and Serial'
		declare
			@supplierCode varchar(20)
		,	@supplierSerial varchar(20)

		begin
			declare
				@i_ int = charindex('_', @LicensePlate)

			set	@supplierCode = left(@LicensePlate, @i_ - 1)
			set @supplierSerial = substring(@LicensePlate, @i_ + 1, 50)

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			--- </TOC>
		end

		/*	Lookup License Plate in object table and return if found. */
		set @TocMsg = 'Split License Plate into Supplier Code and Serial'
		if	exists
			(	select
					*
				from
					dbo.object o
				where
					o.SupplierLicensePlate = @LicensePlate
			) begin
			set	@Serial =
				(	select top(1)
						o.serial
					from
						dbo.object o
					where
						o.SupplierLicensePlate = @LicensePlate
					order by
						o.serial desc
				)

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			--- </TOC>

			goto found
		end

		/*	Lookup License Plate in receier object table, validate receiver object, do receipt [if required], return serial. */
		set @TocMsg = 'Lookup License Plate in receier object table, [if required] do receipt, return serial if found'
		if	exists
			(	select
					*
				from
					dbo.ReceiverObjects ro
				where
					ro.SupplierLicensePlate = @LicensePlate
			) begin
			declare
				@boxReceiverObjectID int

			set	@boxReceiverObjectID =
				(	select top(1)
						ro.ReceiverObjectID
					from
						dbo.ReceiverObjects ro
					where
						ro.SupplierLicensePlate = @LicensePlate
					order by
						ro.ReceiverObjectID desc
				)

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			--- </TOC>

			/*	If receiver object is already received, thow error.*/
			if	(	select top(1)
						ro.Status
					from
						dbo.ReceiverObjects ro
					where
						ro.ReceiverObjectID = @boxReceiverObjectID
					order by
						ro.ReceiverObjectID desc
				) != 0 begin
				declare
					@receiverObjectSerial int =
						(	select top(1)
								ro.ReceiverObjectID
							from
								dbo.ReceiverObjects ro
							where
								ro.ReceiverObjectID = @boxReceiverObjectID
							order by
								ro.ReceiverObjectID desc
						)
				RAISERROR ('Error: License plate %s was already received but object serial %d is no longer in inventory.  Invalid label.', 16, 1, @LicensePlate, @receiverObjectSerial)
			end

			/*	Do receipt. */
			set @TocMsg = 'Do receipt'

			--- <Call>	
			set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject'
			
			execute @ProcReturn = dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject
				@User = @User
			,	@ReceiverObjectID = @boxReceiverObjectID
			,	@TranDT = @TranDT output
			,	@Result = @Result output

			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			--- </TOC>
			
			select
				@Serial =
				(	select top(1)
						ro.Serial
					from
						dbo.ReceiverObjects ro
					where
						ro.ReceiverObjectID = @boxReceiverObjectID
					order by
						ro.ReceiverObjectID desc
				)

			goto found
		end

		/*	Handle pallet (TBD)...*/

		/*	Look up License Plate in supplier objects table, find receiver header / create line / object, do receipt, return serial. */
		set @TocMsg = 'Look up License Plate in supplier objects table, find receiver header / create line / object, do receipt, return serial'
		declare
			@partCode varchar(25)
		,	@objectQty numeric(20,6)
		
		select top(1)
			@partCode = sob.InternalPartCode
		,	@objectQty = so.Quantity
		from
			SPORTAL.SupplierObjects so
			join SPORTAL.SupplierObjectBatches sob
				on sob.RowID = so.SupplierObjectBatch
		where
			sob.SupplierCode = @supplierCode
			and so.Serial = @supplierSerial
		order by
			so.RowID desc

		if	@partCode is not null begin
			/*	Check for open requirement. */
			declare
				@poNumber int
			,	@poDueDT datetime

			select top(1)
				@poNumber = pd.po_number
			,	@poDueDT = pd.date_due
			from
				dbo.po_detail pd
					join dbo.po_header ph on
						pd.po_number = ph.po_number
					join dbo.destination d on
						d.destination = @supplierCode
						and d.vendor = pd.vendor_code
			where
				pd.balance > 0
			order by
				pd.date_due asc
			,	pd.po_number desc

			if	@poNumber is null
				or @poDueDT is null begin

				RAISERROR ('Error: License plate %s with part %s has no active requirements.  Fix PO and try again.', 16, 1, @LicensePlate, @partCode)
			end

			/*	Check for open receiver header. */
			declare
				@receiverID int = 
				(	select top(1)
						rh.ReceiverID
					from
						dbo.ReceiverHeaders rh
					where
						rh.ShipFrom = @supplierCode
						and rh.Type in (1, 3) --(1) Purchase Order or (3) Outside Process
						and rh.Status in (0, 1, 2, 3, 4) -- (0) New, (1) Confirmed, (2) Shipped, (3) Arrived, or (4) Received
					order by
						rh.ReceiverID desc
				)

			if	@receiverID is null begin
				RAISERROR ('Error: License plate %s was found but there is not an open receiver for supplier %s.  Open a Receiver in Receiving Dock and try again.', 16, 1, @LicensePlate, @supplierCode)
			end

			/*	Adjust the expected receive date to include the next requirement. */
			--- <Update rows="1">
			set	@TableName = 'dbo.ReceiverHeaders'
				
			update
				rh
			set
				ExpectedReceiveDT =
					case
						when @poDueDT > coalesce(rh.ExpectedReceiveDT, '2001-01-01') then @poDueDT
						else coalesce(rh.ExpectedReceiveDT, @poDueDT)
					end
			from
				dbo.ReceiverHeaders rh
			where
				rh.ReceiverID = @receiverID
				
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
				
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			end
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
			end
			--- </Update>

			/*	Create receiver lines. */
			--- <Call>	
			set	@CallProcName = 'dbo.usp_ReceivingDock_CreateReceiverLines_fromReceiverHeader'
			execute
				@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromReceiverHeader
					@ReceiverID = @receiverID
				,	@Result = @ProcResult out
			
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>

			/*	Find receiver object and set the supplier license plate. */
			declare
				@newReceiverObjectID int =
				(	select top(1)
						ro.ReceiverObjectID
					from
						dbo.ReceiverObjects ro
						join dbo.ReceiverLines rl
							on rl.ReceiverLineID = ro.ReceiverLineID
					where
						rl.ReceiverID = @receiverID
						and ro.PartCode = @partCode
						and ro.Status = 0
					order by
						rl.POLineDueDate
					,	rl.POLineNo
				)

			if	@newReceiverObjectID is null begin
				declare
					@receiverNumber varchar(50) =
					(	select
							rh.ReceiverNumber
						from
							dbo.ReceiverHeaders rh
						where
							rh.ReceiverID = @receiverID
					)

				RAISERROR ('Error: License plate %s with part %s has no active receiver objects.  Fix receiver %s and try again.', 16, 1, @LicensePlate, @partCode, @receiverNumber)
			end

			--- <Update rows="1">
			set	@TableName = 'dbo.ReceiverObjects'
			
			update
				ro
			set
				ro.SupplierLicensePlate = @LicensePlate
			,	ro.QtyObject = coalesce(@objectQty, ro.QtyObject)
			from
				dbo.ReceiverObjects ro
			where
				ro.ReceiverObjectID = @newReceiverObjectID
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			end
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
			end
			--- </Update>

			/*	Perform receipt. */
			--- <Call>	
			set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject'
			
			execute @ProcReturn = dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject
				@User = @User
			,	@ReceiverObjectID = @newReceiverObjectID
			,	@TranDT = @TranDT output
			,	@Result = @Result output
			
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>
			
			/*	Get serial. */
			select
				@Serial =
				(	select top(1)
						ro.Serial
					from
						dbo.ReceiverObjects ro
					where
						ro.ReceiverObjectID = @newReceiverObjectID
					order by
						ro.ReceiverObjectID desc
				)

			goto found
		end
		--- </Body>

		/*	Object not found, throw error. */
		RAISERROR ('Error: License plate %s not found', 16, 1, @LicensePlate)
		

		found:
		---	<CloseTran AutoCommit=Yes>
		if	@TranCount = 0 begin
			commit tran @ProcName
		end
		---	</CloseTran AutoCommit=Yes>

		--- <SP End Logging>
		update
			uc
		set	EndDT = getdate()
		,	OutArguments = 
				'@Serial = ' + coalesce(convert(varchar, @Serial), 'null')
				+ ', @TranDT = ' + coalesce(convert(varchar, @TranDT, 121), 'null')
				+ ', @Result = ' + coalesce(convert(varchar, @Result), 'null')
		from
			FXSYS.USP_Calls uc
		where
			uc.RowID = @LogID
		--- </SP End Logging>

		--- <TIC/TOC END>
		if	@Debug & 0x3F = 0x01 begin
			set @DebugMsg = @DebugMsg + char(13) + char(10)
			print @DebugMsg
		end
		--- </TIC/TOC END>

		---	<Return>
		set	@Result = 0
		return
			@Result
		--- </Return>
	end try
	begin catch
		declare
			@errorSeverity int
		,	@errorState int
		,	@errorMessage nvarchar(2048)
		,	@xact_state int
	
		select
			@errorSeverity = error_severity()
		,	@errorState = error_state ()
		,	@errorMessage = error_message()
		,	@xact_state = xact_state()

		execute FXSYS.usp_PrintError

		if	@xact_state = -1 begin 
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount = 0 begin
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount > 0 begin
			rollback transaction @ProcName
			execute FXSYS.usp_LogError
		end

		raiserror(@errorMessage, @errorSeverity, @errorState)
	end catch
end

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
	@User varchar(5) = '142'
,	@LicensePlate varchar(50) = 'SX_123'
,	@Serial int
,	@Debug int = 1
,	@DebugMsg varchar(max) = null

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = RFR.usp_GetInternalSerialByLicensePlate
	@User = @User
,	@LicensePlate = @LicensePlate
,	@Serial = @Serial out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Debug = @Debug
,	@DebugMsg = @DebugMsg out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult, @DebugMsg, @Serial
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
