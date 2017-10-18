
/*
Create Procedure.Fx.EDIToyota.usp_GetManifestHeaders_byPickupID.sql
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.usp_GetManifestHeaders_byPickupID'), 'IsProcedure') = 1 begin
	drop procedure EDIToyota.usp_GetManifestHeaders_byPickupID
end
go

create procedure EDIToyota.usp_GetManifestHeaders_byPickupID
	@PickupID int
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
select
	md.PickupID
,	md.ManifestNumber
,	Parts = count(distinct md.Part)
,	Racks = sum(md.Racks)
,	max(p.ShipperID)
from
	EDIToyota.ManifestDetails md
	join EDIToyota.Pickups p
		on md.PickupID = p.RowID
where
	md.PickupID = @PickupID
group by
	md.PickupID
,	md.ManifestNumber
order by
	ManifestNumber
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
	@ProcReturn = EDIToyota.usp_GetManifestHeaders_byPickupID
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

