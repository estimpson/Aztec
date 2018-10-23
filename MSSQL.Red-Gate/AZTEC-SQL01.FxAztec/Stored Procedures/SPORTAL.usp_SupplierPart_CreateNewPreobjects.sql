SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SPORTAL].[usp_SupplierPart_CreateNewPreobjects]
	@SupplierCode varchar(20)
,	@SupplierPartCode varchar(50)
,	@InternalPartCode varchar(25)
,	@QuantityPerObject numeric(20,6)
,	@ObjectCount int
,	@LotNumber varchar(100)
,	@FirstNewSerial int out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SPORTAL.usp_Test
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
/*	Valid supplier code. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierList sl
		where
			sl.SupplierCode = @SupplierCode
			and sl.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier code %s in procedure %s', 16, 1, @SupplierCode, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid supplier part. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierPartList spl
		where
			spl.SupplierCode = @SupplierCode
			and spl.SupplierPartCode = @SupplierPartCode
			and spl.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier part code %s in procedure %s', 16, 1, @SupplierPartCode, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid internal part. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierPartList spl
		where
			spl.SupplierCode = @SupplierCode
			and spl.SupplierPartCode = @SupplierPartCode
			and spl.InternalPartCode = @InternalPartCode
			and spl.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid internal part code %s in procedure %s', 16, 1, @InternalPartCode, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid quantity per object. */
if	@QuantityPerObject is null begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object (null) in procedure %s', 16, 1, @ProcName)
	rollback tran @ProcName
	return
end
if	@QuantityPerObject < 0 begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object %d in procedure %s', 16, 1, @QuantityPerObject, @ProcName)
	rollback tran @ProcName
	return
end
if	@QuantityPerObject > 100000 begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object %d in procedure %s', 16, 1, @QuantityPerObject, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid object count. */
if	@ObjectCount is null begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid object count (null) in procedure %s', 16, 1, @ProcName)
	rollback tran @ProcName
	return
end
if	@ObjectCount < 0 begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid object count %d in procedure %s', 16, 1, @ObjectCount, @ProcName)
	rollback tran @ProcName
	return
end
if	@ObjectCount > 100 begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid object count %d in procedure %s', 16, 1, @ObjectCount, @ProcName)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Get block of serial numbers for pre-objects. */
--- <Call>	
set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
		@SerialBlockSize = @ObjectCount
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

/*	Create supplier pre-object batch.*/
--- <Insert rows="1">
set	@TableName = 'SPORTAL.SupplierObjectBatches'

insert
	SPORTAL.SupplierObjectBatches
(	SupplierCode
,	SupplierPartCode
,	InternalPartCode
,	QuantityPerObject
,	ObjectCount
,	LotNumber
,	FirstSerial
)
select
	SupplierCode = spl.SupplierCode
,	SupplierPartCode = spl.SupplierPartCode
,	InternalPartCode = spl.InternalPartCode
,	QuantityPerObject = @QuantityPerObject
,	ObjectCount = @ObjectCount
,	LotNumber = @LotNumber
,	FirstSerial = @FirstNewSerial
from
	SPORTAL.SupplierPartList spl
where
	spl.SupplierCode = @SupplierCode
	and spl.SupplierPartCode = @SupplierPartCode
	and spl.InternalPartCode = @InternalPartCode
	and spl.Status = 0

select
	@Error = @@error
,	@RowCount = @@rowcount

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

declare
	@SupplierObjectBatch int = scope_identity()
--- </Insert>

/*	Create supplier pre-objects.*/
--- <Insert rows="n">
set	@TableName = 'SPORTAL.SupplierObjects'

insert
	SPORTAL.SupplierObjects
(	Serial
,	SupplierObjectBatch
,	Quantity
,	LotNumber
)
select
	Serial = NewSerials.Serial
,	SupplierObjectBatch = @SupplierObjectBatch
,	Quantity = @QuantityPerObject
,	LotNumber = @LotNumber
from
	SPORTAL.SupplierPartList spl
	cross apply
		(	select
				Serial = @FirstNewSerial + ur.RowNumber - 1
			from
				dbo.udf_Rows(@ObjectCount) ur
		) NewSerials
where
	spl.SupplierCode = @SupplierCode
	and spl.SupplierPartCode = @SupplierPartCode
	and spl.InternalPartCode = @InternalPartCode
	and spl.Status = 0

select
	@Error = @@error
,	@RowCount = @@rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @ObjectCount begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @ObjectCount)
	rollback tran @ProcName
	return
end
--- </Insert>
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
	@SupplierCode varchar(20) = 'MAR0200'
,	@SupplierPartCode varchar(50) = '12311 - 0V170'
,	@InternalPartCode varchar(25) = '3246 - OP5'
,	@QuantityPerObject numeric(20,6) = 200
,	@ObjectCount int = 10
,	@LotNumber varchar(100) = 'TEST'
,	@FirstNewSerial int

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_SupplierPart_CreateNewPreobjects
	@SupplierCode = @SupplierCode
,	@SupplierPartCode = @SupplierPartCode
,	@InternalPartCode = @InternalPartCode
,	@QuantityPerObject = @QuantityPerObject
,	@ObjectCount = @ObjectCount
,	@LotNumber = @LotNumber
,	@FirstNewSerial = @FirstNewSerial out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @FirstNewSerial, @TranDT, @ProcResult

execute
	@ProcReturn = SPORTAL.usp_Preobject_ChangeLot
	@SupplierCode = @SupplierCode
,	@Serial = @FirstNewSerial
,	@NewLot = 'TEST1'

execute
	SPORTAL.usp_Q_Lots_BySupplier
	@SupplierCode = @SupplierCode

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierLot
	@SupplierCode = @SupplierCode
,	@LotNumber = @LotNumber

execute
	@ProcReturn = SPORTAL.usp_Preobject_ChangeQuantity
	@SupplierCode = @SupplierCode
,	@Serial = @FirstNewSerial
,	@NewQuantity = 4
,	@TranDT = @TranDT out

execute
	@ProcReturn = SPORTAL.usp_Q_SerialObjectBatches_BySupplier
	@SupplierCode = @SupplierCode

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierBatch
	@SupplierCode = @SupplierCode
,	@FirstSerial = @FirstNewSerial

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierSerialList
	@SupplierCode = @SupplierCode
,	@SerialList = @FirstNewSerial
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
GRANT EXECUTE ON  [SPORTAL].[usp_SupplierPart_CreateNewPreobjects] TO [SupplierPortal]
GO
