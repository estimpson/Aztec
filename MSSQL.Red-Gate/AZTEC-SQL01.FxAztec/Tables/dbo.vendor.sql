CREATE TABLE [dbo].[vendor]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[outside_processor] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ytd_sales] [numeric] (20, 6) NULL,
[balance] [numeric] (20, 6) NULL,
[frieght_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [int] NULL,
[partial_release_update] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trusted] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kanban] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_euro_amount] [smallint] NULL,
[status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[empower_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_vendor_u] on [dbo].[vendor] for update
as
begin
	--	declarations
	declare	@vendor varchar(10),
		@vs_status varchar(20),
		@deleted_status varchar(20)
	--	get first updated row

	select	@vendor=min(code)
	from	inserted

	--	loop through all updated records and if vs_status has been modified, 
	--	update destination with new status
	
	while	(isnull(@vendor,'-1')<>'-1')
	begin
		select	@vs_status=status
		from	inserted
		where	code=@vendor
		select	@deleted_status=status
		from	deleted
		where	code=@vendor
		select	@vs_status=isnull(@vs_status,'')
		select	@deleted_status=isnull(@deleted_status,'')
		if @vs_status<>@deleted_status
			update	destination 
			set	cs_status=@vs_status
			where	vendor=@vendor
		select @vendor=min(code)
		from	inserted
		where	code>@vendor
	end
end
GO
ALTER TABLE [dbo].[vendor] ADD CONSTRAINT [PK__vendor__167AF389] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
