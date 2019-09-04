CREATE TABLE [EDI].[EDIDocuments]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__RawEDIDocu__GUID__403A8C7D] DEFAULT (newid()),
[Status] [int] NOT NULL CONSTRAINT [DF__RawEDIDoc__Statu__412EB0B6] DEFAULT ((0)),
[FileName] [sys].[sysname] NOT NULL,
[HeaderData] [xml] NULL,
[RowTS] [timestamp] NOT NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__RawEDIDoc__RowCr__4222D4EF] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__RawEDIDoc__RowCr__4316F928] DEFAULT (suser_name()),
[Data] [xml] NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Version] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EDIStandard] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Release] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ControlNumber] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DeliverySchedule] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MessageNumber] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MoparSSDDocument] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VersionEDIFACTorX12] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[EDIDocuments] ADD CONSTRAINT [PK__RawEDIDo__3214EC27E3A649A7] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ixRawEDIDocuments_1] ON [EDI].[EDIDocuments] ([Status], [EDIStandard], [Type]) ON [PRIMARY]
GO
CREATE PRIMARY XML INDEX [PXML_EDIData]
ON [EDI].[EDIDocuments] ([Data])
GO
