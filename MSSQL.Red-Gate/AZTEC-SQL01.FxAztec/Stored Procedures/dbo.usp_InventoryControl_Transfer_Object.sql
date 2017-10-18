SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_InventoryControl_Transfer_Object]
	@Operator varchar(5)
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@TranDT datetime out
,	@Result integer out
,	@Debug integer = 0
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
	@RowCount integer,
	@FirstNewSerial integer

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
-- Valid operator.
if	not exists
	(	select	1
		from	employee
		where	operator_code = @Operator) begin

	set	@Result = 60001
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Operator %s not found.', 16, 1, @ProcName, @Operator)
	return	@Result
end

-- Serial exists.
if not exists
	(	select	1 
		from	object
		where	serial = @Serial) begin
	
	set	@Result = 60002
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Serial %d not found.', 16, 1, @ProcName, @Serial)
	return	@Result
end
---	</ArgumentValidation>


--- <Body>
--- Determine object type
if exists 
	(	select	1
		from	object o
		where	o.serial = @Serial
				and o.type = 'S') begin
	
	--- <Update location of pallet and boxes on pallet, create transfer records>
	set			@CallProcName = 'dbo.usp_InventoryControl_Transfer_Pallet'
	execute		@ProcReturn = dbo.usp_InventoryControl_Transfer_Pallet
				@Operator = @Operator,
				@PalletSerial = @Serial,
				@Location = @Location,
				@Notes = @Notes,
				@TranDT = @TranDT out,
				@Result = @ProcResult out
	       
	set @Error = @@Error
	if @Error != 0 begin
		set	@Result = 900501
		if	@Debug != 0 begin
			RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		end
		rollback tran @ProcName
		return @Result
	end
	if @ProcResult != 0 begin
		set	@Result = 900502
		if	@Debug != 0 begin
			RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		end
		rollback tran @ProcName
		return	@Result
	end
	--- </Update location of pallet and boxes on pallet, create transfer records>	
end

else begin
	--- <Update location of box, create transfer record>
	set			@CallProcName = 'dbo.usp_InventoryControl_Transfer_Box'
	execute		@ProcReturn = dbo.usp_InventoryControl_Transfer_Box
				@Operator = @Operator,
				@Serial = @Serial,
				@Location = @Location,
				@Notes = @Notes,
				@TranDT = @TranDT out,
				@Result = @ProcResult out
	       
	set @Error = @@Error
	if @Error != 0 begin
		set	@Result = 900503
		if	@Debug != 0 begin
			RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		end
		rollback tran @ProcName
		return @Result
	end
	if @ProcResult != 0 begin
		set	@Result = 900504
		if	@Debug != 0 begin
			RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		end
		rollback tran @ProcName
		return	@Result
	end
	--- </Update location of box, create transfer record>
end
--- </Body>



--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	Success.
set	@Result = 0
return
	@Result


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
	@Operator varchar(5) = 'RCR'
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@TranDT datetime out
,	@Result integer out

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_JobComplete
	@Operator = @Operator
,	@Serial int
,	@Location varchar(10)
,	@Notes varchar(254) = null
,	@TranDT datetime out
,	@Result integer out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.audit_trail at
where
	at.serial = @Serial

select
	*
from
	dbo.BackflushHeaders bh
where
	bh.SerialProduced = @NewSerial

select
	*
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = (select bh.BackflushNumber from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)

select
	*
from
	dbo.audit_trail at
where
	at.serial in
		(	select
				bd.SerialConsumed
			from
				dbo.BackflushDetails bd
			where
				bd.BackflushNumber = (select bh.BackflushNumber from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)
		)
	and at.type = 'M'
	and at.date_stamp = (select bh.TranDT from dbo.BackflushHeaders bh where bh.SerialProduced = @NewSerial)
go

select
	*
from
	FT.SPLogging
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
