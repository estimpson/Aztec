CREATE TABLE [dbo].[MachineState]
(
[MachineCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MachineSt__Statu__116B5A52] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__MachineSta__Type__125F7E8B] DEFAULT ((0)),
[OperatorCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActiveWorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActiveWorkOrderDetailSequence] [int] NULL,
[CurrentToolCode] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CurrentPalletSerial] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MachineSt__RowCr__1353A2C4] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MachineSt__RowCr__1447C6FD] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MachineSt__RowMo__153BEB36] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MachineSt__RowMo__16300F6F] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trMachineState_d] on [dbo].[MachineState] instead of delete
as
/*	Don't allow deletes.  */
update
	ms
set
	Status = dbo.udf_StatusValue('dbo.MachineState', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.MachineState ms
	join deleted d on
		ms.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trMachineState_u] on [dbo].[MachineState] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		ms
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.MachineState ms
		join inserted i on
			ms.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[MachineState] ADD CONSTRAINT [PK__MachineS__FFEE74510CA6A535] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MachineState] ADD CONSTRAINT [UQ__MachineS__DB84B5B80F8311E0] UNIQUE NONCLUSTERED  ([MachineCode]) ON [PRIMARY]
GO
