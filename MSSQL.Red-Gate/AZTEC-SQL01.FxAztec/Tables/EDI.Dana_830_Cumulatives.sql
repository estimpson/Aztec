CREATE TABLE [EDI].[Dana_830_Cumulatives]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Dana_830___Statu__4A2FA1B9] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Dana_830_C__Type__4B23C5F2] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipToCode] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyQualifier] [int] NULL,
[CumulativeQty] [int] NULL,
[CumulativeStartDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowCr__4C17EA2B] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowCr__4D0C0E64] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowMo__4E00329D] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowMo__4EF456D6] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Dana_830_Cumulatives] ADD CONSTRAINT [PK__Dana_830__FFEE745148475947] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
