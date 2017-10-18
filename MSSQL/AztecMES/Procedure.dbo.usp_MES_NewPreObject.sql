
/*
Create procedure fx21stPilot.dbo.usp_MES_NewPreObject
*/

--use fx21stPilot
--go

if	objectproperty(object_id('dbo.usp_MES_NewPreObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_NewPreObject
end
go

create procedure dbo.usp_MES_NewPreObject
	@Operator varchar (10)
,	@WODID int
,	@QtyToLabel numeric(20,6)
,	@QtyBox int
,	@PackageCode varchar(25)
,	@LotNumber varchar(20)
,	@FirstNewSerial int out
,	@Boxes int out
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
/*	Operator required:  */
if	not exists
	(	select
			1
		from
			employee
		where
			operator_code = @Operator
	) begin

	set @Result = 60001
	RAISERROR ('Invalid operator code %s in procedure %s.  Error: %d', 16, 1, @Operator, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	WOD ID must be valid:  */
declare	@Part varchar (25)
select
	@Part =	PartCode
from
	dbo.WorkOrderDetails wod
where
	RowID = @WODID

if	@@RowCount != 1 or @@Error != 0 begin
	
	set	@Result = 200101
	RAISERROR ('Invalid job id %d in procedure %s.  Error: %d', 16, 1, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	Part valid:  */
if	not exists
	(	select	1
		from	part
		where	part = @Part) begin

	set	@Result = 70001
	RAISERROR ('Invalid part %s for job id %d in procedure %s.  Error: %d', 16, 1, @Part, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
declare
	@Status char(1)
,	@UserStatus varchar(10)
,	@ObjectType char(1)
,	@TranType char(1)
,	@Remark varchar(10)
,	@Notes varchar(50)
,	@AssemblyPreObjectLocation varchar(10)

set	@Status = 'H'
set	@UserStatus = 'PRESTOCK'
set	@ObjectType = null
set	@TranType = 'P'
set	@Remark = 'PRE-OBJECT'
set	@Notes = 'Pre-object.'
set	@AssemblyPreObjectLocation = 'PRE-OBJECT'

/*	Get block of serial numbers for pre-objects. */
set	@Boxes = ceiling(@QtyToLabel / @QtyBox)
--- <Call>	
set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
		@SerialBlockSize = @Boxes
	,	@FirstNewSerial = @FirstNewSerial out
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

/*	Create new object(s). */
--- <Insert rows="n">
set	@TableName = 'dbo.object'

insert
	dbo.object
(	serial
,	part
,	location
,	last_date
,	unit_measure
,	operator
,	status
,	quantity
,	lot
,	plant
,	std_quantity
,	package_type
,	last_time
,	user_defined_status
,	type
,	workorder
)
select
	@FirstNewSerial + r.RowNumber - 1
,	@Part
,	l.code
,	@TranDT
,	pi.standard_unit
,	@Operator
,	@Status
,	case when r.RowNumber = @Boxes and @QtyToLabel % @QtyBox != 0 then @QtyToLabel % @QtyBox else @QtyBox end -- Put remainder on final box.
,	lot = @LotNumber
,	l.plant
,	case when r.RowNumber = @Boxes and @QtyToLabel % @QtyBox != 0 then @QtyToLabel % @QtyBox else @QtyBox end
,	package_type = @PackageCode
,	@TranDT
,	@UserStatus
,	@ObjectType
,	@WODID
from
	dbo.part_inventory pi
	join dbo.location l
		on l.code = @AssemblyPreObjectLocation
	cross join dbo.udf_Rows(@Boxes) r
where
	pi.part = @Part

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @Boxes begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @Boxes)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Create new audit trail.  */
--- <Insert rows="n">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(	serial
,	date_stamp
,	type
,	part
,	quantity
,	remarks
,	operator
,	from_loc
,	to_loc
,	lot
,	weight
,	status
,	unit
,	std_quantity
,	plant
,	notes
,	package_type
,	std_cost
,	user_defined_status
,	tare_weight
,	workorder
)	
select
	o.serial
,	o.last_date
,	@TranType
,	o.part
,	o.quantity
,	@Remark
,	o.operator
,	o.location
,	o.location
,	o.lot
,	o.weight
,	o.status
,	o.unit_measure
,	o.std_quantity
,	o.plant
,	@Notes
,	o.package_type
,	o.cost
,	o.user_defined_status
,	o.tare_weight
,	o.workorder
from
	dbo.object o
where
	o.serial between @FirstNewSerial and @FirstNewSerial + @Boxes - 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @Boxes begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @Boxes)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Create new pre-object history.  */
--- <Insert rows="n">
set	@TableName = 'dbo.WorkOrderObjects'

insert
	dbo.WorkOrderObjects
(	WorkOrderNumber
,	WorkOrderDetailLine
,	Serial
,	PartCode
,	OperatorCode
,	Quantity
,	PackageType
,	LotNumber
)
select
	WorkOrderNumber = wod.WorkOrderNumber
,	WorkOrderDetailLine = wod.Line
,	Serial = o.serial
,	PartCode = o.part
,	OperatorCode = o.operator
,	Quantity = o.std_quantity
,	PackageType = o.package_type
,	LotNumber = o.lot
from
    dbo.object o
    join dbo.WorkOrderDetails wod
		on wod.RowID = @WODID
where
    o.serial between @FirstNewSerial and @FirstNewSerial + @Boxes - 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @Boxes begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @Boxes)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Update quantity printed.  */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set	QtyLabelled = QtyLabelled + @QtyToLabel
from
	dbo.WorkOrderDetails wod
where
	wod.RowID = @WODID

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

/*	Set the job status to running. */
if	exists
	(	select
			*
		from
			dbo.WorkOrderHeaders woh
			join dbo.WorkOrderDetails wod
				on wod.WorkOrderNumber = woh.WorkOrderNumber
				and wod.RowID = @WODID
		where
			woh.Status in
			(	select
	 				sd.StatusCode
	 			from
	 				FT.StatusDefn sd
	 			where
	 				sd.StatusTable = 'dbo.WorkOrderHeaders'
	 				and sd.StatusName = 'New'
			)
	) begin
	
	--- <Update rows="1">
	set	@TableName = 'dbo.WorkOrderHeaders'
	
	update
		woh
	set
		Status =
			(	select
	 				sd.StatusCode
	 			from
	 				FT.StatusDefn sd
	 			where
	 				sd.StatusTable = 'dbo.WorkOrderHeaders'
	 				and sd.StatusName = 'Running'
			)
	from
		dbo.WorkOrderHeaders woh
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = woh.WorkOrderNumber
			and wod.RowID = @WODID

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
	
	--- <Update rows="1">
	set	@TableName = 'dbo.WorkOrderDetails'
	
	update
		wod
	set
		Status =
			(	select
	 				sd.StatusCode
	 			from
	 				FT.StatusDefn sd
	 			where
	 				sd.StatusTable = 'dbo.WorkOrderDetails'
	 				and sd.StatusName = 'Running'
			)
	from
		dbo.WorkOrderDetails wod
	where
		wod.RowID = @WODID
	
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
end

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

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
	@Operator varchar (10)
,	@WODID int
,	@QtyToLabel numeric(20,6)
,	@QtyBox int
,	@PackageCode varchar(25)
,	@FirstNewSerial int
,	@Boxes int

set	@Operator = 'mon'
set @WODID = 189
set @QtyToLabel = 10
set @QtyBox = 8
set @PackageCode = 'NUS-22'
set @Boxes = 2

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_NewPreObject
	@Operator = @Operator
,	@WODID = @WODID
,	@QtyToLabel = @QtyToLabel
,	@QtyBox = @QtyBox
,	@PackageCode = @PackageCode
,	@FirstNewSerial = @FirstNewSerial out
,	@Boxes = @Boxes out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@FirstNewSerial, @Boxes, @Error, @ProcReturn, @TranDT, @ProcResult

select
	o.*
from
	dbo.object o
where
	o.serial between @FirstNewSerial and @FirstNewSerial + @Boxes - 1

select
	at.*
from
	dbo.audit_trail at
where
	at.serial between @FirstNewSerial and @FirstNewSerial + @Boxes - 1

select
	p.next_serial
from
	dbo.parameters p

exec dbo.usp_MES_GetJobList
go

--commit
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

