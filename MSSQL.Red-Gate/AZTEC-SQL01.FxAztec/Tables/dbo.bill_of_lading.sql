CREATE TABLE [dbo].[bill_of_lading]
(
[bol_number] [int] NOT NULL,
[scac_transfer] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scac_pickup] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_mode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[equipment_initial] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[equipment_description] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gross_weight] [numeric] (7, 2) NULL,
[net_weight] [numeric] (7, 2) NULL,
[tare_weight] [numeric] (7, 2) NULL,
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lading_quantity] [numeric] (20, 6) NULL,
[total_boxes] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_bill_of_lading_u] on [dbo].[bill_of_lading] for update
as
begin
	declare updated_rows cursor for
		select	bol_number,
			scac_transfer,
			scac_pickup,
			trans_mode,
			destination
		from	inserted

	declare	@bol_number integer,
		@scac_transfer varchar(10),
		@scac_pickup varchar(10),
		@trans_mode varchar(10),
		@destination varchar(20)
		
	open updated_rows
	fetch updated_rows into @bol_number,@scac_transfer,@scac_pickup,@trans_mode,@destination
	while ( @@fetch_status = 0 )
	begin
		if update ( scac_transfer ) or update ( scac_pickup ) or update ( trans_mode ) or update ( destination )
		begin
			update	shipper
			set	ship_via = @scac_transfer,
				bol_carrier = @scac_pickup,
				trans_mode = @trans_mode,
				bol_ship_to = @destination
			where	bill_of_lading_number = @bol_number
		end
		fetch updated_rows into @bol_number,@scac_transfer,@scac_pickup,@trans_mode,@destination
	end
	close updated_rows
	deallocate updated_rows
end
GO
ALTER TABLE [dbo].[bill_of_lading] ADD CONSTRAINT [PK__bill_of_lading__7DF8932B] PRIMARY KEY CLUSTERED  ([bol_number]) ON [PRIMARY]
GO
