CREATE TABLE [dbo].[kanban]
(
[kanban_number] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [numeric] (8, 0) NOT NULL,
[line11] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line12] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line13] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line14] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line15] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line16] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line17] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[standard_quantity] [numeric] (20, 6) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[kanban] ADD CONSTRAINT [PK__kanban__BAE2C5AC4F47C5E3] PRIMARY KEY CLUSTERED  ([kanban_number], [order_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[kanban] ADD CONSTRAINT [FK__kanban__order_no__745AE5AF] FOREIGN KEY ([order_no]) REFERENCES [dbo].[order_header] ([order_no])
GO
