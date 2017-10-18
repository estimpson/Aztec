SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [EDIToyota].[usp_MarkShippedManifests]
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
/*	Get shipment and manifest details for fully and/or partially shipped manifests. */
declare
	@shipmentDetails table
(	ShipperID int
,	Part varchar(25)
,	QtyShipped numeric(20,6)
)

select
	ShipperID = s.id
,	Part = sd.part
,	QtyShipped = sum(sd.qty_packed)
from
	EDIToyota.ManifestDetails md
	join EDIToyota.Pickups p
		on p.RowID = md.PickupID
	join dbo.shipper s
		join dbo.shipper_detail sd
			on sd.shipper = s.id
		on s.id = p.ShipperID
		and sd.part = md.Part
where
	md.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'Scheduled'))
	and s.date_shipped is not null
group by
	s.id
,	sd.part

/*	Mark any manifest details to shipped status when their pickup has shipped. */
--- <Update rows="*">
set	@TableName = 'EDIToyota.ManifestDetails'

update
	md
set
	Status =
		case
			when s.date_shipped is not null then 2 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'Shipped'))
			when s.status = 'E' then 0 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'New'))
		end          
from
	EDIToyota.ManifestDetails md
	join EDIToyota.Pickups p
		on p.RowID = md.PickupID
	join dbo.shipper s
		on s.id = p.ShipperID
where
	md.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'Scheduled'))
	and
    (	s.date_shipped is not null
		or s.status = 'E'
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

/*	Set the pickups to "Shipped" status once shipper has a date shipped datestamp. */
--- <Update rows="*">
set	@TableName = 'EDIToyota.Pickups'

update
	p
set
	Status =
		case
			when s.date_shipped is not null then 2 --(dbo.udf_StatusValue('EDIToyota.Pickups', 'Shipped'))
			when s.status = 'E' then 0 --(dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))
		end
,	ShipperID =      
		case
			when s.date_shipped is not null then p.ShipperID
			when s.status = 'E' then null
		end
from
	EDIToyota.Pickups p
	join dbo.shipper s
		on s.id = p.ShipperID
where
	p.Status = 1 --(dbo.udf_StatusValue('EDIToyota.Pickups', 'Scheduled'))
	and
	(	s.date_shipped is not null
		or s.status = 'E'
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
	@ProcReturn = EDIToyota.usp_MarkShippedManifests
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
