CREATE TABLE [dbo].[unit_conversion]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit1] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit2] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[conversion] [numeric] (20, 14) NOT NULL,
[sequence] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[unit_conversion] ADD CONSTRAINT [PK__unit_conversion__014935CB] PRIMARY KEY CLUSTERED  ([code], [unit1], [unit2]) ON [PRIMARY]
GO
