SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_ReceivingDock_PutAwayReceiver]
(	@ReceiverID int,
	@Result int output)
as
set ansi_warnings off
set nocount on
set	@Result = 999999

--- <ErrorHandling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </ErrorHandling>

--- <Tran required=Yes autoCreate=Yes tranDTParm=No>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

/*	Delete unused receiver objects and receiver lines. */
--- <Delete rows="*">
set	@TableName = 'dbo.ReceiverObjects'

delete
	ro
from
	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl
		on rl.ReceiverLineID = ro.ReceiverLineID
where
	rl.ReceiverID = @ReceiverID
	and ro.Status = 0 --(select dbo.udf_StatusValue ('ReceiverObjects', 'New'))

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>

--- <Delete rows="*">
set	@TableName = 'dbo.ReceiverLines'

delete
	rl
from
	dbo.ReceiverLines rl
where
	rl.ReceiverID = @ReceiverID
	and rl.Status = 0 --(select dbo.udf_StatusValue ('ReceiverLines', 'New'))
	and not exists
	(	select
			*
		from
			dbo.ReceiverObjects ro
		where
			ro.ReceiverLineID = rl.ReceiverLineID
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>


/*	Set receiver status. */
--- <Update>
set	@TableName = 'dbo.ReceiverHeaders'

update
	rh
set
	Status = 5 --(select dbo.udf_StatusValue ('ReceiverHeaders', 'Put Away'))
from
	dbo.ReceiverHeaders rh
where
	ReceiverID = @ReceiverID

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, 1)
	rollback tran @ProcName
	return @Result
end
--- </Update>

--- <CloseTran required=Yes autoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran>

---	<Return success=True>
set	@Result = 0
return	@Result
--- </Return>
GO
