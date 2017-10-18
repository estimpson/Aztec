CREATE TABLE [dbo].[RegionsMX]
(
[RegionCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RegionCodeISO] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Region] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[RegionsMX] ADD CONSTRAINT [PK_RegionsMX] PRIMARY KEY CLUSTERED  ([RegionCode]) ON [PRIMARY]
GO
