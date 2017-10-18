CREATE TABLE [dbo].[RegionsWorld]
(
[CountryCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RegionCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RegionName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[RegionsWorld] ADD CONSTRAINT [PK_RegionsWorld] PRIMARY KEY CLUSTERED  ([CountryCode], [RegionCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RegionsWorld_ix1] ON [dbo].[RegionsWorld] ([CountryCode], [RegionCode], [RegionName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [RegionsWorld_ix2] ON [dbo].[RegionsWorld] ([RegionName], [RegionCode], [CountryCode]) ON [PRIMARY]
GO
