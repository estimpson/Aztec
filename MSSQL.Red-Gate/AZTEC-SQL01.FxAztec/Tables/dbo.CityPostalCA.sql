CREATE TABLE [dbo].[CityPostalCA]
(
[ProvinceCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PostalCode] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Latitude] [real] NULL,
[Longitude] [real] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CityPostalCA] ADD CONSTRAINT [PK__CityPost__5D5A23C9262816C4] PRIMARY KEY CLUSTERED  ([ProvinceCode], [PostalCode], [City]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCA_ix3] ON [dbo].[CityPostalCA] ([City], [PostalCode], [ProvinceCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCA_ix4] ON [dbo].[CityPostalCA] ([PostalCode], [City], [ProvinceCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCA_ix2] ON [dbo].[CityPostalCA] ([ProvinceCode], [City], [PostalCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCA_ix1] ON [dbo].[CityPostalCA] ([ProvinceCode], [PostalCode], [City]) ON [PRIMARY]
GO
