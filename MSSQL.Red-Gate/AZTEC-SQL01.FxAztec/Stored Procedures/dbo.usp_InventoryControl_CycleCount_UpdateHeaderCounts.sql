SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_CycleCount_UpdateHeaderCounts]
	@User varchar(10)
,	@CycleCountNumber varchar(50)
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
/*	Update objects. */
--- <Update rows="*">
set	@TableName = 'dbo.InventoryControl_CycleCountObjects'

update
	iccco
set
	Status =
		case
			when iccco.Status > 0 and o.serial is null then 5
			when iccco.Status > 0 and o.serial is not null and iccco.CorrectedQuantity is null and iccco.CorrectedLocation is null then 1
			when iccco.Status > 0 and o.serial is not null and iccco.CorrectedQuantity != iccco.OriginalQuantity and iccco.CorrectedLocation is null then 2
			when iccco.Status > 0 and o.serial is not null and iccco.CorrectedQuantity is null and iccco.CorrectedLocation != iccco.OriginalLocation then 3
			when iccco.Status > 0 and o.serial is not null and iccco.CorrectedQuantity != iccco.OriginalQuantity and iccco.CorrectedLocation != iccco.OriginalLocation then 4
			else iccco.Status
		end
,	Type = case when o.serial is null and iccco.Status > 0 then 1 else 0 end
from
	dbo.InventoryControl_CycleCountObjects iccco
	left join dbo.object o
		on o.serial = iccco.Serial
where
	iccco.CycleCountNumber = @CycleCountNumber
	and iccco.RowCommittedDT is null

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

/*	Update header. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_CycleCountHeaders'

update
	iccch
set
	ExpectedCount = counts.ExpectedCount
,	FoundCount = counts.FoundCount
,	RecoveredCount = counts.RecoveredCount
,	QtyAdjustedCount = counts.QtyAdjustedCount
,	LocationChangedCount = counts.LocationChangedCount
from
	dbo.InventoryControl_CycleCountHeaders iccch
	left join
	(	select
			ExpectedCount = sum(co.ExpectedCount)
		,	FoundCount = sum(co.FoundCount)
		,	RecoveredCount = sum(co.RecoveredCount)
		,	QtyAdjustedCount = sum(co.QtyAdjustedCount)
		,	LocationChangedCount = sum(co.LocationChangedCount)
		from
			(	select
					iccco.Serial
				,	ExpectedCount = max(case when iccco.Type = 0 and iccco.Status != -2 then 1 else 0 end)
				,	FoundCount = max(case when iccco.Type = 0 and iccco.Status > 0 then 1 else 0 end)
				,	RecoveredCount = max(case when iccco.Type = 1 and iccco.Status > 0 then 1 else 0 end)
				,	QtyAdjustedCount = max(case when iccco.Type = 0 and iccco.Status in (2, 4) then 1 else 0 end)
				,	LocationChangedCount = max(case when iccco.Type = 0 and iccco.Status in (3, 4) then 1 else 0 end)
				from
					dbo.InventoryControl_CycleCountObjects iccco
				where
					iccco.CycleCountNumber = @CycleCountNumber
				group by
					iccco.Serial
			) co
	) counts
		on 1 = 1
where
	iccch.CycleCountNumber = @CycleCountNumber

--select
--	ExpectedCount = count(distinct case when iccco.Type = 0 and iccco.Status != -2 then iccco.Serial end)
--,	FoundCount = count(distinct case when iccco.Type = 0 and iccco.Status > 0 then iccco.Serial end)
--,	RecoveredCount = count(distinct case when iccco.Type = 1 and iccco.Status > 0 then iccco.Serial end)
--,	QtyAdjustedCount = count(distinct case when iccco.Type = 0 and iccco.Status in (2, 4) then iccco.Serial end)
--,	LocationChangedCount = count(distinct case when iccco.Type = 0 and iccco.Status in (3, 4) then iccco.Serial end)
--from
--	dbo.InventoryControl_CycleCountObjects iccco
--where
--	iccco.CycleCountNumber = @CycleCountNumber

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_UpdateHeaderCounts
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
