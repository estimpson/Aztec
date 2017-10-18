CREATE TABLE [dbo].[exp_apdata_header]
(
[sequence_num] [int] NULL,
[status_code] [int] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [int] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied_j] [int] NULL,
[date_doc_j] [int] NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied_d] [datetime] NULL,
[date_doc_d] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[exp_apdata_header] ADD CONSTRAINT [PK__exp_apda__47D915EF2BFE89A6] PRIMARY KEY CLUSTERED  ([trx_ctrl_num], [batch_code]) ON [PRIMARY]
GO
