CREATE TABLE [dbo].[part_unit_conversion]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_unit_conversion] ADD CONSTRAINT [PK__part_unit_conver__36E62C6D] PRIMARY KEY CLUSTERED  ([part], [code]) ON [PRIMARY]
GO
