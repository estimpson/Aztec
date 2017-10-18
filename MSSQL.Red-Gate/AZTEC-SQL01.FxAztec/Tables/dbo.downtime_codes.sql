CREATE TABLE [dbo].[downtime_codes]
(
[dt_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_group] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code_description] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[downtime_codes] ADD CONSTRAINT [PK__downtime__50DF9AD00A9D95DB] PRIMARY KEY CLUSTERED  ([dt_code]) ON [PRIMARY]
GO
