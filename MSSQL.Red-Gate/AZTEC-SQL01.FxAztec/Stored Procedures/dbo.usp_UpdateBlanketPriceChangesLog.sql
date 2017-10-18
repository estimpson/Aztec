SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_UpdateBlanketPriceChangesLog] 
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
where	1 = 0


-- Move import table data (new price) to log, as well as, current price and old price
insert blanket_price_changes_log (
	part,
	customer,
	new_effective_date,
	current_blanket_price,
	new_blanket_price,
	old_blanket_price,
	usercode,
	username,
	changed_date)
select 
	pcpi.part,
	pcpi.customer,
	pcpi.effective_date,
	part_customer.blanket_price,
	pcpi.blanket_price,
	pcbc.blanket_price,
	pcpi.usercode,
	pcpi.username,
	pcpi.changed_date
from 
	part_customer_price_import pcpi left join
	part_customer_blanketprice_changes pcbc on
	pcbc.part = pcpi.part and
	pcbc.customer = pcpi.customer and
	pcbc.effective_date =
	(	select
			max(effective_date)
		from
			dbo.part_customer_blanketprice_changes
		where
			part = pcpi.part
			and
				customer = pcpi.customer
			and
				effective_date <= pcpi.effective_date)
	 left join
	part_customer on
	part_customer.part = pcbc.part and
	part_customer.customer = pcbc.customer
where 
	pcpi.effective_date is not null and 
	pcpi.blanket_price is not null

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
