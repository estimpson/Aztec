CREATE TABLE [dbo].[RegionsCA]
(
[ProvinceCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Province] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[RegionsCA] ADD CONSTRAINT [PK_RegionsCA] PRIMARY KEY CLUSTERED  ([ProvinceCode]) ON [PRIMARY]
GO
