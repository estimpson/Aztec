CREATE TABLE [dbo].[term]
(
[description] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[due_day] [int] NULL,
[discount_days] [int] NULL,
[discount_percentage] [numeric] (5, 2) NULL,
[eom_cut_off] [int] NULL
) ON [PRIMARY]
GO
