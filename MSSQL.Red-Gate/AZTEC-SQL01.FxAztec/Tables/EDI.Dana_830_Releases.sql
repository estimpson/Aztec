CREATE TABLE [EDI].[Dana_830_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Dana_830___Statu__206E7217] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Dana_830_R__Type__21629650] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowCr__2256BA89] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowCr__234ADEC2] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowMo__243F02FB] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowMo__25332734] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Dana_830_Releases] ADD CONSTRAINT [PK__Dana_830__FFEE74511E8629A5] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
