CREATE TABLE [dbo].[TestRawReleases2]
(
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RawDocumentGUID] [uniqueidentifier] NULL,
[TradingPartner] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NULL,
[OrderNo] [int] NULL,
[Type] [tinyint] NULL,
[ReleaseDT] [datetime] NULL,
[BlanketPart] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ModelYear] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrderUnit] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyShipper] [numeric] (20, 6) NULL,
[Line] [int] NULL,
[ReleaseNo] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DockCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineFeedCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReserveLineFeedCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyRelease] [numeric] (20, 6) NULL,
[StdQtyRelease] [numeric] (20, 6) NULL,
[ReferenceAccum] [numeric] (20, 6) NULL,
[RelPrior] [numeric] (20, 6) NULL,
[RelPost] [numeric] (20, 6) NULL,
[NewDocument] [int] NULL
) ON [PRIMARY]
GO
