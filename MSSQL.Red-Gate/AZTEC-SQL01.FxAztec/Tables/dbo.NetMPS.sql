CREATE TABLE [dbo].[NetMPS]
(
[Status] [int] NOT NULL CONSTRAINT [DF__NetMPS__Status__111A4D4A] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__NetMPS__Type__120E7183] DEFAULT ((0)),
[OrderNo] [int] NOT NULL CONSTRAINT [DF__NetMPS__OrderNo__130295BC] DEFAULT ((-1)),
[LineID] [int] NOT NULL,
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RequiredDT] [datetime] NOT NULL,
[GrossDemand] [numeric] (30, 12) NOT NULL,
[Balance] [numeric] (30, 12) NOT NULL,
[OnHandQty] [numeric] (30, 12) NOT NULL CONSTRAINT [DF__NetMPS__OnHandQt__13F6B9F5] DEFAULT ((0)),
[InTransitQty] [numeric] (30, 12) NOT NULL CONSTRAINT [DF__NetMPS__InTransi__14EADE2E] DEFAULT ((0)),
[WIPQty] [numeric] (30, 12) NOT NULL CONSTRAINT [DF__NetMPS__WIPQty__15DF0267] DEFAULT ((0)),
[LowLevel] [int] NOT NULL,
[Sequence] [int] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__NetMPS__RowCreat__16D326A0] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__NetMPS__RowCreat__17C74AD9] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__NetMPS__RowModif__18BB6F12] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__NetMPS__RowModif__19AF934B] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[NetMPS] ADD CONSTRAINT [PK__NetMPS__FFEE74514FE9C8F8] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
