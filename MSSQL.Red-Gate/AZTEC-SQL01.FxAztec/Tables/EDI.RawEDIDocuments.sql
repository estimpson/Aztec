CREATE TABLE [EDI].[RawEDIDocuments]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__RawEDIDocu__GUID__09801FC7] DEFAULT (newid()),
[Status] [int] NOT NULL CONSTRAINT [DF__RawEDIDoc__Statu__0A744400] DEFAULT ((0)),
[FileName] [sys].[sysname] NOT NULL,
[Data] [xml] NOT NULL,
[RowTS] [timestamp] NOT NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__RawEDIDoc__RowCr__0B686839] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__RawEDIDoc__RowCr__0C5C8C72] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [EDI].[RawEDIDocuments] ADD CONSTRAINT [PK__RawEDIDo__3214EC270797D755] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
CREATE PRIMARY XML INDEX [idx_xml_RawEDIDocuments_Data]
ON [EDI].[RawEDIDocuments] ([Data])
GO
CREATE XML INDEX [idx_xml_RawEDIDocuments_Data_Path]
ON [EDI].[RawEDIDocuments] ([Data])
USING XML INDEX [idx_xml_RawEDIDocuments_Data]
FOR PATH
GO
CREATE XML INDEX [idx_xml_RawEDIDocuments_Data_Property]
ON [EDI].[RawEDIDocuments] ([Data])
USING XML INDEX [idx_xml_RawEDIDocuments_Data]
FOR PROPERTY
GO
CREATE XML INDEX [idx_xml_RawEDIDocuments_Data_Value]
ON [EDI].[RawEDIDocuments] ([Data])
USING XML INDEX [idx_xml_RawEDIDocuments_Data]
FOR VALUE
GO
