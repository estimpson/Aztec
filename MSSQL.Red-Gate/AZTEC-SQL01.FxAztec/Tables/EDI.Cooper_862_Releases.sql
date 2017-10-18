CREATE TABLE [EDI].[Cooper_862_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Cooper_86__Statu__4204700C] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Cooper_862__Type__42F89445] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Cooper_86__RowCr__43ECB87E] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_86__RowCr__44E0DCB7] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Cooper_86__RowMo__45D500F0] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_86__RowMo__46C92529] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Cooper_862_Releases] ADD CONSTRAINT [PK__Cooper_8__FFEE7451401C279A] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
