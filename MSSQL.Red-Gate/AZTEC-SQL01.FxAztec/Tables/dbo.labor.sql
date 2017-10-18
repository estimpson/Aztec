CREATE TABLE [dbo].[labor]
(
[id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[standard_rate] [numeric] (20, 6) NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_rate] [numeric] (20, 6) NULL,
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
[gl_segment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[labor] ADD CONSTRAINT [PK__labor__5DCAEF64] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
