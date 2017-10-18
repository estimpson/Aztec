CREATE TABLE [dbo].[requisition_detail]
(
[requisition_number] [int] NOT NULL,
[part_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[deliver_to_operator] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expected_cost] [numeric] (20, 6) NULL,
[quantity] [numeric] (20, 6) NOT NULL,
[date_required] [datetime] NOT NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL,
[po_number] [int] NULL,
[vendor_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[service_flag] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_of_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [decimal] (20, 6) NULL,
[extended_cost] [decimal] (20, 6) NULL,
[status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_rowid] [int] NULL,
[project_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_detail] ADD CONSTRAINT [PK__requisit__77D4C1A5314D4EA8] PRIMARY KEY CLUSTERED  ([requisition_number], [row_id]) ON [PRIMARY]
GO
