CREATE TABLE [dbo].[package_materials]
(
[code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[returnable] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight] [numeric] (12, 6) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[package_materials] ADD CONSTRAINT [PK__package_material__71D1E811] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
