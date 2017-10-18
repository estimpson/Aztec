SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ReceivingDock_PutAwaySerial]
	@User varchar(5)
,	@ReceiverNumber varchar(50)
,	@PutAwaySerial int
,	@PutAwayLocation varchar(10)
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
/*	Validate receiver number / serial. */
declare
	@receiverObjectIDs table
(	receiverObjectID int
)

insert
	@receiverObjectIDs
select
	ro.ReceiverObjectID
from
	dbo.ReceiverObjects ro
	join dbo.ReceiverLines rl
		on rl.ReceiverLineID = ro.ReceiverLineID
	join dbo.ReceiverHeaders rh
		on rh.ReceiverID = rl.ReceiverID
	left join dbo.part p
		on p.part = ro.PartCode
where
	rh.ReceiverNumber = @ReceiverNumber
	and
	(	ro.Serial = @PutAwaySerial
		or ro.Serial in
			(	select
					o.serial
				from
					dbo.object o
				where
					o.parent_serial = @PutAwaySerial
			)
	)

if	@@rowcount is null begin
	set @Result = 999999
	RAISERROR ('Error encountered in %s.  Validation: Serial %d invalid for receiver %s.', 16, 1, @ProcName, @PutAwaySerial, @ReceiverNumber)
	rollback tran @ProcName
	return @Result
end
---	</ArgumentValidation>

--- <Body>
/*	Set location of Receiver Object. */
--- <Update rows="1+">
set	@TableName = 'dbo.ReceiverObjects'

update
	ro
set
	Location = @PutAwayLocation
from
	dbo.ReceiverObjects ro
where
	ro.ReceiverObjectID in
		(	select
				receiverObjectID
			from
				@receiverObjectIDs
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount !> 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1+.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Determine if receipt is required for the specified serial. */
if	exists
	(	select
			*
		from
			dbo.ReceiverObjects ro
		where
			ro.ReceiverObjectID in
				(	select
						receiverObjectID
					from
						@receiverObjectIDs
				)
			and ro.Status = 0 --(select dbo.udf_StatusValue ('ReceiverObjects', 'New'))
	) begin

	declare receiverObjects cursor local for
	select
		ro.ReceiverObjectID
	from
		dbo.ReceiverObjects ro
	where
		ro.ReceiverObjectID in
			(	select
					receiverObjectID
				from
					@receiverObjectIDs
			)
		and ro.Status = 0 --(select dbo.udf_StatusValue ('ReceiverObjects', 'New'))

	open receiverObjects

	while
		1 = 1 begin
		
		declare
			@receiverObjectID int
		
		fetch
			receiverObjects
		into
			@receiverObjectID
			
		if	@@FETCH_STATUS != 0 begin
			break
		end
        
		--- <Call>	
		set	@CallProcName = 'dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject'
		execute
			@ProcReturn = dbo.usp_ReceivingDock_ReceiveObject_againstReceiverObject
				@User = @User
			,	@ReceiverObjectID = @receiverObjectID
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
	end
end

/*	Perform transfer to put-away location. */
if	(	select
  			o.type
  		from
  			dbo.object o
		where
			o.serial = @PutAwaySerial
  	) = 'S' begin

	if  not exists
			(	select
					*
				from
					dbo.object o
				where
					o.serial = @PutAwaySerial
					and o.location = @PutAwayLocation
			) begin
		
		
		--- <Call>	
		set	@CallProcName = 'dbo.usp_InventoryControl_Transfer_Pallet'
		execute
			@ProcReturn = dbo.usp_InventoryControl_Transfer_Pallet
				@Operator = @User
			,	@PalletSerial = @PutAwaySerial
			,	@Location = @PutAwayLocation
			,	@Notes = 'Put-away during receiving'
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
		          
    end
end  
else begin  
	if	not exists
			(	select
					*
				from
					dbo.object o
				where
					o.serial = @PutAwaySerial
					and o.location = @PutAwayLocation
			) begin
      
		--- <Call>	
		set	@CallProcName = 'dbo.usp_InventoryControl_Transfer_Box'
		execute
			@ProcReturn = dbo.usp_InventoryControl_Transfer_Box
				@Operator = @User
			,	@Serial = @PutAwaySerial
			,	@Location = @PutAwayLocation
			,	@Notes = 'Put-away during receiving'
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
	end
	--- </Body>
end

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
	@ProcReturn = dbo.usp_ReceivingDock_PutAwaySerial
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
