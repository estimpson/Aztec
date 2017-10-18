CREATE TABLE [dbo].[product_line]
(
[id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_segment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[product_line] ADD CONSTRAINT [PK__product_line__239E4DCF] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
