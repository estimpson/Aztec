CREATE TABLE [dbo].[RegionsUS]
(
[StateCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StateName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Active] [int] NOT NULL CONSTRAINT [DF_RegionsUS_PrimaryRegion] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[RegionsUS] ADD CONSTRAINT [PK_RegionsUS] PRIMARY KEY CLUSTERED  ([StateCode]) ON [PRIMARY]
GO
