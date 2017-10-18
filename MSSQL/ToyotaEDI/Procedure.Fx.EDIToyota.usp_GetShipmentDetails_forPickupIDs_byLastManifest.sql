
/*
Create Procedure.Fx.EDIToyota.usp_GetShipmentDetails_forPickupIDs_byLastManifest.sql
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.usp_GetShipmentDetails_forPickupIDs_byLastManifest'), 'IsProcedure') = 1 begin
	drop procedure EDIToyota.usp_GetShipmentDetails_forPickupIDs_byLastManifest
end
go

create procedure EDIToyota.usp_GetShipmentDetails_forPickupIDs_byLastManifest
	@LastManifestNumber char (16)
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
if	Object_ID ('tempdb.dbo.#PickupIDs') is null begin
	create table #PickupIDs
	(	PickupID int primary key)
end

select
	OrderNo
,	CustomerPart
,	Part
,	CustomerPO =
		(	select
				customer_po
			from
				order_header
			where
				order_no = OrderNo
		)
,	QtyRequired = sum(Quantity)
,	Racks = sum(Racks)
from
	EDIToyota.ManifestDetails
where
	PickupID in
		(	select
				PickupID
			from
				#PickupIDs
		)
	and ManifestNumber <= @LastManifestNumber
group by
	OrderNo
,	CustomerPart
,	Part
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

begin transaction
go

create table #PickupIDs
(	PickupID int primary key)
go

insert	#PickupIDs
select	1 union all
select	2
go

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

declare	@LastManifest char (16) ; set @LastManifest = '60358021-6784910'

execute	@ProcReturn = EDIToyota.usp_GetShipmentdetails_forPickupIDs_byLastManifest
	@LastManifest = @LastManifest

set	@Error = @@error

select	ProcReturn = @ProcReturn, ProcResult = @ProcResult, Error = @Error
go

rollback
go
}

Results {
}
*/
go

