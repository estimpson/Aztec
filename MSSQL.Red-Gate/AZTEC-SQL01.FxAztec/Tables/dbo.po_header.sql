CREATE TABLE [dbo].[po_header]
(
[po_number] [int] NOT NULL,
[vendor_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_date] [datetime] NULL,
[date_due] [datetime] NULL,
[terms] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_destination] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_amount] [numeric] (20, 6) NULL,
[shipping_fee] [numeric] (20, 6) NULL,
[sales_tax] [numeric] (20, 6) NULL,
[blanket_orderded_qty] [numeric] (20, 6) NULL,
[blanket_frequency] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_duration] [numeric] (5, 0) NULL,
[blanket_qty_per_release] [numeric] (20, 6) NULL,
[blanket_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_vendor_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [numeric] (20, 6) NULL,
[std_unit] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [int] NULL,
[release_no] [int] NULL,
[release_control] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_rate] [numeric] (4, 2) NULL,
[scheduled_time] [datetime] NULL,
[trusted] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_euro_amount] [smallint] NULL,
[next_seqno] [int] NULL,
[CUSTOM_BestPO] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierShipFrom] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_po_header_u] on [dbo].[po_header] for update
as
begin
	-- declarations
	declare	@po_number		integer,
		@deleted_cu		varchar(3),
		@inserted_cu		varchar(3),
		@vendor_old		varchar(10),
		@vendor_new		varchar(10)

	-- get first updated row
	select	@po_number = min(po_number)
	from 	inserted


	-- loop through all updated records
	while ( isnull(@po_number,-1) <> -1 )
	begin

		select	@deleted_cu = currency_unit,
			@vendor_old = vendor_code
		from	deleted
		where	po_number = @po_number

		select	@inserted_cu = currency_unit,
			@vendor_new = vendor_code
		from	inserted
		where	po_number = @po_number

		select @deleted_cu = isnull(@deleted_cu,'')
		select @inserted_cu = isnull(@inserted_cu,'')

		if @deleted_cu <> @inserted_cu
			exec msp_calc_po_currency @po_number, null, null, null, null, null, null

		-- included this block to check if user changed vendor code and update necessary tables 
		if @vendor_old <> @vendor_new
		begin
			update po_detail
			set vendor_code = @vendor_new
			where po_number = @po_number

			update requisition_detail
			set vendor_code = @vendor_new,
		        status = 'Modified',	
		        status_notes = 'Modified Vendor Code from ' + @vendor_old  + ' to different Vendor: ' + @vendor_new + ' on ' + convert ( varchar (20), getdate( ) )
			where po_number = @po_number 

			update requisition_header
			set status = '8',
		 	status_notes = 'Modified Vendor Code on detail item on : '  + convert ( varchar (20), getdate( ) )
			where requisition_number in (	select distinct (requisition_id)
							from po_detail
							where po_detail.po_number = @po_number )	
		end

		select	@po_number = min(po_number)
		from 	inserted
		where	po_number > @po_number

	end

end
GO
ALTER TABLE [dbo].[po_header] ADD CONSTRAINT [PK__po_header__2414E5C9] PRIMARY KEY CLUSTERED  ([po_number]) ON [PRIMARY]
GO
