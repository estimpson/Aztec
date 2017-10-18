CREATE TABLE [dbo].[BlanketPriceChangesLog]
(
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PreviousEffectiveDate] [datetime] NULL,
[NewEffectiveDate] [datetime] NULL,
[CurrentBlanketPrice] [numeric] (20, 6) NULL,
[PreviousBlanketPrice] [numeric] (20, 6) NULL,
[NewBlanketPrice] [numeric] (20, 6) NULL,
[CurrentCustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PreviousCustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NewCustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Deleted] [int] NULL CONSTRAINT [DF__BlanketPr__Delet__29572725] DEFAULT ((0)),
[UserCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ChangedDate] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__BlanketPr__RowCr__2A4B4B5E] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__BlanketPr__RowCr__2B3F6F97] DEFAULT (suser_name())
) ON [PRIMARY]
GO
