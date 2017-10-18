CREATE TABLE [dbo].[order_detail]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [numeric] (8, 0) NOT NULL,
[sequence] [numeric] (5, 0) NOT NULL,
[part_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [numeric] (20, 6) NULL,
[price] [numeric] (20, 6) NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [numeric] (20, 6) NULL,
[invoiced] [numeric] (20, 6) NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[our_cum] [numeric] (20, 6) NULL,
[the_cum] [numeric] (20, 6) NULL,
[due_date] [datetime] NULL,
[destination] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[committed_qty] [numeric] (20, 6) NULL,
[row_id] [int] NULL,
[group_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [numeric] (20, 6) NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [int] NULL,
[week_no] [int] NULL,
[std_qty] [numeric] (20, 6) NULL,
[customer_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dropship_po] [int] NULL,
[dropship_po_row_id] [int] NULL,
[suffix] [int] NULL,
[packline_qty] [numeric] (20, 6) NULL,
[packaging_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weight] [numeric] (20, 6) NULL,
[custom01] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom02] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[custom03] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dimension_qty_string] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[engineering_level] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[box_label] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pallet_label] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alternate_price] [decimal] (20, 6) NULL,
[promise_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_order_detail_d] on [dbo].[order_detail] for delete
as
begin
	-- declarations
	declare	@order_no			numeric(8,0),
		@sequence			numeric(5,0),
		@rowid				integer,
		@part				varchar(25),
		@shiptype			varchar(1),
		@suffix				integer

	-- get first updated/inserted row
	select	@order_no = min(order_no)
	from	deleted

	-- loop through all updated records
	while ( isnull(@order_no,-1) <> -1 )
	begin

		select	@sequence = min(sequence)
		from	deleted
		where	order_no = @order_no

		while ( isnull(@sequence,-1) <> -1 )
		begin

			select	@part = part_number,
				@rowid = row_id,
				@suffix = suffix,
				@shiptype = ship_type
			from	deleted
			where	order_no = @order_no and
				sequence = @sequence

			if isnull(@shiptype,'N') = 'N'
				exec msp_calculate_committed_qty @order_no, @part, @suffix
						
			select	@sequence = min(sequence)
			from	deleted
			where	order_no = @order_no and
				sequence > @sequence

		end

		select	@order_no = min(order_no)
		from	deleted
		where	order_no > @order_no

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_order_detail_i] on [dbo].[order_detail] for insert
as
begin
	-- declarations
	declare	@order_no	numeric(8,0),
		@sequence	numeric(5,0),
		@part		varchar(25),
		@configurable	varchar(1),
		@count		smallint,
		@suffix		integer,
		@type		varchar(1),
		@shiptype	varchar(1),
		@box_label	varchar(25),
		@pallet_label	varchar(25),
		@customer	varchar(10),
		@price_type	char(1)
		
	-- get first updated/inserted row
	select	@order_no = min(order_no)
	from	inserted

	-- loop through all updated records
	while ( isnull(@order_no,-1) <> -1 )
	begin

		select	@sequence = min(sequence)
		from	inserted
		where	order_no = @order_no

		while ( isnull(@sequence,-1) <> -1 )
		begin

			exec msp_calc_order_currency @order_no, null, null, @sequence, null

			-- check if a suffix is needed only for normal orders
			select	@type = order_type,
				@part = blanket_part,
				@box_label = box_label,
				@pallet_label = pallet_label,
				@customer = customer
			from	order_header
			where	order_no = @order_no
			
			select	@shiptype = ship_type
			from	inserted
			where	order_no = @order_no and
				sequence = @sequence
				
			if @type = 'N'
			begin
				-- create suffix if part is configurable
				select	@part = part_number
				from	inserted
				where	order_no = @order_no and
					sequence = @sequence
					
				select	@configurable = configurable
				from	part_inventory
				where	part = @part
	
				if IsNull ( @configurable, 'N' ) = 'Y'
				begin
					select @count = 1
					
					while ( @count > 0 )
					begin
					
						select	@suffix = next_suffix
						from	part_inventory
						where	part = @part
						
						select	@suffix = IsNull ( @suffix, 1 )
						
						update	part_inventory set
							next_suffix = @suffix + 1
						where	part = @part
						
						select	@count = count(suffix)
						from	order_detail
						where	part_number = @part and
							suffix = @suffix
						
						if @count <= 0
							select	@count = count(suffix)
							from	shipper_detail
							where	part = @part and
								suffix = @suffix
								
						if @count <= 0
							select	@count = count(suffix)
							from	object
							where	part = @part and
								suffix = @suffix
								
						if @count <= 0
							update 	order_detail 
							set	suffix = @suffix
							where	order_no = @order_no and
								sequence = @sequence
					end
				end
				else				
					-- create part_customer record if customer_additional.auto_profile is set to 'Y'
					-- and part is not configurable
					if isnull ( ( select isnull ( auto_profile, 'N' ) from customer where customer = @customer ), 'N' ) = 'Y' and
					   not exists ( select 1 from part_customer where customer = @customer and part = @part )
					begin
						if ( select isnull(category,'') from customer where customer = @customer ) > ''
							select @price_type = 'C'
						else
							select @price_type = 'B'
							
						insert into part_customer ( part, customer, customer_part, customer_standard_pack, taxable, customer_unit, type, upc_code, blanket_price )
						select @part, @customer, isnull(customer_part,''), std_qty, null, unit, @price_type, null, null from inserted where order_no = @order_no and sequence = @sequence
					end
			end
			else
				update	order_detail
				set	box_label = @box_label,
					pallet_label = @pallet_label
				where	order_no = @order_no and
					sequence = @sequence
						
			if isnull(@shiptype,'N') = 'N'
				exec msp_calculate_committed_qty @order_no, @part, @suffix
				
			select	@sequence = min(sequence)
			from	inserted
			where	order_no = @order_no and
				sequence > @sequence

		end

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
create trigger [dbo].[mtr_order_detail_u]
on [dbo].[order_detail]
for update
as
---------------------------------------------------------------------------------------
--	This trigger propagates price changes and calls for recalculation of committed
--	quantities for quantity or due date changes.
--
--	Modifications:	?? ??? ????	???			Original
--			26 AUG 1999	Eric E. Stimpson	Modified to loop through modified records.
--			17 NOV 1999	Chris B. Rogers		Changed statement below #7 to use order_no instead of sequence to fix lock up.
--
--	1,	Declarations
--	2.	Loop through all updated records for price changes.
--	3.	Get first order that has a price change.
--	4.	Get first sequence for current order that has a price change.
--	5,	Calculate standard price.
--	6.	Get the next sequence for current order that has a price change.
--	7.	Get the next order that has a price change.
--	8.	Loop through all normal updated records for quantity or due date changes.
--	9.	Get first order that has a quantity or due date change.
--	10.	Get first sequence for current order that has a quantity or due date change.
--	11,	Calculate committed quantity.
--	12.	Get the next sequence for current order that has a quantity or due date change.
--	13.	Get the next order that has a quantity or due date change.
--	14.	Loop through all dropship updated records for quantity or due date changes.
--	15.	Get first order that has a quantity or due date change.
--	16.	Get first sequence for current order that has a quantity or due date change.
--	17,	Calculate committed dropship quantity.
--	18.	Get the next sequence for current order that has a quantity or due date change.
--	19.	Get the next order that has a quantity or due date change.
---------------------------------------------------------------------------------------

