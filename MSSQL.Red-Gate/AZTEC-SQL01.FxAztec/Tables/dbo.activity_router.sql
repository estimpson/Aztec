CREATE TABLE [dbo].[activity_router]
(
[parent_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [numeric] (5, 0) NOT NULL,
[code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_bill] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc1] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc2] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc3] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc4] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [numeric] (20, 6) NULL,
[price] [numeric] (20, 6) NULL,
[cost_price_factor] [numeric] (20, 6) NULL,
[time_stamp] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger
[dbo].[mtr_activity_router_d]
on [dbo].[activity_router] for delete
as
begin
	declare deleted_items cursor for select parent_part,sequence from deleted order by
		parent_part asc,sequence asc
	declare @parent_part varchar(25),
		@sequence numeric(5,0),
		@counter integer
	select @counter=0
	open deleted_items
	fetch deleted_items into @parent_part,@sequence
	while @@fetch_status=0
	begin
		update 	activity_router set
			sequence=sequence-1
		where 	parent_part=@parent_part
			and sequence>=@sequence

		fetch deleted_items into @parent_part,@sequence 
	end
	close deleted_items
	deallocate deleted_items
end
GO
ALTER TABLE [dbo].[activity_router] ADD CONSTRAINT [PK__activity__A72839E907020F21] PRIMARY KEY CLUSTERED  ([parent_part], [sequence]) ON [PRIMARY]
GO
