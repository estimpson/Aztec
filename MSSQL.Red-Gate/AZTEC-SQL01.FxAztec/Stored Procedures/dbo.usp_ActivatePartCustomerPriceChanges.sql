SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ActivatePartCustomerPriceChanges] 
(	@TranDT datetime = null out,
	@Result int = 0 out)
as

set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn int,
	@ProcResult int,
	@Error int,
	@RowCount int
	
	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>


-- Lock table
delete	part_customer_blanketprice_changes
from	part_customer_blanketprice_changes with (tablockx)
where	1 = 0


-- Update part_customer 
set		@TableName = 'dbo.part_customer'
update	
		part_customer
set		
		part_customer.blanket_price = pcbc.blanket_price
from	
		part_customer join 
		part_customer_blanketprice_changes pcbc on 
		pcbc.part = part_customer.part and
		pcbc.customer = part_customer.customer
where	
		pcbc.effective_date < getdate() and pcbc.activated = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end


-- Update part_standard
set		@TableName = 'dbo.part_standard'
update	
		part_standard
set	
		part_standard.price = pcbc.blanket_price
from
		part_standard join
		part_customer_blanketprice_changes pcbc on
		pcbc.part = part_standard.part
where	
		pcbc.effective_date < getdate() and pcbc.activated = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end


-- Update order_header
set		@TableName = 'dbo.order_header'
update	
		order_header
set		
		order_header.price = pcbc.blanket_price
from	
		order_header join
		part_customer_blanketprice_changes pcbc on 
		pcbc.part = order_header.blanket_part and
		pcbc.customer = order_header.customer
where
		pcbc.effective_date < getdate() and pcbc.activated = 0
		
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end	
		

-- Update order_detail
set		@TableName = 'dbo.order_detail'
update	
		order_detail
set	
		order_detail.price = pcbc.blanket_price
from
		order_detail join
		order_header on
		order_header.order_no = order_detail.order_no and
		order_header.blanket_part = order_detail.part_number join
		part_customer_blanketprice_changes pcbc	on
		pcbc.part = order_header.blanket_part and
		pcbc.customer = order_header.customer
where
		pcbc.effective_date < getdate() and pcbc.activated = 0
			
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end		


-- Update shipper_detail
-- (where shipper has not been shipped, is not open or staged, and was not manually entered)
set		@TableName = 'dbo.shipper_detail'
update
		shipper_detail
set		
		shipper_detail.price = pcbc.blanket_price
from	
		shipper_detail join
		shipper on shipper_detail.shipper = shipper.id join
		order_header on
		order_header.order_no = shipper_detail.order_no and
		order_header.blanket_part = shipper_detail.part_original join
		part_customer_blanketprice_changes pcbc	on
		pcbc.part = order_header.blanket_part and
		pcbc.customer = order_header.customer
where 
		pcbc.effective_date < getdate() and pcbc.activated = 0
		and shipper.date_shipped is null
		and shipper.status in ('O', 'S')
		and shipper.type is null

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end	


-- Update blanket_price_changes_log (no error check)
update
		blanket_price_changes_log
set		
		blanket_price_changes_log.order_no = order_header.order_no
from
		order_header join
		part_customer_blanketprice_changes pcbc on 
		pcbc.part = order_header.blanket_part and
		pcbc.customer = order_header.customer
where
		pcbc.effective_date < getdate() and pcbc.activated = 0


-- Update part_customer_blanketprice_changes
set		@TableName = 'dbo.part_customer_blanketprice_changes'
update	
		part_customer_blanketprice_changes
set		
		activated = 1
where	
		effective_date < getdate() and activated = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
GO
