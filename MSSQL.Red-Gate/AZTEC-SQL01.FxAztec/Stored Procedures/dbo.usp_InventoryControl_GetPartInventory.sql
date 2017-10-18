SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_GetPartInventory]
	@Part varchar(25)
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
select
	Plant = coalesce(l.plant, o.plant)
,	Location = o.location
,	OnHand = coalesce(sum(case when o.status = 'A' then o.std_quantity end), 0)
,	Outside = coalesce(sum(case when o.status = 'P' then o.std_quantity end), 0)
,	OnHold = coalesce(sum(case when o.status = 'H' then o.std_quantity end), 0)
,	Scrapped = coalesce(sum(case when o.status = 'S' then o.std_quantity end), 0)
,	Rejected = coalesce(sum(case when o.status = 'R' then o.std_quantity end), 0)
,	Obsolete = coalesce(sum(case when o.status = 'O' then o.std_quantity end), 0)
,	CommittedQty = coalesce(sum(case when o.shipper > 0 and o.status = 'A' then o.std_quantity end), 0)
from
	dbo.object o
	left join dbo.location l
		on l.code = o.location
where
	o.part = @Part
group by
	o.part
,	o.location
,	coalesce(l.plant, o.plant)
order by
	coalesce(l.plant, o.plant) asc
,	o.location asc
--- </Body>

if	@TranCount = 0 begin
	rollback tran @ProcName
end

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

set statistInventoryControls io on
set statistInventoryControls time on
go

declare
	@Part varchar(25)

set	@Part = ''

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_GetPartInventory
	@Part = @Part
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

set statistInventoryControls io off
set statistInventoryControls time off
go

}

Results {
}
*/
GO
