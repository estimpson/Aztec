CREATE TABLE [dbo].[BlanketPriceAdmin]
(
[TableName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AllowUpdate] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BlanketPriceAdmin] ADD CONSTRAINT [PK__BlanketP__733652EF21B6055D] PRIMARY KEY CLUSTERED  ([TableName]) ON [PRIMARY]
GO
