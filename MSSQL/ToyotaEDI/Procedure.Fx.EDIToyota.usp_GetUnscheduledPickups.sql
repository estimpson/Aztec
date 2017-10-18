
/*
Create Procedure.Fx.EDIToyota.usp_GetUnscheduledPickups.sql
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.usp_GetUnscheduledPickups'), 'IsProcedure') = 1 begin
	drop procedure EDIToyota.usp_GetUnscheduledPickups
end
go

create procedure EDIToyota.usp_GetUnscheduledPickups
	@PickupID int = null
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
	PickupID = p.RowID
,	p.PickupDT
,	bo.ShipToCode
,	p.PickupCode
,	bo.Plant
,	st.FOB
,	st.Carrier
,	st.TransMode
,	st.FreightType
,	st.ShipperNote
,	Parts = count(distinct bo.PartCode)
,	FreightAmount = 0
,	AETCNumber = convert(varchar(20), null)
,	DockCode = convert(varchar(15), null)
from
	EDIToyota.Pickups p
	join EDIToyota.ManifestDetails md
		on md.PickupID = p.RowID
		and md.Status = 0 --(dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'New'))
	join EDIToyota.BlanketOrders bo
		on bo.BlanketOrderNo = md.OrderNo
	join EDIToyota.ShipTos st
		on st.ShipToCode = bo.ShipToCode
where
	p.RowID = coalesce(@PickupID, p.RowID)
	and p.Status = 0 --(dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))
	and p.ShipperID is null
group by
	p.RowID
,	p.PickupDT
,	bo.ShipToCode
,	p.PickupCode
,	bo.Plant
,	st.FOB
,	st.Carrier
,	st.TransMode
,	st.FreightType
,	st.ShipperNote
order by
	PickupDT
,	ShipToCode
,	PickupCode
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
	@ProcReturn = EDIToyota.usp_GetUnscheduledPickups
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

