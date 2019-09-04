CREATE TABLE [EDI].[FTPLogDetails]
(
[FLHRowID] [int] NOT NULL,
[Line] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__FTPLogDet__Statu__787EE5A0] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__FTPLogDeta__Type__797309D9] DEFAULT ((0)),
[Command] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommandOutput] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__FTPLogDet__RowCr__7A672E12] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FTPLogDet__RowCr__7B5B524B] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__FTPLogDet__RowMo__7C4F7684] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FTPLogDet__RowMo__7D439ABD] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[FTPLogDetails] ADD CONSTRAINT [PK__FTPLogDe__FFEE7451D3891B79] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[FTPLogDetails] ADD CONSTRAINT [UQ__FTPLogDe__3D42B08D35442E78] UNIQUE NONCLUSTERED  ([FLHRowID], [Line]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[FTPLogDetails] ADD CONSTRAINT [FK__FTPLogDet__FLHRo__7E37BEF6] FOREIGN KEY ([FLHRowID]) REFERENCES [EDI].[FTPLogHeaders] ([RowID])
GO
