SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_QualityBatch_UpdateHeader]
	@QualityBatchNumber varchar(50)
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Adjust header. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_QualityBatchHeaders'

update
	icqbh
set	
	SortedCount =
		(	select
				count(*)
			from
				dbo.InventoryControl_QualityBatch_Objects icqbo
			where
				icqbo.QualityBatchNumber = @QualityBatchNumber
				and icqbo.Status != 0
		)
,	ScrapCount =
		(	select
				count(*)
			from
				dbo.InventoryControl_QualityBatch_Objects icqbo
			where
				icqbo.QualityBatchNumber = @QualityBatchNumber
				and icqbo.Status in (-1, 2)
		)
,	ScrapQuantity =
		(	select
					coalesce(sum(icqbo.ScrapQuantity), 0)
			from
				dbo.InventoryControl_QualityBatch_Objects icqbo
			where
				icqbo.QualityBatchNumber = @QualityBatchNumber
		)
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
where
	icqbh.QualityBatchNumber = @QualityBatchNumber

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@QualityBatchNumber varchar(50)

set	@QualityBatchNumber = 'QC_000000004'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_UpdateHeader
	@QualityBatchNumber = @QualityBatchNumber
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
where
	icqbh.QualityBatchNumber = @QualityBatchNumber
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/

GO
