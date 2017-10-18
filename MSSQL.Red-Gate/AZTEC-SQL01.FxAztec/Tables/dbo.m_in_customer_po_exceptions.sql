CREATE TABLE [dbo].[m_in_customer_po_exceptions]
(
[logid] [int] NOT NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipto_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_part] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_unit] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [numeric] (20, 6) NOT NULL,
[release_dt_qualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_dt] [datetime] NOT NULL,
[release_type_qualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
