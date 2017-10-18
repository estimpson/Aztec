CREATE TABLE [dbo].[activity_codes]
(
[code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value_add_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[industry] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[budget] [numeric] (20, 6) NULL,
[actual] [numeric] (20, 6) NULL,
[qty] [numeric] (20, 6) NULL,
[flow_route_window] [varchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[generate_mps_records] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[mtr_activity_code_d] on [dbo].[activity_codes]
for delete
as
begin

	declare  @activity varchar (15), 
		 @count integer

	select @activity = code
	from  deleted

	select @count = count(1) 
	from activity_router
	where code = @activity

	if isnull ( @count, -1 ) <= 0 
	begin
		select @count = count(1)
		from part_machine
		where activity = @activity 

		if isnull ( @count, 0) > 0 
			RAISERROR ('You cannot delete this activity as it is used elsewhere in the system! ', 16, 1)

	end
	else
		RAISERROR ('You cannot delete this activity as it is used elsewhere in the system! ', 16, 1 )
	
end
GO
ALTER TABLE [dbo].[activity_codes] ADD CONSTRAINT [PK__activity_codes__07020F21] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
