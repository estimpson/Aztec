
--exec sp_rename 'dbo.trReceiverHeaders', 'tr_ReceiverHeaders_NumberMask'
--alter table dbo.TransportDeliveries drop constraint FK__Transport__Recei__3826CB6E
--alter table dbo.ReceiverHeaders drop constraint UQ__Receiver__B35701C20662F0A3

alter trigger dbo.tr_ReceiverHeaders_NumberMask on dbo.ReceiverHeaders for insert
as
declare
	@TranDT datetime
,	@Result int

set xact_abort off
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

begin try
	--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount
	set	@TranDT = coalesce(@TranDT, GetDate())
	save tran @ProcName
	--- </Tran>

	---	<ArgumentValidation>

	---	</ArgumentValidation>
	
	--- <Body>
/*	Check if any new rows require a new receiver number. */
	if	exists
			(	select
					*
				from
					inserted i
				where
					i.ReceiverNumber = '0'
			) begin

/*			Get the number of new receiver numbers needed. */
		declare
			@NumberCount int
	
		select
			@NumberCount = Count(*)
		from
			inserted i
		where
			i.ReceiverNumber = '0'
		
/*			Set the new receiver numbers. */
		--- <Update rows="n">
		set	@TableName = 'dbo.ReceiverHeaders'
				
		update
			rh
		set
			ReceiverNumber = NewValues.NewValue
		from
			dbo.ReceiverHeaders rh
			join
			(	select
					i.ReceiverID
				,	i.LastDT
				,	NewValue = FT.udf_NumberFromMaskAndValue
						(	ns.NumberMask
						,	ns.NextValue + row_number() over (order by i.ReceiverID) - 1
						,	i.LastDT
						)
				from
					inserted i
					join FT.NumberSequenceKeys nsk
						join FT.NumberSequence ns with(updlock)
							on ns.NumberSequenceID = nsk.NumberSequenceID
						on nsk.KeyName = 'dbo.ReceiverHeaders.ReceiverNumber'
				where
					i.ReceiverNumber = '0'
			) NewValues
				on NewValues.ReceiverID = rh.ReceiverID
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		if	@RowCount != @NumberCount begin
			set	@Result = 999999
			RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NumberCount)
			rollback tran @ProcName
			return
		end
		--- </Update>
	
/*			Increment the next delivery number. */
		--- <Update rows="1">
		set	@TableName = 'FT.NumberSequence'
		
		update
			ns
		set
			NextValue = ns.NextValue + @NumberCount
		from
			FT.NumberSequenceKeys nsk
			join FT.NumberSequence ns with(updlock)
				on ns.NumberSequenceID = nsk.NumberSequenceID
		where
			nsk.KeyName = 'dbo.ReceiverHeaders.ReceiverNumber'
		
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
	--- </Body>
end try
begin catch
	declare
		@errorName int
	,	@errorSeverity int
	,	@errorState int
	,	@errorLine int
	,	@errorProcedures sysname
	,	@errorMessage nvarchar(2048)
	,	@xact_state int
	
	select
		@errorName = error_number()
	,	@errorSeverity = error_severity()
	,	@errorState = error_state ()
	,	@errorLine = error_line()
	,	@errorProcedures = error_procedure()
	,	@errorMessage = error_message()
	,	@xact_state = xact_state()

	if	xact_state() = -1 begin
		print 'Error number: ' + convert(varchar, @errorName)
		print 'Error severity: ' + convert(varchar, @errorSeverity)
		print 'Error state: ' + convert(varchar, @errorState)
		print 'Error line: ' + convert(varchar, @errorLine)
		print 'Error procedure: ' + @errorProcedures
		print 'Error message: ' + @errorMessage
		print 'xact_state: ' + convert(varchar, @xact_state)
		
		rollback transaction
	end
	else begin
		/*	Capture any errors in SP Logging. */
		rollback tran @ProcName
	end
end catch

---	<Return>
set	@Result = 0
return
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

begin transaction Test
go

insert
	dbo.ReceiverHeaders
...

update
	...
from
	dbo.ReceiverHeaders
...

delete
	...
from
	dbo.ReceiverHeaders
...
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

begin transaction

select top 10
	*
from
	dbo.ReceiverHeaders rh
order by
	rh.ReceiverID desc

insert
	dbo.ReceiverHeaders
(	ReceiverNumber
,	Type
,	Status
,	ShipFrom
,	Plant
,	ExpectedReceiveDT
,	ConfirmedShipDT
,	ConfirmedSID
,	ConfirmedArrivalDT
,	TrackingNumber
,	ActualArrivalDT
,	ReceiveDT
,	PutawayDT
,	Note
,	LastUser
,	LastDT
,	SupplierASNGuid
)
select top 10
	'0'
,	rh.Type
,	rh.Status
,	rh.ShipFrom
,	rh.Plant
,	rh.ExpectedReceiveDT
,	rh.ConfirmedShipDT
,	rh.ConfirmedSID
,	rh.ConfirmedArrivalDT
,	rh.TrackingNumber
,	rh.ActualArrivalDT
,	rh.ReceiveDT
,	rh.PutawayDT
,	rh.Note
,	rh.LastUser
,	rh.LastDT
,	rh.SupplierASNGuid
from
	dbo.ReceiverHeaders rh
order by
	rh.ReceiverID desc

select top 20
	*
from
	dbo.ReceiverHeaders rh
order by
	rh.ReceiverID desc
go

rollback
go
