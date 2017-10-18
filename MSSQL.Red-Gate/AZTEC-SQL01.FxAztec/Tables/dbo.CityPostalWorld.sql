CREATE TABLE [dbo].[CityPostalWorld]
(
[CountryCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RegionCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Latitude] [real] NOT NULL,
[Longitude] [real] NOT NULL,
[Active] [int] NOT NULL CONSTRAINT [DF_CityPostalWorld_Active] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CityPostalWorld] ADD CONSTRAINT [PK__CityPost__4811FB29660D91AF] PRIMARY KEY CLUSTERED  ([CountryCode], [RegionCode], [City], [Latitude], [Longitude]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalWorld_ix2] ON [dbo].[CityPostalWorld] ([City], [RegionCode], [CountryCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalWorld_ix1] ON [dbo].[CityPostalWorld] ([CountryCode], [RegionCode], [City]) ON [PRIMARY]
GO
