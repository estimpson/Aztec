
/*
Create procedure Fx.dbo.usp_InventoryControl_CycleCount_AddObject
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_InventoryControl_CycleCount_AddObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_InventoryControl_CycleCount_AddObject
end
go

create procedure dbo.usp_InventoryControl_CycleCount_AddObject
	@User varchar(10)
,	@CycleCountNumber varchar(50)
,	@Serial int = null
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
/*	If no #serialList exists, create one and add the passed serial to it. */
if	object_id('tempdb..#serialList') is null begin
	create table #serialList
	(	serial int
	,	RowID int not null IDENTITY(1, 1) primary key
	)
	
	insert
		#serialList
	select
		Serial = @Serial
	where
		@Serial is not null
end

/*	Add serial(s) to cycle count objects. */
--- <Insert rows="*">
set	@TableName = 'dbo.CycleCountHeaders'

insert
	dbo.InventoryControl_CycleCountObjects
(	CycleCountNumber
,	Line
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalLocation
)
select
	CycleCountNumber = @CycleCountNumber
,	Line = coalesce(icco.MaxLine, 0) + row_number() over (order by cco.RowID, cco.Serial)
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalLocation
from
	(	select
			RowID = sl.RowID
		,	Serial = sl.serial
		,	Part = o.part
		,	OriginalQuantity = o.std_quantity
		,	Unit = pi.standard_unit
		,	OriginalLocation = o.location
		from
			#serialList sl
			join dbo.object o
				on o.serial = sl.serial
			join dbo.part p
				on p.part = o.part
			join dbo.part_inventory pi
				on pi.part = o.part
		--union all
		--select
		--	RowID = sl.RowID
		--,	Serial = sl.serial
		--,	Part = at.part
		--,	Quantity = at.std_quantity
		--,	Unit = pi.standard_unit
		--,	Location = at.location
		--from
		--	#serialList sl
		--	join dbo.audit_trail atLast
		--		on atLast.serial = sl.serial
		--		and atLast.id =
		--		(	select
		--				max(id)
		--			from
		--				dbo.audit_trail
		--			where
		--				serial = sl.serial
		--		)
		--	join dbo.part p
		--		on p.part = atLast.part
		--	join dbo.part_inventory pi
		--		on pi.part = atLast.part
		--where
		--	sl.serial not in
		--	(	select
		--			serial
		--		from
		--			dbo.object
		--	)
	) cco
	left join
	(	select
			MaxLine = max(Line)
		from
			dbo.InventoryControl_CycleCountObjects icco
		where
			CycleCountNumber = @CycleCountNumber
	) icco on 1 = 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>
--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

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
	@User varchar(10)
,	@CycleCountNumber varchar(50)
,	@Serial int = null

set	@User = 'mon'
set	@CycleCountNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_AddObject
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
,	@Serial = @Serial
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

