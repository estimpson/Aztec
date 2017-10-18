CREATE TABLE [dbo].[print_queue]
(
[printed] [int] NOT NULL CONSTRAINT [DF__print_que__print__2C4A3917] DEFAULT ((0)),
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[copies] [int] NULL,
[serial_number] [int] NULL,
[label_format] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[server_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entry_id] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__print_que__RowCr__2D3E5D50] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__print_que__RowCr__2E328189] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__print_que__RowMo__2F26A5C2] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__print_que__RowMo__301AC9FB] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[print_queue] ADD CONSTRAINT [PK__print_queue__2B5614DE] PRIMARY KEY CLUSTERED  ([entry_id]) ON [PRIMARY]
GO
