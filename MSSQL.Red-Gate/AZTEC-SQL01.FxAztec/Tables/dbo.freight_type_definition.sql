CREATE TABLE [dbo].[freight_type_definition]
(
[Type_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[freight_type_definition] ADD CONSTRAINT [PK__freight___7C695F6731B762FC] PRIMARY KEY CLUSTERED  ([Type_name]) ON [PRIMARY]
GO
