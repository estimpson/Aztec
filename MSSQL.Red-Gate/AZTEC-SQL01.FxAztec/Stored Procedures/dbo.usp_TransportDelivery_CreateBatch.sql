SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_TransportDelivery_CreateBatch]
	@FirstDepartureDT datetime
,	@DeliveryCount smallint
,	@TransportDays smallint
,	@DeparturePlant varchar(20)
,	@ArrivalPlant varchar(20)
,	@Carrier varchar(4)
,	@TransportMode varchar(2)
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
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Create a batch of deliveries. */
alter table
	dbo.TransportDeliveries drop constraint UQ_TransportDeliveries_DeliveryNumber

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error disabling unique constraint on table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end

--- <Insert rows="n">
set	@TableName = 'dbo.TransportDeliveries'

insert
	dbo.TransportDeliveries
(	DeliveryNumber
,	DeparturePlant
,	ArrivalPlant
,	Carrier
,	TransportMode
,	ScheduledDepartureDT
,	ScheduledArrivalDT
)
select
	DeliveryNumber = '0'
,	DeparturePlant = @DeparturePlant
,	ArrivalPlant = @ArrivalPlant
,	Carrier = @Carrier
,	TransportMode = @TransportMode
,	ScheduledDepartureDT = dateadd(week, urDeliveries.RowNumber - 1, @FirstDepartureDT)
,	ScheduledArrivalDT = dateadd(week, urDeliveries.RowNumber - 1, @FirstDepartureDT + @TransportDays)
from
	dbo.udf_Rows(@DeliveryCount) urDeliveries

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @DeliveryCount begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

alter table
	dbo.TransportDeliveries add constraint UQ_TransportDeliveries_DeliveryNumber unique (DeliveryNumber)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error enabling unique constraint on table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
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
	@ProcReturn = dbo.usp_TransportDelivery_CreateBatch
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
