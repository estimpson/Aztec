CREATE TABLE [dbo].[Notification_VendorEmailProfile]
(
[VendorCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProfileID] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Notificat__Statu__22A0D34C] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Notificati__Type__2394F785] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowCr__24891BBE] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowCr__257D3FF7] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Notificat__RowMo__26716430] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Notificat__RowMo__27658869] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_VendorEmailProfile] ADD CONSTRAINT [PK__Notifica__FFEE74510BBD6DF4] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_VendorEmailProfile] ADD CONSTRAINT [UQ__Notifica__425147D40E99DA9F] UNIQUE NONCLUSTERED  ([VendorCode], [ProfileID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Notification_VendorEmailProfile] ADD CONSTRAINT [FK__Notificat__Profi__2A41F514] FOREIGN KEY ([ProfileID]) REFERENCES [dbo].[Notification_EmailProfiles] ([RowID])
GO
ALTER TABLE [dbo].[Notification_VendorEmailProfile] ADD CONSTRAINT [FK__Notificat__Vendo__2B36194D] FOREIGN KEY ([VendorCode]) REFERENCES [dbo].[vendor] ([code])
GO
