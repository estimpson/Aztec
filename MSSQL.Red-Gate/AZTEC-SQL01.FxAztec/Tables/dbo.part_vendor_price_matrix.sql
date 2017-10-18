CREATE TABLE [dbo].[part_vendor_price_matrix]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [numeric] (20, 6) NOT NULL,
[break_qty] [numeric] (20, 6) NOT NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alternate_price] [decimal] (20, 6) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_pv_price_matrix_i] on [dbo].[part_vendor_price_matrix] for insert
as
begin
	-- declare local variables
	declare	@part				varchar(25),
			@vendor				varchar(10),
			@qty_break			numeric(20,6)

	-- get first updated/inserted row
	select	@part = min(part)
	from	inserted

	-- loop through all updated records
	while ( isnull(@part,'') <> '' )
	begin

		select	@vendor = min(vendor)
		from	inserted
		where	part = @part

		while ( isnull(@vendor,'') <> '' )
		begin

			select	@qty_break = min(break_qty)
			from	inserted
			where	part = @part and
					vendor = @vendor

			while ( isnull(@qty_break,-1) <> -1 )
			begin

				exec msp_calc_vendor_matrix @part, @vendor, @qty_break, null

				select	@qty_break = min(break_qty)
				from	inserted
				where	part = @part and
						vendor = @vendor and
						break_qty > @qty_break

			end

			select	@vendor = min(vendor)
			from	inserted
			where	part = @part and
					vendor > @vendor

		end

		select	@part = min(part)
		from	inserted
		where	part > @part

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_pv_price_matrix_u] on [dbo].[part_vendor_price_matrix] for update
as
begin
	-- declare local variables
	declare	@part				varchar(25),
			@vendor				varchar(10),
			@qty_break			numeric(20,6),
			@inserted_ap		numeric(20,6),
			@deleted_ap			numeric(20,6)

	-- get first updated/inserted row
	select	@part = min(part)
	from	inserted

	-- loop through all updated records
	while ( isnull(@part,'') <> '' )
	begin

		select	@vendor = min(vendor)
		from	inserted
		where	part = @part

		while ( isnull(@vendor,'') <> '' )
		begin

			select	@qty_break = min(break_qty)
			from	inserted
			where	part = @part and
					vendor = @vendor

			while ( isnull(@qty_break,-1) <> -1 )
			begin

				select	@deleted_ap = alternate_price
				from	deleted
				where	part = @part and
						vendor = @vendor and
						break_qty = @qty_break

				select	@inserted_ap = alternate_price
				from	inserted
				where	part = @part and
						vendor = @vendor and
						break_qty = @qty_break

				select @deleted_ap = isnull(@deleted_ap,0)
				select @inserted_ap = isnull(@inserted_ap,0)

				if @deleted_ap <> @inserted_ap
					exec msp_calc_vendor_matrix @part, @vendor, @qty_break, null

				select	@qty_break = min(break_qty)
				from	inserted
				where	part = @part and
						vendor = @vendor and
						break_qty > @qty_break

			end

			select	@vendor = min(vendor)
			from	inserted
			where	part = @part and
					vendor > @vendor

		end

		select	@part = min(part)
		from	inserted
		where	part > @part

	end

end
GO
ALTER TABLE [dbo].[part_vendor_price_matrix] ADD CONSTRAINT [PK__part_ven__0485CDF65E54FF49] PRIMARY KEY CLUSTERED  ([part], [vendor], [break_qty]) ON [PRIMARY]
GO
