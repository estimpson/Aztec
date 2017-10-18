CREATE TABLE [dbo].[TransportDeliveries]
(
[DeliveryNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Transport__Deliv__3085A9A6] DEFAULT ('0'),
[Status] [int] NOT NULL CONSTRAINT [DF__Transport__Statu__3179CDDF] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__TransportD__Type__326DF218] DEFAULT ((0)),
[DeparturePlant] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ArrivalPlant] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Carrier] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransportMode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipperID] [int] NULL,
[ReceiverNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScheduledDepartureDT] [datetime] NULL,
[ScheduledArrivalDT] [datetime] NULL,
[ActualDepartureDT] [datetime] NULL,
[ActualArrivalDT] [datetime] NULL,
[TrackingCodes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Transport__RowCr__391AEFA7] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Transport__RowCr__3A0F13E0] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Transport__RowMo__3B033819] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Transport__RowMo__3BF75C52] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_TransportDeliveries_NumberMask] on [dbo].[TransportDeliveries] after insert
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
/*	Check if any new rows require a new Delivery Number. */
	if	exists
			(	select
					*
				from
					inserted i
				where
					i.DeliveryNumber = '0'
			) begin

/*			Get the number of new delivery numbers needed. */
		declare
			@NumberCount int
	
		select
			@NumberCount = Count(*)
		from
			inserted i
		where
			i.DeliveryNumber = '0'
		
/*			Set the new delivery numbers. */
		--- <Update rows="n">
		set	@TableName = 'dbo.TransportDeliveries'
				
		update
			td
		set
			DeliveryNumber = NewValues.NewValue
		from
			dbo.TransportDeliveries td
			join
			(	select
					i.RowID
				,	i.RowCreateDT
				,	NewValue = FT.udf_NumberFromMaskAndValue
						(	ns.NumberMask
						,	ns.NextValue + row_number() over (order by i.RowID) - 1
						,	i.RowCreateDT
						)
				from
					inserted i
					join FT.NumberSequenceKeys nsk
						join FT.NumberSequence ns with(updlock)
							on ns.NumberSequenceID = nsk.NumberSequenceID
						on nsk.KeyName = 'dbo.TransportDeliveries.DeliveryNumber'
				where
					i.DeliveryNumber = '0'
			) NewValues
				on NewValues.RowID = td.RowID
		
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
			nsk.KeyName = 'dbo.TransportDeliveries.DeliveryNumber'
		
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
	dbo.TransportDeliveries
...

update
	...
from
	dbo.TransportDeliveries
...

delete
	...
from
	dbo.TransportDeliveries
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
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_TransportDeliveries_uRowModified] on [dbo].[TransportDeliveries] after update
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
	--- <Update rows="*">
	set	@TableName = 'dbo.TransportDeliveries'
	
	update
		td
	set	RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.TransportDeliveries td
		join inserted i
			on i.RowID = td.RowID
	
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
	dbo.TransportDeliveries
...

update
	...
from
	dbo.TransportDeliveries
...

delete
	...
from
	dbo.TransportDeliveries
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
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [PK__Transpor__FFEE7451651F91CE] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [UQ_TransportDeliveries_DeliveryNumber] UNIQUE NONCLUSTERED  ([DeliveryNumber]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [FK__Transport__Arriv__34563A8A] FOREIGN KEY ([ArrivalPlant]) REFERENCES [dbo].[destination] ([destination])
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [FK__Transport__Depar__33621651] FOREIGN KEY ([DeparturePlant]) REFERENCES [dbo].[destination] ([destination])
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [FK__Transport__Recei__3826CB6E] FOREIGN KEY ([ReceiverNumber]) REFERENCES [dbo].[ReceiverHeaders] ([ReceiverNumber])
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [FK__Transport__Shipp__3732A735] FOREIGN KEY ([ShipperID]) REFERENCES [dbo].[shipper] ([id])
GO
ALTER TABLE [dbo].[TransportDeliveries] ADD CONSTRAINT [FK__Transport__Trans__363E82FC] FOREIGN KEY ([TransportMode]) REFERENCES [dbo].[trans_mode] ([code])
GO
