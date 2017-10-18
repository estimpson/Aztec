CREATE TABLE [dbo].[Notification_POLog]
(
[PONumber] [int] NULL,
[EmailTo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailCC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailReplyTo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailSubject] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailBody] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailAttachmentNames] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailFrom] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MailItemID] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowCr__6BF08837] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowCr__6CE4AC70] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowMo__6DD8D0A9] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowMo__6ECCF4E2] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_POLog] ADD CONSTRAINT [PK__Notifica__FFEE74516A083FC5] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
