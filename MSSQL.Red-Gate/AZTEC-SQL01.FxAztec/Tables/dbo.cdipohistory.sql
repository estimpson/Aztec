CREATE TABLE [dbo].[cdipohistory]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[po_number] [int] NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_due] [datetime] NULL,
[type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_recvd_date] [datetime] NULL,
[last_recvd_amount] [decimal] (20, 6) NULL,
[quantity] [decimal] (20, 6) NULL,
[received] [decimal] (20, 6) NULL,
[balance] [decimal] (20, 6) NULL,
[price] [decimal] (20, 6) NULL,
[row_id] [int] NULL,
[release_no] [int] NULL,
[raccuracy] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cdipohist__raccu__36B12243] DEFAULT ('A'),
[premium_freight] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cdipohist__premi__37A5467C] DEFAULT ('N'),
[premium_amount] [decimal] (20, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cdipohistory] ADD CONSTRAINT [PK__cdipohis__3213E83F34C8D9D1] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
