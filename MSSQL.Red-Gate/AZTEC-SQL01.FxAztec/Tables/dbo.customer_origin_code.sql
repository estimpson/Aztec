CREATE TABLE [dbo].[customer_origin_code]
(
[code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[customer_origin_code] ADD CONSTRAINT [PK__customer_origin___705EA0EB] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
