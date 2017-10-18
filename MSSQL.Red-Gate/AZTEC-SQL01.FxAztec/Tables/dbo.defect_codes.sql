CREATE TABLE [dbo].[defect_codes]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_group] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[defect_codes] ADD CONSTRAINT [PK__defect_codes__21EB0F87] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
