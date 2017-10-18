CREATE TABLE [dbo].[destination]
(
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [int] NULL,
[salestax_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salestax_rate] [numeric] (7, 4) NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scheduler] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_segment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_euro_amount] [smallint] NULL,
[cs_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom2] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom3] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom4] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom5] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom6] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom7] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom8] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom9] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom10] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_destination_u] on [dbo].[destination] for update
as
begin
	-- declarations
	declare @destination varchar(20),
			@cs_status varchar(20),
			@deleted_status varchar(20)

	-- get first updated row
	select	@destination = min(destination)
	from 	inserted

	-- loop through all updated records and if cs_status has been modified, update 
	-- orders with new status
	while(isnull(@destination,'-1') <> '-1')
	begin

		select	@cs_status = cs_status
		from	inserted
		where	destination = @destination

		select	@deleted_status = cs_status
		from	deleted
		where	destination = @destination

		select @cs_status = isnull(@cs_status,'')
		select @deleted_status = isnull(@deleted_status,'')

		if @cs_status <> @deleted_status
			update 	order_header
			set		cs_status = @cs_status
			where 	destination = @destination

		select	@destination = min(destination)
		from 	inserted
		where	destination > @destination

	end
end
GO
ALTER TABLE [dbo].[destination] ADD CONSTRAINT [PK__destination__3D5E1FD2] PRIMARY KEY CLUSTERED  ([destination]) ON [PRIMARY]
GO
