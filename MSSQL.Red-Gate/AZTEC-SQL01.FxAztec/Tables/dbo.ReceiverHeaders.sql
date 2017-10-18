CREATE TABLE [dbo].[ReceiverHeaders]
(
[ReceiverID] [int] NOT NULL IDENTITY(1, 1),
[ReceiverNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ReceiverHe__Type__084B3915] DEFAULT ((1)),
[Status] [int] NOT NULL CONSTRAINT [DF__ReceiverH__Statu__093F5D4E] DEFAULT ((0)),
[ShipFrom] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ExpectedReceiveDT] [datetime] NULL,
[ConfirmedShipDT] [datetime] NULL,
[ConfirmedSID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConfirmedArrivalDT] [datetime] NULL,
[TrackingNumber] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActualArrivalDT] [datetime] NULL,
[ReceiveDT] [datetime] NULL,
[PutawayDT] [datetime] NULL,
[Note] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ReceiverH__LastU__0A338187] DEFAULT (suser_sname()),
[LastDT] [datetime] NULL CONSTRAINT [DF__ReceiverH__LastD__0B27A5C0] DEFAULT (getdate()),
[SupplierASNGuid] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trReceiverHeaders] on [dbo].[ReceiverHeaders] for insert
as
set nocount on
set ansi_warnings off
declare
	@Result int

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=No>
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--- <Body>
declare
	@NextNumber varchar(50)

--- <Call>	
set	@CallProcName = 'dbo.ReceiverHeaders.ReceiverNumber'
execute
	@ProcReturn = FT.usp_NextNumberInSequnce
	@KeyName = 'dbo.ReceiverHeaders.ReceiverNumber'
,	@NextNumber = @NextNumber out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return
end
--- </Call>

--- <Update rows="1">
set	@TableName = 'dbo.ReceiverHeaders'

update
	dbo.ReceiverHeaders
set
	ReceiverNumber = @NextNumber
from
	dbo.ReceiverHeaders
	join inserted on
		ReceiverHeaders.ReceiverID = inserted.ReceiverID
where
	Inserted.ReceiverNumber = '0'

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
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>
--- </Body>
GO
ALTER TABLE [dbo].[ReceiverHeaders] ADD CONSTRAINT [PK__Receiver__FEBB5F07038683F8] PRIMARY KEY CLUSTERED  ([ReceiverID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverHeaders] ADD CONSTRAINT [UQ__Receiver__B35701C20662F0A3] UNIQUE NONCLUSTERED  ([ReceiverNumber]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ReceiverHeaders_Status] ON [dbo].[ReceiverHeaders] ([Status]) INCLUDE ([ReceiverID]) ON [PRIMARY]
GO
