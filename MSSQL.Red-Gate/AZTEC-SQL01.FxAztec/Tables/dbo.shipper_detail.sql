CREATE TABLE [dbo].[shipper_detail]
(
[shipper] [int] NOT NULL,
[part] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_required] [numeric] (20, 6) NULL,
[qty_packed] [numeric] (20, 6) NULL,
[qty_original] [numeric] (20, 6) NULL,
[accum_shipped] [numeric] (20, 6) NULL,
[order_no] [numeric] (8, 0) NULL,
[customer_po] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [numeric] (20, 6) NULL,
[account_code] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesman] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tare_weight] [numeric] (20, 6) NULL,
[gross_weight] [numeric] (20, 6) NULL,
[net_weight] [numeric] (20, 6) NULL,
[date_shipped] [datetime] NULL,
[assigned] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[packaging_job] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[boxes_staged] [int] NULL,
[pack_line_qty] [numeric] (20, 6) NULL,
[alternative_qty] [numeric] (20, 6) NULL,
[alternative_unit] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[week_no] [int] NULL,
[taxable] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cross_reference] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dropship_po] [int] NULL,
[dropship_po_row_id] [int] NULL,
[dropship_oe_row_id] [int] NULL,
[suffix] [int] NULL,
[part_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_original] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_cost] [numeric] (20, 6) NULL,
[group_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dropship_po_serial] [int] NULL,
[dropship_invoice_serial] [int] NULL,
[stage_using_weight] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alternate_price] [decimal] (20, 6) NULL,
[old_suffix] [int] NULL,
[old_shipper] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_shipper_detail_d] on [dbo].[shipper_detail] for delete
as
begin
	-- declarations
	declare	@shipper		integer,
		@part			varchar(35),
		@suffix			integer,
		@order_number		numeric(8,0),
		@linecount		integer,
		@part_original		varchar(25)

	-- get first updated/deleted row
	select	@shipper = min(shipper)
	from 	deleted
	
	-- loop through all updated records
	while ( isnull(@shipper,-1) <> -1 )
	begin

		-- Get the number line items on shipper.
		select	@linecount = count ( 1 )
		  from	shipper_detail
		 where	shipper = @shipper
		 
		-- If shipper is now empty, mark it as empty.
		if @linecount = 0
			update	shipper
			   set	status = 'E'
			 where	id = @shipper
	
		select	@part = min(part)
		from 	deleted
		where	shipper = @shipper

		while ( isnull(@part,'') <> '' )
		begin

			select	@suffix = suffix,
				@order_number = order_no,
				@part_original = part_original
			from	deleted
			where	shipper = @shipper and
				part = @part
				
			if isnull ( @order_number, 0 ) > 0
				exec msp_calculate_committed_qty @order_number, @part_original, @suffix
					
			select	@part = min(part)
			from 	deleted
			where	shipper = @shipper and
				part > @part

		end

		select	@shipper = min(shipper)
		from 	deleted
		where	shipper > @shipper

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_shipper_detail_i] on [dbo].[shipper_detail] for insert
as
begin
	-- declarations
	declare	@shipper		integer,
		@part			varchar(35),
		@suffix			integer,
		@order_number		numeric(8,0),
		@part_original		varchar(25)

	-- get first updated/inserted row
	select	@shipper = min(shipper)
	from 	inserted

	-- loop through all updated records
	while ( isnull(@shipper,-1) <> -1 )
	begin

		select	@part = min(part)
		from 	inserted
		where	shipper = @shipper

		while ( isnull(@part,'') <> '' )
		begin

			exec msp_calc_invoice_currency @shipper, null, null, @part, null
	
			select	@part_original = part_original,
				@suffix = suffix,
				@order_number = order_no
			from	inserted
			where	shipper = @shipper and
				part = @part
				
			if isnull ( @order_number, 0 ) > 0
				exec msp_calculate_committed_qty @order_number, @part_original, @suffix
					
			select	@part = min(part)
			from 	inserted
			where	shipper = @shipper and
				part > @part

		end

		select	@shipper = min(shipper)
		from 	inserted
		where	shipper > @shipper

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_shipper_detail_u] on [dbo].[shipper_detail] for update
as
begin
	-- declarations
	declare	@shipper		integer,
		@part			varchar(35),
		@inserted_ap		numeric(20,6),
		@inserted_qty_required	numeric(20,6),
		@deleted_ap		numeric(20,6),
		@deleted_qty_required	numeric(20,6),
		@order_number		numeric(8,0),
		@suffix			integer,
		@shipper_status		varchar(1),
		@part_original		varchar(25)

	-- get first updated/inserted row
	select	@shipper = min(shipper)
	from 	inserted

	-- loop through all updated records
	while ( isnull(@shipper,-1) <> -1 )
	begin

		select	@part = min(part)
		from 	inserted
		where	shipper = @shipper

		while ( isnull(@part,'') <> '' )
		begin

			select	@deleted_ap = alternate_price,
				@deleted_qty_required = qty_required
			from	deleted
			where	shipper = @shipper and
				part = @part

			select @deleted_ap = isnull(@deleted_ap,-1)

			select	@inserted_ap = alternate_price,
				@inserted_qty_required = qty_required,
				@order_number = order_no,
				@suffix = suffix,
				@part_original = part_original
			from	inserted
			where	shipper = @shipper and
				part = @part

			select @inserted_ap = isnull(@inserted_ap,-1)

			if @deleted_ap <> @inserted_ap
				exec msp_calc_invoice_currency @shipper, null, null, @part, null
	
			select	@shipper_status = status
			from	shipper
			where	id = @shipper
			
			if isnull ( @order_number, 0 ) > 0
				if isnull ( @deleted_qty_required, 0 ) <> isnull ( @inserted_qty_required, 0 )
					exec msp_calculate_committed_qty @order_number, @part_original, @suffix
				
			select	@part = min(part)
			from 	inserted
			where	shipper = @shipper and
				part > @part

		end

		select	@shipper = min(shipper)
		from 	inserted
		where	shipper > @shipper

	end

end
GO
ALTER TABLE [dbo].[shipper_detail] ADD CONSTRAINT [PK__shipper_detail__6E8B6712] PRIMARY KEY CLUSTERED  ([shipper], [part]) ON [PRIMARY]
GO
