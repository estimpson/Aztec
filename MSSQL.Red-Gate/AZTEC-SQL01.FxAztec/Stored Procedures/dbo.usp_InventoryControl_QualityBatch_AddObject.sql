SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_QualityBatch_AddObject]
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int = null
,	@NewUserDefinedStatus varchar(30) = null
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
set	@TableName = 'dbo.QualityBatchHeaders'

insert
	dbo.InventoryControl_QualityBatchObjects
(	QualityBatchNumber
,	Line
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalStatus
)
select
	QualityBatchNumber = @QualityBatchNumber
,	Line = coalesce(icqbo.MaxLine, 0) + row_number() over (order by qbo.RowID, qbo.Serial)
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalStatus
from
	(	select
			RowID = sl.RowID
		,	Serial = sl.serial
		,	Part = o.part
		,	OriginalQuantity = o.std_quantity
		,	Unit = pi.standard_unit
		,	OriginalStatus = o.user_defined_status
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
	) qbo
	left join
	(	select
			MaxLine = max(Line)
		from
			dbo.InventoryControl_QualityBatchObjects icqbo
		where
			QualityBatchNumber = @QualityBatchNumber
	) icqbo on 1 = 1

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

/*	Set the status of the object to hold. */
declare
	@holdStatus varchar(30)

select
	@holdStatus = coalesce(@NewUserDefinedStatus, uds.display_name)
from
	dbo.user_defined_status uds
where
	uds.type = 'H'
	and uds.base = 'Y'

declare
	@batchDescription varchar(max)

select
	@batchDescription = icqbh.Description
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
where
	icqbh.QualityBatchNumber = @QualityBatchNumber

--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_Quality'
execute
	@ProcReturn = dbo.usp_InventoryControl_Quality
		@User = @User
	,	@Serial = @Serial
	,	@NewUserDefinedStatus = @holdStatus
	,	@Notes = @batchDescription
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
if	@ProcResult not in (0, 100) begin
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
,	@QualityBatchNumber varchar(50)
,	@Serial int = null

set	@User = 'mon'
set	@QualityBatchNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_AddObject
	@User = @User
,	@QualityBatchNumber = @QualityBatchNumber
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
