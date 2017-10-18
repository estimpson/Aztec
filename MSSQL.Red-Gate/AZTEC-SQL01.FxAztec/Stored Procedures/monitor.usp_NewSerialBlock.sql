SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [monitor].[usp_NewSerialBlock]
(	@SerialBlockSize tinyint,
	@FirstNewSerial integer out,
	@Result integer out)
as
/*
Example:
Test syntax {
begin transaction NewSerialBlock_Test

declare	@SerialBlockSize tinyint,
	@FirstNewSerial integer

set	@SerialBlockSize = 10

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

execute	@ProcReturn = monitor.usp_NewSerialBlock
	@SerialBlockSize = @SerialBlockSize,
	@FirstNewSerial = @FirstNewSerial out,
	@Result = @ProcResult out

set	@Error = @@error

select	ProcReturn = @ProcReturn, ProcResult = @ProcResult, Error = @Error, Serials = @SerialBlockSize, NewSerial = @FirstNewSerial, NextSerial = next_serial
from	parameters

rollback
}

Results {
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
Table 'audit_trail'. Scan count 1, logical reads 3, physical reads 0, read-ahead reads 0.
Table 'object'. Scan count 1, logical reads 3, physical reads 0, read-ahead reads 0.
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
ProcReturn  ProcResult  Error       Serials NewSerial   NextSerial
----------- ----------- ----------- ------- ----------- -----------
0           0           0           10      13726955    13726965
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
}
*/
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes>
declare	@TranCount smallint
set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
--- </Tran>

--	Argument Validation:
--		New serial block size is valid.
--- <Call>	
set	@CallProcName = 'monitor.usp_Validate_NewSerialBlockSize'

execute @ProcReturn = monitor.usp_Validate_NewSerialBlockSize
	@SerialBlockSize = @SerialBlockSize

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return @Result
end
--- </Call>

--	I.	Find new serial.
select	@FirstNewSerial = next_serial
from	parameters with (TABLOCKX)

while	exists
	(	select	serial
		from	object
		where	serial between @FirstNewSerial and @FirstNewSerial + @SerialBlockSize - 1) or
	exists
	(	select	serial
		from	audit_trail
		where	serial between @FirstNewSerial and @FirstNewSerial + @SerialBlockSize - 1) begin

	set	@FirstNewSerial = @FirstNewSerial + 1
end

--- <Update>
set	@TableName = 'dbo.parameters'

update
	dbo.parameters
set	next_serial = @FirstNewSerial + @SerialBlockSize

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, 1)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction NewSerialBlock
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	II.	Return.
set	@Result = 0
return	@Result
GO