--	1,	Declarations
declare	@order_no			numeric(8,0),
	@sequence			numeric(5,0),
	@rowid				integer,
	@part				varchar(25),
	@suffix				integer

--	2.	Loop through all updated records for price changes.
--	3.	Get first order that has a price change.
select	@order_no = min ( deleted.order_no )
from	deleted
	join order_detail on order_detail.order_no = deleted.order_no and
		order_detail.sequence = deleted.sequence
where	IsNull ( order_detail.alternate_price, -1 ) <> IsNull ( deleted.alternate_price, -1 )

while isnull ( @order_no, -1 ) <> -1
begin

--	4.	Get first sequence for current order that has a price change.
	select	@sequence = min ( deleted.sequence )
	from	deleted
		join order_detail on order_detail.order_no = @order_no and
			order_detail.sequence = deleted.sequence
	where	IsNull ( order_detail.alternate_price, -1 ) <> IsNull ( deleted.alternate_price, -1 ) and
		deleted.order_no = @order_no

	while isnull ( @sequence, -1 ) <> -1
	begin

--	5,	Calculate standard price.
		exec msp_calc_order_currency @order_no, null, null, @sequence, null
		
--	6.	Get the next sequence for current order that has a price change.
		select	@sequence = min ( deleted.sequence )
		from	deleted
			join order_detail on order_detail.order_no = @order_no and
				order_detail.sequence = deleted.sequence
		where	IsNull ( order_detail.alternate_price, -1 ) <> IsNull ( deleted.alternate_price, -1 ) and
			deleted.order_no = @order_no and
			deleted.sequence > @sequence
	end

--	7.	Get the next order that has a price change.
	select	@order_no = min ( deleted.order_no )
	from	deleted
		join order_detail on order_detail.order_no = @order_no and
			order_detail.sequence = deleted.sequence
	where	IsNull ( order_detail.alternate_price, -1 ) <> IsNull ( deleted.alternate_price, -1 ) and
		deleted.order_no > @order_no
