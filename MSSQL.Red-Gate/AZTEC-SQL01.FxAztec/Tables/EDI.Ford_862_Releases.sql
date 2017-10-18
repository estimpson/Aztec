CREATE TABLE [EDI].[Ford_862_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Ford_862___Statu__54D74D5E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Ford_862_R__Type__55CB7197] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipToCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNo] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DockCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineFeedCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReserveLineFeedCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseQty] [int] NULL,
[ReleaseDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Ford_862___RowCr__56BF95D0] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_862___RowCr__57B3BA09] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Ford_862___RowMo__58A7DE42] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_862___RowMo__599C027B] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Ford_862_Releases] ADD CONSTRAINT [PK__Ford_862__FFEE745152EF04EC] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
