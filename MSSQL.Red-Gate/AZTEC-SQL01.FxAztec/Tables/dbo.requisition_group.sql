CREATE TABLE [dbo].[requisition_group]
(
[group_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_group] ADD CONSTRAINT [PK__requisit__3180DCD0351DDF8C] PRIMARY KEY CLUSTERED  ([group_code]) ON [PRIMARY]
GO
