CREATE TABLE [dbo].[BlanketPriceActivatedLog]
(
[TableAffected] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrderNo] [numeric] (8, 0) NULL,
[TableRowID] [int] NULL,
[Shipper] [int] NULL,
[PreviousBlanketPrice] [numeric] (20, 6) NULL,
[NewBlanketPrice] [numeric] (20, 6) NULL,
[PreviousCustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NewCustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActivatedDate] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__BlanketPr__RowCr__1DE57479] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__BlanketPr__RowCr__1ED998B2] DEFAULT (suser_name())
) ON [PRIMARY]
GO
