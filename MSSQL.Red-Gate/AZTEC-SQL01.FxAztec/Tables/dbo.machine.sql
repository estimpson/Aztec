CREATE TABLE [dbo].[machine]
(
[machine_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mach_descp] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cell] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[speed] [numeric] (20, 6) NULL,
[redraw_graph] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_rate] [numeric] (20, 6) NULL,
[standard_rate] [numeric] (20, 6) NULL,
[varying_rate_1] [numeric] (20, 6) NULL,
[varying_rate_2] [numeric] (20, 6) NULL,
[indirect] [numeric] (20, 6) NULL,
[sga] [numeric] (20, 6) NULL,
[qted_rate] [numeric] (20, 6) NULL,
[qted_variable] [numeric] (20, 6) NULL,
[qted_indirect] [numeric] (20, 6) NULL,
[qted_sga] [numeric] (20, 6) NULL,
[plnd_rate] [numeric] (20, 6) NULL,
[plnd_variable] [numeric] (20, 6) NULL,
[plnd_indirect] [numeric] (20, 6) NULL,
[plnd_sga] [numeric] (20, 6) NULL,
[frzn_rate] [numeric] (20, 6) NULL,
[frzn_variable] [numeric] (20, 6) NULL,
[frzn_indirect] [numeric] (20, 6) NULL,
[frzn_sga] [numeric] (20, 6) NULL,
[burden_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_segment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[machine] ADD CONSTRAINT [PK__machine__2A805588] PRIMARY KEY CLUSTERED  ([machine_no]) ON [PRIMARY]
GO
