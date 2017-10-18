
if	objectproperty(object_id('dbo.trInventoryControl_QualityBatchHeaders_i'), 'IsTrigger') = 1 begin
	drop trigger dbo.trInventoryControl_QualityBatchHeaders_i
end
go

create trigger dbo.trInventoryControl_QualityBatchHeaders_i on dbo.InventoryControl_QualityBatchHeaders for insert
as
set nocount on
set ansi_warnings off
declare
	@Result int

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=No>
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--- <Body>
declare
	newRows cursor for
select
	i.RowID
from
	inserted i
where
	i.QualityBatchNumber = '0'

open
	newRows

while
	1 = 1 begin
	
	declare
		@newRowID int
	
	fetch
		newRows
	into
		@newRowID
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	declare
		@NextNumber varchar(50)

	--- <Call>	
	set	@CallProcName = 'FT.usp_NextNumberInSequnce'
	execute
		@ProcReturn = FT.usp_NextNumberInSequnce
		@KeyName = 'dbo.InventoryControl_QualityBatchHeaders.QualityBatchNumber'
	,	@NextNumber = @NextNumber out
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return
	end
	--- </Call>

	--- <Update rows="1">
	set	@TableName = 'dbo.InventoryControl_QualityBatchHeaders'

	update
		icqbh
	set
		QualityBatchNumber = @NextNumber
	from
		dbo.InventoryControl_QualityBatchHeaders icqbh
	where
		icqbh.RowID = @newRowID

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
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
	--- </Body>
end

close
	newRows
deallocate
	newRows
go

