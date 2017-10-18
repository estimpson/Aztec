SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_PriceAdmin_UpdatePartCustomerBlanketPricesLog] 
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
delete	PartCustomerBlanketPriceImport
from	PartCustomerBlanketPriceImport with (tablockx)
where	1 = 0


-- Move import table data (new price) to log, as well as, current price and old price
insert PartCustomerBlanketPriceChangesLog (
	Part,
	Customer,
	NewEffectiveDate,
	CurrentBlanketPrice,
	NewBlanketPrice,
	OldBlanketPrice,
	UserCode,
	UserName,
	ChangedDate)
select 
	pcpi.Part,
	pcpi.Customer,
	pcpi.EffectiveDate,
	part_customer.blanket_price,
	pcpi.BlanketPrice,
	pcbc.BlanketPrice,
	pcpi.UserCode,
	pcpi.UserName,
	pcpi.ChangedDate
from 
	PartCustomerBlanketPriceImport pcpi join
	PartCustomerBlanketPriceChanges pcbc on
	pcbc.Part = pcpi.Part and
	pcbc.Customer = pcpi.Customer join
	part_customer on
	part_customer.part = pcbc.Part and
	part_customer.customer = pcbc.Customer
where 
	pcpi.EffectiveDate is not null and 
	pcpi.BlanketPrice is not null and 
	((	pcpi.EffectiveDate = pcbc.EffectiveDate and
		pcpi.BlanketPrice <> pcbc.BlanketPrice) or
		pcpi.EffectiveDate <> pcbc.EffectiveDate)

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
