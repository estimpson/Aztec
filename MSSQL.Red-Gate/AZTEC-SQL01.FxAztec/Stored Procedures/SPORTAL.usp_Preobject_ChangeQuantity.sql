SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SPORTAL].[usp_Preobject_ChangeQuantity]
	@SupplierCode varchar(20)
,	@Serial int
,	@NewQuantity numeric(20,6)
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
declare
	@Exception varchar(1000)
,	@ProcedureName varchar(50)

set @ProcedureName = 'SPORTAL.usp_Preobject_ChangeQuantity'

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

	set @Exception = 'Invalid supplier code: ' + @SupplierCode	
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier code %s in procedure %s', 16, 1, @SupplierCode, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid pre-object serial. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierObjects so
			join SPORTAL.SupplierObjectBatches sob
				on sob.RowID = so.SupplierObjectBatch
		where
			sob.SupplierCode = @SupplierCode
			and so.Serial = @Serial
			and so.Status = 0
	) begin
	set	@Result = 999999

	set @Exception = 'Invalid serial: ' + @Serial	
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	RAISERROR ('Error:  Invalid serial %d in procedure %s', 16, 1, @Serial, @ProcName)
	rollback tran @ProcName
	return
end

/*	Valid quantity per object. */
if	@NewQuantity is null begin

	set @Exception = 'Invalid quantity per object (null).'	
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object (null) in procedure %s', 16, 1, @ProcName)
	rollback tran @ProcName
	return
end
if	@NewQuantity < 0 begin

	set @Exception = 'Quantity per oject cannot be less than zero.'	
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object %d in procedure %s', 16, 1, @NewQuantity, @ProcName)
	rollback tran @ProcName
	return
end
if	@NewQuantity > 100000 begin

	set @Exception = 'Quantity per object cannot be greater than 100000.'
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error:  Invalid quantity per object %d in procedure %s. 100000 maximum.', 16, 1, @NewQuantity, @ProcName)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Change the Quantity number of a serial. */
--- <Update rows="1">
set	@TableName = 'SPORTAL.SupplierObjects'

update
	so
set
	so.Quantity = @NewQuantity
from
	SPORTAL.SupplierObjects so
	join SPORTAL.SupplierObjectBatches sob
		on sob.RowID = so.SupplierObjectBatch
where
	sob.SupplierCode = @SupplierCode
	and so.Serial = @Serial

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin

	set @Exception = 'Error updating table: ' + @TableName + '.'
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin

	set @Exception = 'Error updating table: ' + @TableName + '. Rows updated: ' + @RowCount + '. Expected rows: 1.'	
	exec 
		SPORTAL.ExceptionLogInsert @ProcedureName, @Exception

	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
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
	@SupplierCode varchar(20) = 'MAR0200'
,	@Serial int = -1
,	@NewQuantity numeric(20,6) = 0

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Preobject_ChangeQuantity
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
GRANT EXECUTE ON  [SPORTAL].[usp_Preobject_ChangeQuantity] TO [SupplierPortal]
GO
