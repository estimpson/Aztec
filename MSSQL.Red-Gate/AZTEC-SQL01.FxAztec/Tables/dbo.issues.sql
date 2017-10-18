CREATE TABLE [dbo].[issues]
(
[issue_number] [int] NOT NULL,
[issue] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[solution] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NOT NULL,
[stop_date] [datetime] NULL,
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[priority_level] [smallint] NOT NULL,
[product_line] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[origin_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[origin] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[assigned_to] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[authorized_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[documentation_change] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax_sheet] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[environment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_component] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[issues] ADD CONSTRAINT [PK__issues__29E1370A] PRIMARY KEY CLUSTERED  ([issue_number]) ON [PRIMARY]
GO
