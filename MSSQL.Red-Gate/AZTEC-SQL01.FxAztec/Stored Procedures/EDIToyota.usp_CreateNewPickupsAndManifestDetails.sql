SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [EDIToyota].[usp_CreateNewPickupsAndManifestDetails]
	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
,	@Testing INT = 1
--<Debug>
,	@Debug INTEGER = 0
--</Debug>
AS
set nocount on
set ansi_warnings off
set	@Result = 999999

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	set	@StartDT = GetDate ()
	print	'START.   ' + Convert (varchar (50), @StartDT)
	SET	@ProcStartDT = GETDATE ()
END
--</Debug>

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
ELSE BEGIN
	SAVE TRAN @ProcName
END
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*		New pickups required for any active pickups that have new active manifest details. */
--<Debug>
if @Debug & 1 = 1 begin
	print	'Create new pickups and manifest details.'
	PRINT	'	New pickups required for any active pickups that have new active manifest details.'
END
--</Debug>
--- <Insert rows="*">
set	@TableName = 'EDIToyota.Pickups'

insert
	EDIToyota.Pickups
(	ReleaseDate
,	PickupDT
,	ShipToCode
,	PickupCode
)
select
	pa.ReleaseDate
,   pa.PickupDT
,   pa.ShipToCode
,   pa.PickupCode
from
	EDIToyota.Pickups_Active pa
where
	not exists
		(	select
				*
			from
				EDIToyota.Pickups p
			where
				p.ShipToCode = pa.ShipToCode
				and p.PickupDT = pa.PickupDT
				and p.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))
				and p.ShipperID is null
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
--- </Insert>

/*		New manifest details for new active manifest details. */
--select
--	PickupID = p.RowID
--,	mda.ManifestNumber
--,   mda.CustomerPart
--,   coalesce(mda.ReturnableContainer,'TOYOTATOTE')
--,   mda.Part
--,   mda.Quantity
--,   mda.Racks
--,   mda.OrderNo
--,   mda.Plant
--,	p.shipToCode
--from
--	EDIToyota.ManifestDetails_Active mda
--	join EDIToyota.Pickups p
--		on p.ShipToCode = mda.ShipToCode
--		and p.PickupDT = mda.PickupDT
--		and p.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))
--		and p.ShipperID is null
--where
--	not exists
--		(	select
--				*
--			from
--				EDIToyota.ManifestDetails rd
--			where
--				rd.OrderNo = mda.OrderNo
--				and rd.ManifestNumber = mda.ManifestNumber
--		)

--Select * From EDIToyota.ManifestDetails_Active
--Select * From EDIToyota.Pickups
--<Debug>
if @Debug & 1 = 1 begin
	print	'	New manifest details for new active manifest details.'
end
--</Debug>
--- <Insert rows="*">
set	@TableName = 'EDIToyota.ManifestDetails'

insert
	EDIToyota.ManifestDetails
(	PickupID
,	ManifestNumber
,	CustomerPart
,	ReturnableContainer
,	Part
,	Quantity
,	Racks
,	OrderNo
,	Plant
)
select
	PickupID = p.RowID
,	mda.ManifestNumber
,   mda.CustomerPart
,   coalesce(mda.ReturnableContainer,'TOYOTATOTE')
,   mda.Part
,   mda.Quantity
,   mda.Racks
,   mda.OrderNo
,   mda.Plant
from
	EDIToyota.ManifestDetails_Active mda
	join EDIToyota.Pickups p
		on p.ShipToCode = mda.ShipToCode
		and p.PickupDT = mda.PickupDT
		AND p.PickupCode = mda.PickupCode
		and p.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))
		and p.ShipperID is null
where
	not exists
		(	select
				*
			from
				EDIToyota.ManifestDetails rd
			where
				rd.OrderNo = mda.OrderNo
				and rd.ManifestNumber = mda.ManifestNumber
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
--- </Insert>

if	@Testing > 0 begin
	select
		'Pickups_Active'
	
	select
		*
	from
		EDIToyota.Pickups_Active rsha
	
	select
		'ManifestDetails_Active'
	
	select
		*
	from
		EDIToyota.ManifestDetails_Active mda
	
	select
		'Pickups'

	select
		*
	from
		EDIToyota.Pickups rsh
	
	select
		'ManifestDetails'
	
	SELECT
		*
	FROM
		EDIToyota.ManifestDetails rd 
		ORDER BY PickupID DESC
END

--<Debug>
if @Debug & 1 = 1 begin
	print	'...created.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
RETURN
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
	@Testing int = 1
,	@Debug integer = 0

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDIToyota.usp_CreateNewPickupsAndManifestDetails
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Testing = @Testing
,	@Debug = @Debug

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

--commit
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
