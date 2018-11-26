SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [RFR].[usp_GetObjectBySerial]
	@User varchar(5)
,	@LookupSerial int
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
			+ ', @LookupSerial = ' + coalesce(convert(varchar, @LookupSerial), 'null')
			+ ', @TranDT = ' + coalesce(convert(varchar, @TranDT, 121), '<null>')
			+ ', @Result = ' + coalesce(convert(varchar, @Result), '<null>')
			+ ', @Debug = ' + coalesce(convert(varchar, @Debug), '<null>')
			+ ', @DebugMsg = ' + coalesce('''' + @DebugMsg + '''', '<null>')

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
		/*	Lookup serial in object table and return if found. */
		set @TocMsg = 'Lookup serial in object table and return if found'
		if	exists
			(	select
					*
				from
					dbo.object o
				where
					o.serial = @LookupSerial
			)
		begin
			set @Serial = @LookupSerial

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

		/*	Look up serial in supplier objects table, find receiver header / create line / object, do receipt, return serial. */
		set @TocMsg = 'Look up serial in supplier objects table, find receiver header / create line / object, do receipt, return serial'
		declare
			@partCode varchar(25)
		,	@supplierCode varchar(10)
		,	@objectQty numeric(20,6)
		
		select top(1)
			@partCode = sob.InternalPartCode
		,	@supplierCode = sob.SupplierCode
		,	@objectQty = so.Quantity
		from
			SPORTAL.SupplierObjects so
			join SPORTAL.SupplierObjectBatches sob
				on sob.RowID = so.SupplierObjectBatch
		where
			so.Serial = @LookupSerial
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

				RAISERROR ('Error: Serial %d with part %s has no active requirements.  Fix PO and try again.', 16, 1, @LookupSerial, @partCode)
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
				RAISERROR ('Error: Serial %d was found in supplier objects but there is not an open receiver for supplier %s.  Open a Receiver in Receiving Dock and try again.', 16, 1, @LookupSerial, @supplierCode)
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

				RAISERROR ('Error: Serial %d with part %s has no active receiver objects.  Fix receiver %s and try again.', 16, 1, @LookupSerial, @partCode, @receiverNumber)
			end

			--- <Update rows="1">
			declare
				@licensePlate varchar(50) = @supplierCode + '_' + right('000000000000' + convert(varchar(12), @LookupSerial), 12)

			set	@TableName = 'dbo.ReceiverObjects'
			
			update
				ro
			set
				ro.Serial = @LookupSerial
			,	ro.SupplierLicensePlate = @licensePlate
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
		RAISERROR ('Error: Serial %d not found', 16, 1, @LookupSerial)

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
,	@LookupSerial int = 924133
,	@Serial int

begin transaction Test

update
	rh
set
	Status = 0
from
	dbo.ReceiverHeaders rh
where
	rh.ReceiverID = 16004

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = RFR.usp_GetObjectBySerial
	@User = @User
,	@LookupSerial = @LookupSerial
,	@Serial = @Serial out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult, @Serial

select
	*
from
	dbo.ReceiverObjects ro
where
	ro.Serial = @Serial

select
	*
from
	dbo.audit_trail at
where
	at.serial = @Serial
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
