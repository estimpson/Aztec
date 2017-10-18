CREATE TABLE [dbo].[shipper]
(
[id] [int] NOT NULL,
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shipping_dock] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[aetc_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_of_lading_number] [int] NULL,
[model_year_desc] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_year] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[staged_objs] [int] NULL,
[plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoiced] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_number] [int] NULL,
[freight] [numeric] (15, 6) NULL,
[tax_percentage] [numeric] (6, 3) NULL,
[total_amount] [numeric] (15, 6) NULL,
[gross_weight] [numeric] (20, 6) NULL,
[net_weight] [numeric] (20, 6) NULL,
[tare_weight] [numeric] (20, 6) NULL,
[responsibility_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_mode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pro_number] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_shipped] [datetime] NULL,
[truck_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seal_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_rate] [numeric] (20, 6) NULL,
[staged_pallets] [int] NULL,
[container_message] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[picklist_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dropship_reconciled] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_stamp] [datetime] NULL,
[platinum_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posted] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scheduled_ship_time] [datetime] NULL,
[currency_unit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_euro_amount] [smallint] NULL,
[cs_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bol_ship_to] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bol_carrier] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpediteCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_shipper_i] on [dbo].[shipper] for insert
as
begin
-----------------------------------------------------------------------------------------------
--	Harish G.P	11/17/01	Included the code to sync shipper and invoice on manual
--					invoices.
--			09/06/02	Commented the shipper update st. to overcome the 
--					recurrisive trigger problem.
-----------------------------------------------------------------------------------------------
	-- declarations
	declare	@shipper	integer
	declare @type		char(1)

	-- get first updated row
	select	@shipper = min(id)
	from 	inserted

	-- loop through all updated records
	while ( isnull(@shipper,-1) <> -1 )
	begin

		if (	select	isnull(currency_unit,'')
			from	inserted
			where	id = @shipper ) > ''
		begin
			exec msp_calc_invoice_currency @shipper, null, null, null, null
/*
			update 	shipper set
				cs_status = destination.cs_status
			from	destination
			where	shipper.id = @shipper and
				destination.destination = shipper.destination
*/				
		end
/*		else
			update 	shipper set
				cs_status = destination.cs_status,
				currency_unit = isnull ( destination.default_currency_unit, (	select	default_currency_unit
												from	customer
												where	customer.customer = destination.customer  ) )
			from	destination
			where	shipper.id = @shipper and
				destination.destination = shipper.destination
*/		
		-- Get the type from the inserted view
		select	@type = isnull(type,'')
		from	inserted
		where	id = @shipper

		-- check if type is 'M', (ie manual invoice) then, sync shipper & invoice no.
		-- if need be add other types too here
		if @type ='M'
			execute msp_sync_shipper_invoice @shipper

		select	@shipper = min(id)
		from 	inserted
		where	id > @shipper

	end

end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_shipper_u]
on [dbo].[shipper]
for update
as
-----------------------------------------------------------------------------------------------
--	Modifications	08/08/02, HGP	Commented the date updation statement on the shipper as
--					that's being handled in the msp_shipout routine
--			09/06/02, HGP	Commented the shipper update st. to overcome the 
--					recurrsive trigger problem.
-----------------------------------------------------------------------------------------------
-- declarations
declare	@shipper		integer,
	@inserted_cu		varchar (3),
	@inserted_status	varchar (20),
	@deleted_cu		varchar (3),
	@deleted_status 	varchar (20),
	@type			varchar (7),
	@order_no		numeric(8,0),
	@inserted_invoice	integer,
	@deleted_invoice	integer

-- set shipper_detail.date_shipped and order_header last_shipped on ship out
if exists (
	select	inserted.status
	from	inserted
		join deleted on inserted.id = deleted.id
	where	inserted.status = 'C' and
		deleted.status <> 'C' )
begin
	update	order_header
	   set	shipper = inserted.id
	  from	inserted
	  	join shipper_detail on inserted.id = shipper_detail.shipper
	 where	shipper_detail.order_no = order_header.order_no
end

-- get first updated row
select	@shipper = min ( id )
  from 	inserted

-- loop through all updated records
while ( isnull ( @shipper, -1 ) <> -1 )
begin
	select	@deleted_cu = currency_unit,
		@deleted_status = status,
		@deleted_invoice = invoice_number
	  from	deleted
	 where	id = @shipper

	select	@inserted_cu = currency_unit,
		@inserted_status = status,
		@inserted_invoice = invoice_number,
		@type = isnull ( type, 'Q' )
	  from	inserted
	 where	id = @shipper

	select	@deleted_cu = isnull ( @deleted_cu, '' )
	select	@deleted_status = isnull ( @deleted_status, '' )
	select	@inserted_cu = isnull ( @inserted_cu, '' )
	select	@inserted_status = isnull ( @inserted_status, '' )

	if @deleted_cu <> @inserted_cu
		exec msp_calc_invoice_currency @shipper, null, null, null, null

	else if @inserted_status <> @deleted_status and @inserted_status = 'C'
	begin
/*	
		update	shipper
		set	date_shipped = GetDate ( )
		where	id = @shipper
*/

		update	shipper_detail
		set	total_cost = isnull (
			(	select	sum ( std_quantity * cost )
				from	audit_trail
				where	audit_trail.shipper = convert(varchar,@shipper) and
					part=shipper_detail.part_original and
					isnull ( audit_trail.suffix, 0 ) = isnull ( shipper_detail.suffix, 0 ) and
					audit_trail.type = 'S' ), total_cost )
		from	shipper_detail
		where	shipper_detail.shipper = @shipper

		select	@order_no = min(order_no)
		from	shipper_detail
		where	shipper = @shipper
		
		while ( isnull(@order_no,0) > 0 )
		begin
		
			exec msp_calculate_committed_qty @order_no, null, null
			
			select @order_no = isnull ( (
				select	min(order_no)
				from	shipper_detail
				where	shipper = @shipper and
					order_no > @order_no ), 0 )
		end
	end

/*
	update 	shipper
	set	cs_status = destination.cs_status
	from	destination
	where	shipper.id = @shipper and
		destination.destination = shipper.destination
*/		

--	Commented the below if statement as it has to call that proc for all types of shippers
	if isnull ( @inserted_invoice, 0 ) <> isnull ( @deleted_invoice, 0 ) -- and @type = 'Q'
		exec msp_sync_shipper_invoice @shipper
		
	select	@shipper = min(id)
	  from 	inserted
	 where	id > @shipper
end
GO
ALTER TABLE [dbo].[shipper] ADD CONSTRAINT [PK__shipper__4F089A18] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [bwa_shipper_cust_indx] ON [dbo].[shipper] ([customer], [date_shipped]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [bi_shipper_pl1] ON [dbo].[shipper] ([status], [date_stamp]) ON [PRIMARY]
GO
