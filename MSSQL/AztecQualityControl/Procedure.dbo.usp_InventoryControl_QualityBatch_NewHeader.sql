
/*
Create Procedure.FxAztec.dbo.usp_InventoryControl_QualityBatch_NewHeader.sql
*/

use FxAztec
go

if	objectproperty(object_id('dbo.usp_InventoryControl_QualityBatch_NewHeader'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_InventoryControl_QualityBatch_NewHeader
end
go

create procedure dbo.usp_InventoryControl_QualityBatch_NewHeader
	@User varchar(10)
,	@Description varchar(255)
,	@QualityBatchNumber varchar(50) = null out
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
/*	Create a new header. */
if	nullif(@QualityBatchNumber,'') is null begin

	--- <Insert rows="1">
	set	@TableName = 'dbo.QualityBatchHeaders'

	insert
		dbo.InventoryControl_QualityBatchHeaders
	(	UserCode
	,	Description
	)
	select
		UserCode = @User
	,	Description = @Description

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Insert>
end
else begin

	--- <Insert rows="1">
	set	@TableName = 'dbo.QualityBatchHeaders'

	insert
		dbo.InventoryControl_QualityBatchHeaders
	(	UserCode
	,	QualityBatchNumber
	,	Description
	)
	select
		UserCode = @User
	,	QualityBatchNumber = @QualityBatchNumber  
	,	Description = @Description

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Insert>
end

/*	Get the new header number. */
select
	@QualityBatchNumber = QualityBatchNumber
from
	dbo.InventoryControl_QualityBatchHeaders icch
where
	icch.RowID = scope_identity()
--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_NewHeader
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
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
go

