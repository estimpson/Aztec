CREATE TABLE [dbo].[CustomerEDI_GenerationLog_Responses]
(
[FileStreamID] [uniqueidentifier] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__CustomerE__Statu__297CB217] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__CustomerED__Type__2A70D650] DEFAULT ((0)),
[ParentFileStreamID] [uniqueidentifier] NULL,
[ParentGenerationLogRowID] [int] NULL,
[MessageInfo] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserNotes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CustomerE__UserN__2B64FA89] DEFAULT (suser_name()),
[ExceptionHandler] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__CustomerE__RowCr__2C591EC2] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CustomerE__RowCr__2D4D42FB] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__CustomerE__RowMo__2E416734] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CustomerE__RowMo__2F358B6D] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[CustomerEDI_GenerationLog_Responses] ADD CONSTRAINT [PK__Customer__FFEE7451A11984BC] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CustomerEDI_GenerationLog_Responses] ADD CONSTRAINT [UQ__Customer__2957490CDB93E559] UNIQUE NONCLUSTERED  ([FileStreamID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CustomerEDI_GenerationLog_Responses] ADD CONSTRAINT [FK__CustomerE__Paren__22109A79] FOREIGN KEY ([ParentFileStreamID]) REFERENCES [dbo].[CustomerEDI_GenerationLog] ([FileStreamID])
GO
ALTER TABLE [dbo].[CustomerEDI_GenerationLog_Responses] ADD CONSTRAINT [FK__CustomerE__Paren__2304BEB2] FOREIGN KEY ([ParentGenerationLogRowID]) REFERENCES [dbo].[CustomerEDI_GenerationLog] ([RowID])
GO