end

--	8.	Loop through all normal updated records for quantity or due date changes.
--	9.	Get first order that has a quantity or due date change.
select	@order_no = min ( deleted.order_no )
from	deleted
	join order_detail on order_detail.order_no = deleted.order_no and
		order_detail.sequence = deleted.sequence
where	(	order_detail.quantity <> deleted.quantity or
		order_detail.due_date <> deleted.due_date ) and
	deleted.ship_type = 'N'
		
while isnull ( @order_no, -1 ) <> -1
begin

--	10.	Get first sequence for current order that has a quantity or due date change.
	select	@sequence = min ( deleted.sequence )
	from	deleted
		join order_detail on order_detail.order_no = deleted.order_no and
			order_detail.sequence = deleted.sequence
	where	(	order_detail.quantity <> deleted.quantity or
			order_detail.due_date <> deleted.due_date ) and
		deleted.ship_type = 'N' and
		deleted.order_no = @order_no

	while isnull ( @sequence, -1 ) <> -1
	begin

--	11,	Calculate committed quantity.
		select	@part = part_number,
			@suffix = suffix
		from	order_detail
		where	order_no = @order_no and
			sequence = @sequence

		exec msp_calculate_committed_qty @order_no, @part, @suffix
		
--	12.	Get the next sequence for current order that has a quantity or due date change.
		select	@sequence = min ( deleted.sequence )
		from	deleted
			join order_detail on order_detail.order_no = deleted.order_no and
				order_detail.sequence = deleted.sequence
		where	(	order_detail.quantity <> deleted.quantity or
				order_detail.due_date <> deleted.due_date ) and
			deleted.ship_type = 'N' and
			deleted.order_no = @order_no and
			deleted.sequence > @sequence
	end

--	13.	Get the next order that has a quantity or due date change.
	select	@order_no = min ( deleted.order_no )
	from	deleted
		join order_detail on order_detail.order_no = deleted.order_no and
			order_detail.sequence = deleted.sequence
	where	(	order_detail.quantity <> deleted.quantity or
			order_detail.due_date <> deleted.due_date ) and
		deleted.ship_type = 'N' and
		deleted.order_no > @order_no
end


--	14.	Loop through all dropship updated records for quantity or due date changes.
--	15.	Get first order that has a quantity or due date change.
select	@order_no = min ( deleted.order_no )
from	deleted
	join order_detail on order_detail.order_no = deleted.order_no and
		order_detail.sequence = deleted.sequence
where	(	order_detail.quantity <> deleted.quantity or
		order_detail.due_date <> deleted.due_date ) and
	deleted.ship_type = 'D'
		
while isnull ( @order_no, -1 ) <> -1
begin

--	16.	Get first sequence for current order that has a quantity or due date change.
	select	@sequence = min ( deleted.sequence )
	from	deleted
		join order_detail on order_detail.order_no = deleted.order_no and
			order_detail.sequence = deleted.sequence
	where	(	order_detail.quantity <> deleted.quantity or
			order_detail.due_date <> deleted.due_date ) and
		deleted.ship_type = 'D' and
		deleted.order_no = @order_no

	while isnull ( @sequence, -1 ) <> -1
	begin

--	17,	Calculate committed dropship quantity.
		select	@rowid = row_id
		from	order_detail
		where	order_no = @order_no and
			sequence = @sequence

		exec msp_calc_committed_dropship @order_no, @rowid
		
--	18.	Get the next sequence for current order that has a quantity or due date change.
		select	@sequence = min ( deleted.sequence )
		from	deleted
			join order_detail on order_detail.order_no = deleted.order_no and
				order_detail.sequence = deleted.sequence
		where	(	order_detail.quantity <> deleted.quantity or
				order_detail.due_date <> deleted.due_date ) and
			deleted.ship_type = 'D' and
			deleted.order_no = @order_no and
			deleted.sequence > @sequence
	end

--	19.	Get the next order that has a quantity or due date change.
	select	@order_no = min ( deleted.order_no )
	from	deleted
		join order_detail on order_detail.order_no = deleted.order_no and
			order_detail.sequence = deleted.sequence
	where	(	order_detail.quantity <> deleted.quantity or
			order_detail.due_date <> deleted.due_date ) and
		deleted.ship_type = 'D' and
		deleted.order_no > @order_no
end
GO
ALTER TABLE [dbo].[order_detail] ADD CONSTRAINT [PK__order_de__3213E83F0697FACD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [destination_part] ON [dbo].[order_detail] ([destination], [part_number]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [order_rowid] ON [dbo].[order_detail] ([order_no], [row_id]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [rowid] ON [dbo].[order_detail] ([row_id]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
