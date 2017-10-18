CREATE TABLE [dbo].[CountriesWorld]
(
[CountryCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CountryName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CountriesWorld] ADD CONSTRAINT [PK__Countrie__5D9B0D2D5DCAEF64] PRIMARY KEY CLUSTERED  ([CountryCode]) ON [PRIMARY]
GO
