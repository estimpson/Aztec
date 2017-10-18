CREATE TABLE [dbo].[AddressBook]
(
[AddressID] [int] NOT NULL IDENTITY(1, 1),
[Status] [int] NOT NULL CONSTRAINT [DF__AddressBo__Statu__4560CAFB] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__AddressBoo__Type__4654EF34] DEFAULT ((0)),
[StreetAddress] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POBox] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Logistics] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DeliveryLocation] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CityName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StateCode] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PostalCode] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CountryCode] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile5] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Profile6] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__AddressBo__RowCr__4749136D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__AddressBo__RowCr__483D37A6] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__AddressBo__RowMo__49315BDF] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__AddressBo__RowMo__4A258018] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AddressBook] ADD CONSTRAINT [PK__AddressB__091C2A1B56B3BE9A] PRIMARY KEY CLUSTERED  ([AddressID]) ON [PRIMARY]
GO
