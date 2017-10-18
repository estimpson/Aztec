declare
	@Operator varchar (10)
,	@PreObjectSerial int
,	@TranDT datetime
,	@Result int

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

declare
	@BackflushNumber varchar(50)

declare missingBF cursor local for
select
	atj.operator
,	bh.BackflushNumber
,	bh.TranDT
from
	dbo.BackflushHeaders bh
	join dbo.audit_trail atJ
		on atJ.type = 'J'
		and atJ.serial = bh.SerialProduced
	left join dbo.BackflushDetails bd
		on bh.BackflushNumber = bd.BackflushNumber
where
	bd.RowID is null

open
	missingBF

while
	1 =	1 begin

	fetch
		missingBF
	into
		@Operator
	,	@BackflushNumber
	,	@TranDT
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	begin transaction backflush
	
	execute @ProcReturn = dbo.usp_MES_Backflush
		@Operator = @Operator
	,	@BackflushNumber = @BackflushNumber
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set @Error = @@Error
	if @ProcResult != 0 begin
		set @Result = 999999
		raiserror ('An error result was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		break
	end
	if @ProcReturn != 0 
	begin
		set @Result = 999999
		raiserror ('An error was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		break
	end
	if @Error != 0 
	begin
		set @Result = 999999
		raiserror ('An error occurred during the execution of the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		break
	end
	
	select
		*
	from
		dbo.BackflushDetails bd
	where
		bd.BackflushNumber = @BackflushNumber
	
	commit
end

sp_lock