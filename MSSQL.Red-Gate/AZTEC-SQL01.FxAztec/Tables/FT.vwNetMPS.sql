CREATE TABLE [FT].[vwNetMPS]
(
[ID] [int] NOT NULL,
[OrderNo] [int] NULL,
[LineID] [int] NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseDT] [datetime] NULL,
[RequiredDT] [datetime] NULL,
[RequiredQty] [numeric] (20, 6) NULL,
[OnHandQty] [numeric] (20, 6) NULL,
[WIPQty] [numeric] (20, 6) NULL,
[GrossQty] [numeric] (20, 6) NULL,
[Sequence] [int] NULL,
[RowNumber] [int] NULL,
[PostRequiredAccum] [numeric] (20, 6) NULL,
[PostOnHandAccum] [numeric] (20, 6) NULL,
[PostWIPAccum] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
