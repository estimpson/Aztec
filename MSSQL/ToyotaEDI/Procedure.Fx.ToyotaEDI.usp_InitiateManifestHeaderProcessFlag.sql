
/*
Create Procedure.Fx.EDIToyota.usp_InitiateManifestHeaderProcessFlag.sql
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.usp_InitiateManifestHeaderProcessFlag'), 'IsProcedure') = 1 begin
	drop procedure EDIToyota.usp_InitiateManifestHeaderProcessFlag
end
go

create procedure EDIToyota.usp_InitiateManifestHeaderProcessFlag
	@PickupDT datetime
,	@ManifestNumber char(16)
,	@ShipToCode varchar(10)
,	@DockCode varchar(10)
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
--	Set the process flag (ShipperID = 0) for the specified row.  Take a table lock.
update
	EDIToyota.ManifestHeaders
set
	ShipperID = 0
from
	EDIToyota.ManifestHeaders with (tablockx)
where
	PickupDT = @PickupDT
	and ManifestNumber = @ManifestNumber
	and ShipToCode = @ShipToCode
--	and DockCode = @DockCode

--- <Validate Type=Update Rows=One>
select	@Error = @@error,
	@Rowcount = @@rowcount

set	@TableName = 'EDIToyota.ManifestHeaders'
---	<Error Num="900200" Msg="Error updating record in table %s in procedure %s.">
if	@Error != 0 begin
	set	@Result = 900200
	RAISERROR (@Result, 16, 1, @TableName, @ProcName)
	return	@Result
end
---	</Error>
---	<Error Num="900201" Msg="Row not found updating record in table %s in procedure %s.">
if	@Rowcount !> 0 begin
	set	@Result = 900201
	RAISERROR (@Result, 16, 1, @TableName, @ProcName)
	return	@Result
end
---	</Error>
---	<Error Num="900202" Msg="Multiple-records error updating record in table %s in procedure %s.">
if	@Rowcount > 1 begin
	set	@Result = 900202
	RAISERROR (@Result, 16, 1, @TableName, @ProcName)
	return	@Result
end
---	</Error>
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDIToyota.usp_InitiateManifestHeaderProcessFlag
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

