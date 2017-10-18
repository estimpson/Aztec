CREATE TABLE [dbo].[edi_ff_loops]
(
[transaction_set] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[overlay_group] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line] [int] NOT NULL,
[max_loops] [int] NOT NULL,
[loop_line] [int] NULL,
[line_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loop_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[used] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loop_used] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[edi_ff_loops] ADD CONSTRAINT [PK__edi_ff_l__BE6D7A0B160F4887] PRIMARY KEY CLUSTERED  ([transaction_set], [overlay_group], [line]) ON [PRIMARY]
GO
