CREATE TABLE [dbo].[Notification_EmailProfiles]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Notificat__Statu__172F20A0] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Notificati__Type__182344D9] DEFAULT ((0)),
[EmailTo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailCC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailReplyTo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailSubject] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailBody] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailAttachmentNames] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailFrom] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowCr__19176912] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowCr__1A0B8D4B] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowMo__1AFFB184] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowMo__1BF3D5BD] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_EmailProfiles] ADD CONSTRAINT [PK__Notifica__FFEE745107ECDD10] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
