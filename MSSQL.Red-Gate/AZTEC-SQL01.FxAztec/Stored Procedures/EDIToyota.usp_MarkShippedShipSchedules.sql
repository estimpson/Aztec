SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [EDIToyota].[usp_MarkShippedShipSchedules]
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
/*	Mark any Ship Schedules that have been fully shipped. */
--- <Update rows="*">
set	@TableName = 'EDIToyota.ShipSchedules'

update
	ss
set
	Status = 2 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Shipped'))
from
	EDIToyota.ShipSchedules ss
	join EDIToyota.ShipScheduleHeaders ssh
		on ssh.RawDocumentGUID = ss.RawDocumentGUID
		and ssh.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active')
	join EDIToyota.Pickups p
		join EDIToyota.ManifestDetails md
			on md.PickupID = p.RowID
			and md.Status = 2 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'Shipped')
		on p.ShipToCode = ss.ShipToCode
		and p.PickupDT = ss.ReleaseDT
		and md.CustomerPart = ss.CustomerPart
		and md.ManifestNumber = ss.UserDefined1
		and p.Status = 2 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'Shipped')
where
	ss.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Active'))

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Mark any Ship Schedule headers that have been fully shipped. */
--- <Update rows="*">
set	@TableName = 'EDIToyota.ShipScheduleHeaders'

update
	ssh
set
	Status = 2 --(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Shipped'))
from
	EDIToyota.ShipScheduleHeaders ssh
where
	ssh.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active'))
	and exists
		(	select
				*
			from
				EDIToyota.ShipSchedules ss
			where
				ss.RawDocumentGUID = ssh.RawDocumentGUID
				and ss.Status = 2 --(dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Shipped'))
		)
	and not exists
		(	select
				*
			from
				EDIToyota.ShipSchedules ss
			where
				ss.RawDocumentGUID = ssh.RawDocumentGUID
				and ss.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Active'))
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
--- </Update>
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
	@ProcReturn = EDIToyota.usp_MarkShippedShipSchedules
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


GO
