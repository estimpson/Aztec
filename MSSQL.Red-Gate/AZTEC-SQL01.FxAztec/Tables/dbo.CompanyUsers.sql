CREATE TABLE [dbo].[CompanyUsers]
(
[CompanyCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserID] [uniqueidentifier] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__CompanyUs__Statu__732795AB] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__CompanyUse__Type__741BB9E4] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__CompanyUs__RowCr__750FDE1D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyUs__RowCr__76040256] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__CompanyUs__RowMo__76F8268F] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyUs__RowMo__77EC4AC8] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyUsers] ADD CONSTRAINT [PK__CompanyU__FFEE74514209018F] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyUsers] ADD CONSTRAINT [UQ__CompanyU__11A0134B1EE579C0] UNIQUE NONCLUSTERED  ([CompanyCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyUsers] ADD CONSTRAINT [FK__CompanyUs__Compa__713F4D39] FOREIGN KEY ([CompanyCode]) REFERENCES [dbo].[Companies] ([CompanyCode])
GO
