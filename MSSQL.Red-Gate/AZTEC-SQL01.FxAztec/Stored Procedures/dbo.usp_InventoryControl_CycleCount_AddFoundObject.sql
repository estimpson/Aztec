SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_CycleCount_AddFoundObject]
	@User varchar(10)
,	@CycleCountNumber varchar(50)
,	@Serial int
,	@Quantity numeric(20,6)
,	@Location varchar(10)
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

/*	Add recovered serial to cycle count objects. */
--- <Insert rows="1">
set	@TableName = 'dbo.CycleCountHeaders'

insert
	dbo.InventoryControl_CycleCountObjects
(	CycleCountNumber
,	Line
,	Status
,	Type
,	Serial
,	Part
,	OriginalQuantity
,	CorrectedQuantity
,	Unit
,	OriginalLocation
,	CorrectedLocation
)
select
	CycleCountNumber = @CycleCountNumber
,	Line = coalesce(icco.MaxLine, 0) + 1
,	Status = case when icccgsi.Recover = 1 then 5 else 1 end
,	Type = icccgsi.Recover
,	Serial
,	Part
,	OriginalQuantity = icccgsi.Quantity
,	CorrectedQuantity = @Quantity
,	Unit
,	OriginalLocation = icccgsi.Location
,	CorrectedLocation = @Location
from
	dbo.InventoryControl_CycleCount_GetSerialInfo(@Serial) icccgsi
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
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Update cycle count counts.*/
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_UpdateHeaderCounts'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_UpdateHeaderCounts
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>
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
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_AddFoundObject
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
GO
