CREATE TABLE [dbo].[down_pointer]
(
[node] [int] NOT NULL,
[time_stamp] [datetime] NOT NULL,
[date_stamp] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[down_pointer] ADD CONSTRAINT [PK__down_pointer__64ACF71D] PRIMARY KEY CLUSTERED  ([node]) ON [PRIMARY]
GO
