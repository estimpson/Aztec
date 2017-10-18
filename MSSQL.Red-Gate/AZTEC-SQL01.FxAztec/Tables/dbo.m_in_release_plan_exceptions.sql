CREATE TABLE [dbo].[m_in_release_plan_exceptions]
(
[logid] [int] NOT NULL,
[customer_part] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shipto_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_year] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity_qualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [numeric] (20, 6) NOT NULL,
[release_dt_qualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_dt] [datetime] NOT NULL
) ON [PRIMARY]
GO
