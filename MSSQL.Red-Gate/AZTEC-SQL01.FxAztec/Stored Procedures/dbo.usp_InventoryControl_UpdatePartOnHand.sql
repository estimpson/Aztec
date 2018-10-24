SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[usp_InventoryControl_UpdatePartOnHand]
	@PartCode varchar(25)
,	@TranDT datetime out
,	@Result integer out
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
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
if	@PartCode is not null
	and not exists
		(	select
				*
			from
				dbo.part p
			where
				p.part = @PartCode
		) begin

	---	<CloseTran AutoCommit=Yes>
	if	@TranCount = 0 begin
		commit tran @ProcName
	end
	---	</CloseTran AutoCommit=Yes>
	set	@Result = 100
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Update part on hand. (uiN) */
declare
	@expectedRowCount int

set @expectedRowCount =
		case
			when @PartCode is not null then 1
			else
				(	select
						count(*)
					from
						dbo.part_online
				)
		end

--- <Update rows="N">
set	@TableName = 'dbo.part_online'

update
	po
set
	on_hand = dbo.udf_GetPartQtyOnHand(po.part)
from
	dbo.part_online po
where
	po.part = coalesce(@PartCode, po.part)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @expectedRowCount
	or	@PartCode is null begin
	--- <Insert rows="*">
	set	@TableName = 'dbo.part_online'
	
	insert
		dbo.part_online
	(
		part
	,   on_hand
	)
	select
		part = p.part
	,   on_hand = dbo.udf_GetPartQtyOnHand(p.part)
	from
		dbo.part p
	where
		p.part = coalesce(@PartCode, p.part)
		and not exists
			(	select
					*
				from
					dbo.part_online po
				where
					po.part = p.part
			)
	
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
	@ProcReturn = dbo.usp_InventoryControl_UpdatePartOnHand
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
