CREATE TABLE [dbo].[currency_conversion]
(
[currency_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [decimal] (20, 6) NOT NULL,
[effective_date] [datetime] NOT NULL,
[currency_display_symbol] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_currency_conversion_i] on [dbo].[currency_conversion] for insert
as
begin
	-- declarations
	declare	@currency_code	varchar(10),
		@effective_date	datetime,
		@current_date	datetime

	-- declare cursor
	declare updated_rows cursor for
		select	currency_code,
			effective_date
		from	inserted

	-- open and fetch first row of cursor
	open updated_rows
	
	fetch updated_rows into @currency_code, @effective_date
	
	-- loop through records
	while ( @@fetch_status = 0 )
	begin
		select	@current_date = max ( effective_date )
		from	currency_conversion
		where	currency_code = @currency_code and
			effective_date <= GetDate ()
			
		if @effective_date = @current_date
		begin
			if update ( rate ) or update ( effective_date )
			begin
				exec msp_calc_order_currency null, null, null, null, @currency_code
				exec msp_calc_po_currency null, null, null, null, null, null, @currency_code
				exec msp_calc_invoice_currency null, null, null, null, @currency_code
				exec msp_calc_customer_matrix null, null, null, @currency_code
				exec msp_calc_vendor_matrix null, null, null, @currency_code
			end
		end
				
		fetch updated_rows into @currency_code, @effective_date
	end
	
	-- close cursor
	close updated_rows
	deallocate updated_rows
end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_currency_conversion_u] on [dbo].[currency_conversion] for update
as
begin
	-- declarations
	declare	@currency_code	varchar(10),
		@effective_date	datetime,
		@current_date	datetime

	-- declare cursor
	declare updated_rows cursor for
		select	currency_code,
			effective_date
		from	inserted

	-- open and fetch first row of cursor
	open updated_rows
	
	fetch updated_rows into @currency_code, @effective_date
	
	-- loop through records
	while ( @@fetch_status = 0 )
	begin
		select	@current_date = max ( effective_date )
		from	currency_conversion
		where	currency_code = @currency_code and
			effective_date <= GetDate ()
			
		if @effective_date = @current_date
		begin
			if update ( rate ) or update ( effective_date )
			begin
				exec msp_calc_order_currency null, null, null, null, @currency_code
				exec msp_calc_po_currency null, null, null, null, null, null, @currency_code
				exec msp_calc_invoice_currency null, null, null, null, @currency_code
				exec msp_calc_customer_matrix null, null, null, @currency_code
				exec msp_calc_vendor_matrix null, null, null, @currency_code
			end
		end
				
		fetch updated_rows into @currency_code, @effective_date
	end
	
	-- close cursor
	close updated_rows
	deallocate updated_rows
end
GO
ALTER TABLE [dbo].[currency_conversion] ADD CONSTRAINT [PK__currency_convers__220B0B18] PRIMARY KEY CLUSTERED  ([currency_code], [effective_date]) ON [PRIMARY]
GO
