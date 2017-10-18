CREATE TABLE [dbo].[CityPostalUS]
(
[StateCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[County] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZipCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Latitude] [real] NULL,
[Longitude] [real] NULL,
[ZipCodeType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CityPostalUS] ADD CONSTRAINT [PK_CityPostalUS] PRIMARY KEY CLUSTERED  ([StateCode], [ZipCode], [City]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCountyUS_ix3] ON [dbo].[CityPostalUS] ([City], [ZipCode], [County], [StateCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCountyUS_ix2] ON [dbo].[CityPostalUS] ([StateCode], [County], [City], [ZipCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCountyUS_ix1] ON [dbo].[CityPostalUS] ([StateCode], [County], [ZipCode], [City]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CityPostalCountyUS_ix4] ON [dbo].[CityPostalUS] ([ZipCode], [City], [County], [StateCode]) ON [PRIMARY]
GO
