CREATE TABLE [dbo].[customer]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address_1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modem] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[profile] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesrep] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_bitmap] [image] NULL,
[bitmap_filename] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [datetime] NULL,
[address_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_euro_amount] [smallint] NULL,
[cs_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom1] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom2] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom3] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom4] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom5] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[origin_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_manager_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[auto_profile] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[check_standard_pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[empower_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_customer_u] on [dbo].[customer] for update
as
begin
	-- declarations
	declare @customer varchar(10),
			@cs_status varchar(20),
			@deleted_status varchar(20)

	-- get first updated row
	select	@customer = min(customer)
	from 	inserted

	-- loop through all updated records and if cs_status has been modified, update 
	-- destination with new status
	while(isnull(@customer,'-1')<>'-1')
	begin

		select	@cs_status = cs_status
		from	inserted
		where	customer = @customer

		select	@deleted_status = cs_status
		from	deleted
		where	customer = @customer

		select @cs_status = isnull(@cs_status,'')
		select @deleted_status = isnull(@deleted_status,'')

		if @cs_status <> @deleted_status
		begin
			update 	destination
			set	cs_status = @cs_status
			where 	customer = @customer

			update 	shipper
			set	cs_status = @cs_status
			where 	customer = @customer
		end 
		select	@customer = min(customer)
		from 	inserted
		where	customer > @customer

	end

end
GO
ALTER TABLE [dbo].[customer] ADD CONSTRAINT [PK__customer__390515B7] PRIMARY KEY CLUSTERED  ([customer]) ON [PRIMARY]
GO
