CREATE TABLE [dbo].[region_code]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[region_code] ADD CONSTRAINT [PK__region_code__38D961D7] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
