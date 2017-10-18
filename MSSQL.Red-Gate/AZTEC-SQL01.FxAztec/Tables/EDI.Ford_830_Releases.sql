CREATE TABLE [EDI].[Ford_830_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Ford_830___Statu__41C478EA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Ford_830_R__Type__42B89D23] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipToCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ICCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNo] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseQty] [int] NULL,
[ReleaseDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Ford_830___RowCr__43ACC15C] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_830___RowCr__44A0E595] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Ford_830___RowMo__459509CE] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_830___RowMo__46892E07] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Ford_830_Releases] ADD CONSTRAINT [PK__Ford_830__FFEE74513FDC3078] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
