CREATE TABLE [dbo].[BlanketPriceImport]
(
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EffectiveDate] [datetime] NULL,
[BlanketPrice] [numeric] (20, 6) NULL,
[CustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ChangedDate] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__BlanketPr__RowCr__2D27B809] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__BlanketPr__RowCr__2E1BDC42] DEFAULT (suser_name())
) ON [PRIMARY]
GO
