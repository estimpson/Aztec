CREATE TABLE [FT].[SecurityAccess]
(
[SecurityID] [uniqueidentifier] NOT NULL,
[ResourceID] [uniqueidentifier] NOT NULL,
[Status] [int] NULL CONSTRAINT [DF__SecurityA__Statu__6DC38C17] DEFAULT ((0)),
[Type] [int] NULL CONSTRAINT [DF__SecurityAc__Type__6EB7B050] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [FT].[SecurityAccess] ADD CONSTRAINT [PK__Security__7B6611443817D8EB] PRIMARY KEY CLUSTERED  ([SecurityID], [ResourceID]) ON [PRIMARY]
GO
