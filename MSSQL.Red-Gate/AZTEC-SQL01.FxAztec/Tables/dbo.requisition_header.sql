CREATE TABLE [dbo].[requisition_header]
(
[requisition_number] [int] NOT NULL,
[vendor_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_destination] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[requested_date] [datetime] NOT NULL,
[requisitioner] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approved] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approver] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[creation_date] [datetime] NOT NULL,
[status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_date] [datetime] NULL,
[freight_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_header] ADD CONSTRAINT [PK__requisit__11429B10408F9238] PRIMARY KEY CLUSTERED  ([requisition_number]) ON [PRIMARY]
GO
