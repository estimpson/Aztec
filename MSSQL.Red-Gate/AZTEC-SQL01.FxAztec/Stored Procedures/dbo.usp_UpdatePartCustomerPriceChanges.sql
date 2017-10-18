SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_UpdatePartCustomerPriceChanges] 
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
delete	part_customer_price_import
from	part_customer_price_import with (tablockx)
where	effective_date is null or
		blanket_price is null


set		@TableName = 'dbo.part_customer_blanketprice_changes'


-- Update existing records in part_customer_blanketprice_changes	
update	
		part_customer_blanketprice_changes
set	
		part_customer_blanketprice_changes.blanket_price = pcpi.blanket_price
from
		part_customer_blanketprice_changes pcbc join
		part_customer_price_import pcpi on
		pcpi.part = pcbc.part and
		pcpi.customer = pcbc.customer and
		pcpi.effective_date = pcbc.effective_date

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end


-- Insert new records into part_customer_blanketprice_changes
insert	
		part_customer_blanketprice_changes (
		part,
		customer,
		effective_date,
		blanket_price)
select
		part,
		customer,
		effective_date,
		blanket_price
from
		part_customer_price_import pcpi
where
		not exists (select 
						*
					from 
						part_customer_blanketprice_changes pcbc
					where
						pcpi.part = pcbc.part and
						pcpi.customer = pcbc.customer and
						pcpi.effective_date = pcbc.effective_date)
		
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
GO
