CREATE TABLE [dbo].[part_type_definition]
(
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_flag] [binary] (8) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_type_definition] ADD CONSTRAINT [PK__part_typ__E3F8524955BFB948] PRIMARY KEY CLUSTERED  ([type]) ON [PRIMARY]
GO
