CREATE TABLE [dbo].[order_header]
(
[order_no] [numeric] (8, 0) NOT NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[contact] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_year] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_part] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[box_label] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pallet_label] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[standard_pack] [numeric] (20, 6) NULL,
[our_cum] [numeric] (20, 6) NULL,
[the_cum] [numeric] (20, 6) NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [numeric] (20, 6) NULL,
[shipped] [numeric] (20, 6) NULL,
[deposit] [numeric] (20, 6) NULL,
[artificial_cum] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[revision] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_qty] [numeric] (20, 6) NULL,
[price] [numeric] (20, 6) NULL,
[price_unit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesman] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zone_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[term] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dock_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[package_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipping_unit] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_feed_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fab_cum] [numeric] (15, 2) NULL,
[raw_cum] [numeric] (15, 2) NULL,
[fab_date] [datetime] NULL,
[raw_date] [datetime] NULL,
[po_expiry_date] [datetime] NULL,
[begin_kanban_number] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_kanban_number] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line11] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line12] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line13] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line14] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line15] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line16] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line17] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom01] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom02] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom03] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quote] [int] NULL,
[due_date] [datetime] NULL,
[engineering_level] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alternate_price] [decimal] (20, 6) NULL,
[show_euro_amount] [smallint] NULL,
[cs_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__order_hea__order__0C50D423] DEFAULT ('A')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_order_header_i] on [dbo].[order_header] for insert
as
begin
	-- declarations
	declare	@order_no	numeric(8,0),
			@inserted_status varchar(20)

	-- get first updated/inserted row
	select	@order_no = min(order_no)
	from	inserted

	-- loop through all updated records and call procedure to calculate the currency price
	while ( isnull(@order_no,-1) <> -1 )
	begin

		exec msp_calc_order_currency @order_no, null, null, null, null

		select	@inserted_status = isnull(cs_status,'')
		from	inserted
		where	order_no = @order_no

		update 	shipper 
		set		cs_status = @inserted_status
		from 	shipper_detail
		where 	shipper.id = shipper_detail.shipper and
				shipper_detail.order_no = @order_no

		select	@order_no = min(order_no)
		from	inserted
		where	order_no > @order_no

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_order_header_u]
on [dbo].[order_header]
for update
as
-- declarations
declare	@order_no	numeric(8,0),
	@deleted_cu	varchar(3),
	@deleted_ap	numeric(20,6),
	@deleted_status varchar(20),
	@deleted_box_label varchar(25),
	@deleted_pallet_label varchar(25),
	@inserted_cu varchar(3),
	@inserted_ap numeric(20,6),
	@inserted_status varchar(20),
	@inserted_box_label varchar(25),
	@inserted_pallet_label varchar(25),
	@type varchar(1)

-- get first updated/inserted row
select	@order_no = min(order_no)
from	inserted

-- loop through all updated records and call procedure to generate kanban and calculate the currency price.
while ( isnull(@order_no,-1) <> -1 )
begin
	EXECUTE	msp_generate_kanban @order_no

	select	@inserted_cu = currency_unit,
		@inserted_ap = alternate_price,
		@inserted_status = cs_status,
		@inserted_box_label = box_label,
		@inserted_pallet_label = pallet_label,
		@type = order_type
	from	inserted
	where	order_no = @order_no

	select	@deleted_cu = currency_unit,
		@deleted_ap = alternate_price,
		@deleted_status = cs_status,
		@deleted_box_label = box_label,
		@deleted_pallet_label = pallet_label
	from	deleted
	where	order_no = @order_no

	select @inserted_cu = isnull(@inserted_cu,'')
	select @inserted_ap = isnull(@inserted_ap,0)
	select @inserted_status = isnull(@inserted_status,'')
	select @inserted_box_label = isnull ( @inserted_box_label, '' )
	select @inserted_pallet_label = isnull ( @inserted_pallet_label, '' )
	select @deleted_cu = isnull(@deleted_cu,'')
	select @deleted_ap = isnull(@deleted_ap,0)
	select @deleted_status = isnull(@deleted_status,'')
	select @deleted_box_label = isnull ( @deleted_box_label, '' )
	select @deleted_pallet_label = isnull ( @deleted_pallet_label, '' )

	if 	@inserted_cu <> @deleted_cu or
		@inserted_ap <> @deleted_ap
		exec msp_calc_order_currency @order_no, null, null, null, null
/*	else if @inserted_status <> @deleted_status
		update 	shipper 
		set	cs_status = @inserted_status
		from 	shipper_detail
		where 	shipper.id = shipper_detail.shipper and
			shipper_detail.order_no = @order_no
*/
	if	@type = 'B' and
		( @inserted_box_label <> @deleted_box_label or
		@inserted_pallet_label <> @deleted_pallet_label )
		update	order_detail
		set	box_label = @inserted_box_label,
			pallet_label = @inserted_pallet_label
		where	order_no = @order_no
		
	select	@order_no = min(order_no)
	from	inserted
	where	order_no > @order_no

end
GO
ALTER TABLE [dbo].[order_header] ADD CONSTRAINT [PK__order_header__05CF8A74] PRIMARY KEY CLUSTERED  ([order_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [order_header_customer_ix] ON [dbo].[order_header] ([customer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
