CREATE TABLE [dbo].[Notification_POEmailProfile]
(
[PONumber] [int] NULL,
[ProfileID] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Notificat__Statu__1CE7F9F6] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Notificati__Type__1DDC1E2F] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowCr__1ED04268] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowCr__1FC466A1] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowMo__20B88ADA] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowMo__21ACAF13] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_POEmailProfile] ADD CONSTRAINT [PK__Notifica__FFEE7451126A6B83] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_POEmailProfile] ADD CONSTRAINT [UQ__Notifica__3B2960C91546D82E] UNIQUE NONCLUSTERED  ([PONumber], [ProfileID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_POEmailProfile] ADD CONSTRAINT [FK__Notificat__PONum__2859ACA2] FOREIGN KEY ([PONumber]) REFERENCES [dbo].[po_header] ([po_number])
GO
ALTER TABLE [dbo].[Notification_POEmailProfile] ADD CONSTRAINT [FK__Notificat__Profi__294DD0DB] FOREIGN KEY ([ProfileID]) REFERENCES [dbo].[Notification_EmailProfiles] ([RowID])
GO
