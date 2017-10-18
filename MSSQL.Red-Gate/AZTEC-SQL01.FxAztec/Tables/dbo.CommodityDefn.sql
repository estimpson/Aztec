CREATE TABLE [dbo].[CommodityDefn]
(
[CommodityID] [int] NOT NULL IDENTITY(1, 1),
[ParentCommodityID] [int] NULL,
[CommodityCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CommodityDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DrAccount] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Virtual] [bit] NOT NULL CONSTRAINT [DF__Commodity__Virtu__148C8229] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CommodityDefn] ADD CONSTRAINT [PK__Commodit__5C5A915A11B0157E] PRIMARY KEY CLUSTERED  ([CommodityID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CommodityDefn] ADD CONSTRAINT [FK__Commodity__Paren__13985DF0] FOREIGN KEY ([ParentCommodityID]) REFERENCES [dbo].[CommodityDefn] ([CommodityID])
GO
