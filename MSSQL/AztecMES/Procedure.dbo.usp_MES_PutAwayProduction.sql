
/*
Create procedure fx21st.dbo.usp_MES_PutAwayProduction
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_PutAwayProduction'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_PutAwayProduction
end
go

create procedure dbo.usp_MES_PutAwayProduction
	@OperatorCode varchar(5)
,	@PartCode varchar(25)
,	@LocationCode varchar(10)
,	@TranDT datetime out
,	@Result integer out
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
--- <Update rows="1+">
set	@TableName = 'dbo.object'

update
	o
set
	location = @LocationCode
from
	dbo.object o
where
	o.part = @PartCode
	and o.location in
	(	select
			m.machine_no
		from
			dbo.machine m
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>
--- </Body>

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

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
	@OperatorCode varchar(5)
,	@PartCode varchar(25)
,	@LocationCode varchar(10)

set	@OperatorCode = '01956'
set	@PartCode = '1217SW19B'
set @LocationCode = ''

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_PutAwayProduction
	@OperatorCode = @OperatorCode
,	@PartCode = @PartCode
,	@LocationCode = @LocationCode
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

