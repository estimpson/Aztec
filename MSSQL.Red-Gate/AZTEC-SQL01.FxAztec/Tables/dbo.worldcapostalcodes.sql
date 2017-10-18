CREATE TABLE [dbo].[worldcapostalcodes]
(
[ID] [int] NULL,
[PostalCode] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Province] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProvinceCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CityType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Latitude] [real] NULL,
[Longitude] [real] NULL
) ON [PRIMARY]
GO
