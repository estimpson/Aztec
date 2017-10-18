CREATE TABLE [dbo].[worlduszipcodes]
(
[ZipCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Latititude] [real] NULL,
[Longitude] [real] NULL,
[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StateCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[County] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZipCodeType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
