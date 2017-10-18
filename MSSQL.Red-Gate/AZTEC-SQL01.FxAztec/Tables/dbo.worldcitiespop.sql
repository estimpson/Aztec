CREATE TABLE [dbo].[worldcitiespop]
(
[Country] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CityName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Region] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Population] [int] NULL,
[Latitude] [real] NULL,
[Longitude] [real] NULL
) ON [PRIMARY]
GO
