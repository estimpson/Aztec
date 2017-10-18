SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [EDIToyota].[usp_RestoreManifestDetailsPart]
	@CustomerPart varchar(30)
,	@PickupID int
,	@ManifestNumber char(16)
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
/*	Determine if new pickup ID is required because this pickup has already been scheduled a new pickup has not yet been created. */
declare	@restorePickupID int

set @restorePickupID = coalesce
	(	(	select
				max(mdd.PickupID)
			from
				EDIToyota.ManifestDetailsDeleted mdd
				join EDIToyota.Pickups p
					on mdd.PickupID = p.RowID
					and p.ShipperID is null
			where
				@PickupID in (coalesce(mdd.OrigPickupID, mdd.PickupID), mdd.PickupID)
		)
	,	(	select
				max(md.PickupID)
			from
				EDIToyota.ManifestDetails md
				join EDIToyota.Pickups p
					on md.PickupID = p.RowID
					and p.ShipperID is null
			where
				@PickupID in (coalesce(md.OrigPickupID, md.PickupID), md.PickupID)
		)
	)

if	@restorePickupID is null begin
	
	--- <Insert rows="1">
	set @TableName = 'EDIToyota.Pickups'
	
	insert
		EDIToyota.Pickups
	(	ReleaseDate
	,	PickupDT
	,	ShipToCode
	,	PickupCode
	,	ShipperID
	,	Racks
	)
	select
		ReleaseDate
	,	PickupDT
	,	ShipToCode
	,	PickupCode
	,	ShipperID = null
	,	Racks
	from
		EDIToyota.Pickups
	where
		RowID = @PickupID
	
	select
		@Error = @@Error
	,	@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set @Result = 999999
		raiserror ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if @RowCount != 1 begin
		set @Result = 999999
		raiserror ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
--- </Insert>
	set @restorePickupID = scope_identity()
end

--- <Insert rows="1">
set @TableName = 'EDIToyota.ManifestDetails'

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
,	OrigPickupID
)
select
	PickupID = @restorePickupID
,	ManifestNumber
,	CustomerPart
,	ReturnableContainer
,	Part
,	Quantity
,	Racks
,	OrderNo
,	Plant
,	OrigPickupID = coalesce(OrigPickupID, nullif(PickupID, @restorePickupID))
from
	EDIToyota.ManifestDetailsDeleted mdd
where
	@PickupID in (coalesce(mdd.OrigPickupID, mdd.PickupID), mdd.PickupID)
	and mdd.ManifestNumber = @ManifestNumber
	and mdd.CustomerPart = @CustomerPart

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set @Result = 999999
	raiserror ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set @Result = 999999
	raiserror ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Delete rows="1">
set @TableName = 'EDIToyota.ManifestDetailsDeleted'

delete
	mdd
from
	EDIToyota.ManifestDetailsDeleted mdd
where
	@PickupID in (coalesce(mdd.OrigPickupID, mdd.PickupID), mdd.PickupID)
	and mdd.ManifestNumber = @ManifestNumber
	and mdd.CustomerPart = @CustomerPart

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set @Result = 999999
	raiserror ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set @Result = 999999
	raiserror ('Error deleting from table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Delete>
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
	@ProcReturn = EDIToyota.usp_RestoreManifestDetailsPart
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
