CREATE TABLE [EDI].[Dana_862_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Dana_862___Statu__34756AC4] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Dana_862_R__Type__35698EFD] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dana_862___RowCr__365DB336] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_862___RowCr__3751D76F] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dana_862___RowMo__3845FBA8] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_862___RowMo__393A1FE1] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Dana_862_Releases] ADD CONSTRAINT [PK__Dana_862__FFEE7451328D2252] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
