
/*
Create Procedure.dbo.usp_InventoryControl_QualityBatch_RemoveObject.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_InventoryControl_QualityBatch_RemoveObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_InventoryControl_QualityBatch_RemoveObject
end
go

create procedure dbo.usp_InventoryControl_QualityBatch_RemoveObject
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int = null
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
/*	If no #serialList exists, create one and add the passed serial to it. */
if	object_id('tempdb..#serialList') is null begin
	create table #serialList
	(	serial int
	,	RowID int not null IDENTITY(1, 1) primary key
	)
	
	insert
		#serialList
	select
		Serial = @Serial
	where
		@Serial is not null
end

/*	Remove serial(s) from cycle count objects. */
--- <Delete rows="*">
set	@TableName = 'dbo.InventoryControl_QualityBatchObjects'

delete
	icqbo
from
	dbo.InventoryControl_QualityBatchObjects icqbo
where
	icqbo.QualityBatchNumber = @QualityBatchNumber
	and Serial in
		(	select
				Serial = sl.serial
			from
				#serialList sl
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>
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
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int = null

set	@User = 'mon'
set	@QualityBatchNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_RemoveObject
	@User = @User
,	@QualityBatchNumber = @QualityBatchNumber
,	@Serial = @Serial
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

