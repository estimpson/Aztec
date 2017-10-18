SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_PriceAdmin_ImportBlanketPriceChanges]
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
delete	BlanketPriceImport
from	BlanketPriceImport with (tablockx)
where	EffectiveDate is null or
		BlanketPrice is null


set		@TableName = 'dbo.BlanketPriceChanges'


-- Update existing records in BlanketPriceChanges	
update	
		BlanketPriceChanges
set	
		BlanketPriceChanges.BlanketPrice = bpi.BlanketPrice,
		BlanketPriceChanges.UserCode = bpi.UserCode,
		BlanketPriceChanges.UserName = bpi.UserName,
		BlanketPriceChanges.ChangedDate = bpi.ChangedDate,
		BlanketPriceChanges.CustomerPO = bpi.CustomerPO
from
		BlanketPriceChanges bpc join
		BlanketPriceImport bpi on
		bpi.Part = bpc.Part and
		bpi.Customer = bpc.Customer and
		bpi.EffectiveDate = bpc.EffectiveDate
where	
		bpc.Activated = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end


-- Insert new records into BlanketPriceChanges
insert	
		BlanketPriceChanges (
		Part,
		Customer,
		EffectiveDate,
		BlanketPrice,
		CustomerPO,
		UserCode,
		UserName,
		ChangedDate)
select
		Part,
		Customer,
		EffectiveDate,
		BlanketPrice,
		CustomerPO,
		UserCode,
		UserName,
		ChangedDate
from
		BlanketPriceImport bpi
where
		not exists (select 
						*
					from 
						BlanketPriceChanges bpc
					where
						bpi.Part = bpc.Part and
						bpi.Customer = bpc.Customer and
						bpi.EffectiveDate = bpc.EffectiveDate)
		
select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end


--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
set	@Result = 0
return @Result
GO
