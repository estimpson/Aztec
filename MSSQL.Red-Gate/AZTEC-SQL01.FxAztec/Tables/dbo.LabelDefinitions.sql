CREATE TABLE [dbo].[LabelDefinitions]
(
[LabelName] [sys].[sysname] NOT NULL,
[PrinterType] [sys].[sysname] NOT NULL,
[ProcedureName] [sys].[sysname] NOT NULL,
[LabelCode] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LabelDefinitions] ADD CONSTRAINT [PK__LabelDef__1E951820540C7B00] PRIMARY KEY CLUSTERED  ([LabelName], [PrinterType]) ON [PRIMARY]
GO
