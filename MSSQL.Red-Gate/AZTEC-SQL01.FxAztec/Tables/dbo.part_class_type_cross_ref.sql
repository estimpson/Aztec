CREATE TABLE [dbo].[part_class_type_cross_ref]
(
[class] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_class_type_cross_ref] ADD CONSTRAINT [PK__part_cla__FFE0FDC81E6F845E] PRIMARY KEY CLUSTERED  ([class], [type]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_class_type_cross_ref] ADD CONSTRAINT [FK__part_clas__class__7A13BF05] FOREIGN KEY ([class]) REFERENCES [dbo].[part_class_definition] ([class])
GO
ALTER TABLE [dbo].[part_class_type_cross_ref] ADD CONSTRAINT [FK__part_class__type__7B07E33E] FOREIGN KEY ([type]) REFERENCES [dbo].[part_type_definition] ([type])
GO
