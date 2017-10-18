CREATE TABLE [dbo].[custom_pbl_link]
(
[button_text] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[menu_text] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mdi_microhelp] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[open_window] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[command_line] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sql_script] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[button_pic] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[custom_pbl_link] ADD CONSTRAINT [PK__custom_p__44C3FE996C190EBB] PRIMARY KEY CLUSTERED  ([module]) ON [PRIMARY]
GO
