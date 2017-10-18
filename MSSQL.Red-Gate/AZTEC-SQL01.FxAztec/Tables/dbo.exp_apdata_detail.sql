CREATE TABLE [dbo].[exp_apdata_detail]
(
[sequence_num] [int] NULL,
[status_code] [int] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[po_ctrl_num] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_price] [float] NULL,
[amt_freight] [float] NULL,
[amt_tax] [float] NULL,
[amt_misc] [float] NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[exp_apdata_detail] ADD CONSTRAINT [PK__exp_apda__82FD22C4282DF8C2] PRIMARY KEY CLUSTERED  ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
