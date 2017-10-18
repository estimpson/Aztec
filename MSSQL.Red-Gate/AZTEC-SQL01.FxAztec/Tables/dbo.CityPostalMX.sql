CREATE TABLE [dbo].[CityPostalMX]
(
[RegionCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PostalCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Latitude] [real] NULL,
[Longitude] [real] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CityPostalMX] ADD CONSTRAINT [PK__CityPost__CEC0F35B1C9EAC8A] PRIMARY KEY CLUSTERED  ([RegionCode], [PostalCode], [City]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalMX_ix3] ON [dbo].[CityPostalMX] ([City], [PostalCode], [RegionCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalMX_ix4] ON [dbo].[CityPostalMX] ([PostalCode], [City], [RegionCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalMX_ix2] ON [dbo].[CityPostalMX] ([RegionCode], [City], [PostalCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalMX_ix1] ON [dbo].[CityPostalMX] ([RegionCode], [PostalCode], [City]) ON [PRIMARY]
GO
