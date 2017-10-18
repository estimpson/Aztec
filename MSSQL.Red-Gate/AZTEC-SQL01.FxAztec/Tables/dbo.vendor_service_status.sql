CREATE TABLE [dbo].[vendor_service_status]
(
[status_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_value] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vendor_service_status] ADD CONSTRAINT [PK__vendor_service__status] PRIMARY KEY CLUSTERED  ([status_name]) ON [PRIMARY]
GO
