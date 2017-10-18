CREATE TABLE [dbo].[part_class_definition]
(
[class] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_flag] [binary] (8) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_class_definition] ADD CONSTRAINT [PK__part_cla__71DF78EC1A9EF37A] PRIMARY KEY CLUSTERED  ([class]) ON [PRIMARY]
GO
