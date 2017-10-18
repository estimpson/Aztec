CREATE TABLE [EDI].[Staging830_Cumulatives_Dana]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Staging83__Statu__53B90BF3] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Staging830__Type__54AD302C] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipToCode] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyQualifier] [int] NULL,
[CumulativeQty] [int] NULL,
[CumulativeStartDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Staging83__RowCr__55A15465] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Staging83__RowCr__5695789E] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Staging83__RowMo__57899CD7] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Staging83__RowMo__587DC110] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Staging830_Cumulatives_Dana] ADD CONSTRAINT [PK__Staging8__FFEE745151D0C381] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
