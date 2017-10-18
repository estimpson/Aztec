CREATE TABLE [dbo].[CompanyAddresses]
(
[CompanyCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AddressID] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__CompanyAd__Statu__67B5E2FF] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__CompanyAdd__Type__68AA0738] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__CompanyAd__RowCr__699E2B71] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyAd__RowCr__6A924FAA] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__CompanyAd__RowMo__6B8673E3] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyAd__RowMo__6C7A981C] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyAddresses] ADD CONSTRAINT [PK__CompanyA__FFEE74515D750646] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyAddresses] ADD CONSTRAINT [UQ__CompanyA__11A0134BAA46A3B5] UNIQUE NONCLUSTERED  ([CompanyCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyAddresses] ADD CONSTRAINT [FK__CompanyAd__Addre__66C1BEC6] FOREIGN KEY ([AddressID]) REFERENCES [dbo].[AddressBook] ([AddressID])
GO
ALTER TABLE [dbo].[CompanyAddresses] ADD CONSTRAINT [FK__CompanyAd__Compa__65CD9A8D] FOREIGN KEY ([CompanyCode]) REFERENCES [dbo].[Companies] ([CompanyCode])
GO
