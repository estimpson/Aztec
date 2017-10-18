
/*
Create Procedure.FxEDI.EDI.usp_DeleteOldDocuments.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.usp_DeleteOldDocuments'), 'IsProcedure') = 1 begin
	drop procedure EDI.usp_DeleteOldDocuments
end
go

create procedure EDI.usp_DeleteOldDocuments
	@TranDT datetime = null out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
/*	Clear FileTable of old EDI documents. */
if	exists
		(	select
				*
			from
				dbo.RawEDIData red
			where
				red.file_type = 'xml'
				and red.is_directory = 0
				and red.creation_time < getdate() - 30
		) begin
	
	--- <Delete rows="1+">
	set	@TableName = 'dbo.RawEDIData'
	
	delete
		red
	from
		dbo.RawEDIData red
	where
		red.file_type = 'xml'
		and red.is_directory = 0
		and red.creation_time < getdate() - 30
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount < 1 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end

/*	Clear EDIDocuments of old EDI documents. */
if	exists
		(	select
				*
			from
				EDI.EDIDocuments ed
			where
				ed.RowCreateDT < getdate() - 30
		) begin
	
	--- <Delete rows="1+">
	set	@TableName = 'dbo.RawEDIData'
	
	delete
		ed
	from
		EDI.EDIDocuments ed
	where
		ed.RowCreateDT < getdate() - 30

	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount < 1 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end
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
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_DeleteOldDocuments
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

if	@Error != 0 begin
	rollback
	return
end

if	@@trancount > 0 begin
	commit
end

set statistics io off
set statistics time off
go

}

Results {
}
*/
go

