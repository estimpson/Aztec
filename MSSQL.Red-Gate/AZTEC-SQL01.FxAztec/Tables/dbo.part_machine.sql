CREATE TABLE [dbo].[part_machine]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[machine] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NULL,
[mfg_lot_size] [numeric] (20, 6) NULL,
[process_id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parts_per_cycle] [numeric] (20, 6) NULL,
[parts_per_hour] [numeric] (20, 6) NULL,
[cycle_unit] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_time] [numeric] (20, 6) NULL,
[overlap_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[overlap_time] [numeric] (6, 2) NULL,
[labor_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[setup_time] [numeric] (20, 6) NULL,
[crew_size] [decimal] (20, 6) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_part_machine_d]
on [dbo].[part_machine] for delete
as
begin
	declare @sequence integer,
		@part varchar(25),
		@machine varchar(15),
		@activity varchar(25)

	declare deleted_recs cursor for
		select	machine,
			part,
			activity,
			sequence
		from deleted

	open deleted_recs
	fetch deleted_recs into @machine, @part, @activity, @sequence
	while ( @@fetch_status = 0 )
	begin
		if @sequence=1
		begin
			select 	@sequence=min(sequence)
			from 	part_machine
			where 	part=@part and 
				machine=@machine and 
				activity=@activity

			if isnull(@sequence,0)>0
				update 	activity_router 
				set	group_location=@machine
			  	where 	part=@part and 
			  		code=@activity
			else
				update 	activity_router 
				set	group_location=''
			  	where 	part=@part and
			  		code=@activity
		end
		fetch deleted_recs into @machine, @part, @activity, @sequence
	end
	close deleted_recs
	deallocate deleted_recs
end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_part_machine_i]
on [dbo].[part_machine] for insert
as
begin
	declare @machine varchar(15),
		@activity varchar(25),
		@part varchar(25),
		@sequence integer
  
	declare new_recs cursor for
	  	select 	machine,
	    		activity,
	    		part,
	    		sequence
		from 	inserted

	open new_recs
	fetch new_recs into @machine,@activity,@part,@sequence
	while ( @@fetch_status = 0 )
	begin
		if @sequence=1
			update	activity_router 
			set	group_location=@machine
			where 	part=@part and 
				code=@activity

		fetch new_recs into @machine,@activity,@part,@sequence
	end
	close new_recs
	deallocate new_recs
end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_part_machine_u]
on [dbo].[part_machine] for update
as
begin
	declare @machine varchar(15),
		@part varchar(25),
		@activity varchar(25),
		@sequence integer

	declare updated_recs cursor for
		select 	machine,
			part,
			activity,
			sequence
		from 	inserted

	open updated_recs
	fetch updated_recs into @machine,@part,@activity,@sequence
	while ( @@fetch_status = 0 )
	begin
		if @sequence=1
			update activity_router set
			group_location=@machine
			where part=@part
			and code=@activity

		fetch updated_recs into @machine,@part,@activity,@sequence
	end
	close updated_recs
	deallocate updated_recs
end
GO
ALTER TABLE [dbo].[part_machine] ADD CONSTRAINT [PK__part_machine__257C74A0] PRIMARY KEY CLUSTERED  ([part], [machine]) ON [PRIMARY]
GO
