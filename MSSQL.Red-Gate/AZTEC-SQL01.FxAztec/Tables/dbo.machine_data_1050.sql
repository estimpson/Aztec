CREATE TABLE [dbo].[machine_data_1050]
(
[machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_reset] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[downtime] [numeric] (20, 6) NULL,
[cycle] [numeric] (20, 6) NULL,
[counter] [numeric] (20, 6) NULL,
[avg_cycle] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[machine_data_1050] ADD CONSTRAINT [PK__machine___38791ADE65370702] PRIMARY KEY CLUSTERED  ([machine]) ON [PRIMARY]
GO
