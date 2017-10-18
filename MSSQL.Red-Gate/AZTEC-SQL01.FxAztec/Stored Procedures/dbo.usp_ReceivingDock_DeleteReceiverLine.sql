SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_DeleteReceiverLine]
(	@ReceiverLineID int,
	@Result int output)
as
/*

begin tran Test
execute	dbo.usp_ReceivingDock_DeleteReceiverLine
	@ReceiverLineID = 3,
	@Result = 0
	
select	*
from	ReceiverLines
where	ReceiverLineID = 3

select	*
from	ReceiverObjects
where	ReceiverLineID = 3

--commit
rollback tran

*/
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes>
declare	@TranCount smallint
set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
--- </Tran>

--	I.	Delete boxes not yet received and lines with no receipts.
delete
	dbo.ReceiverObjects
from
	dbo.ReceiverObjects ro
where
	ro.ReceiverLineID = @ReceiverLineID
and
	ro.ReceiveDT is null

update
	dbo.ReceiverLines
set
	RemainingBoxes = 0,
	Status = 4
from
	dbo.ReceiverLines rl
where
	rl.ReceiverLineID = @ReceiverLineID
and
	exists
	(	select
			*
		from
			dbo.ReceiverObjects ro
		where
			ReceiverLineID = @ReceiverLineID)

delete
	dbo.ReceiverLines
where
	ReceiverLines.ReceiverLineID = @ReceiverLineID
and
	not exists
	(	select
			*
		from
			dbo.ReceiverObjects ro
		where
			ReceiverLineID = @ReceiverLineID)

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

--	II.	Return.
set	@Result = 0
return	@Result
GO
