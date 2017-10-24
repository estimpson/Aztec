
/*
Create Procedure.FxAztec.SPORTAL.usp_Q_Preobjects_ByAnyMethod.sql
*/

use FxAztec
go

if	objectproperty(object_id('SPORTAL.usp_Q_Preobjects_ByAnyMethod'), 'IsProcedure') = 1 begin
	drop procedure SPORTAL.usp_Q_Preobjects_ByAnyMethod
end
go

create procedure SPORTAL.usp_Q_Preobjects_ByAnyMethod
	@SupplierCode varchar(20)
,	@FirstSerial varchar(12) = '' -- 'Leave empty or pass first serial for batch.
,	@LotNumber varchar(100) = ''  -- 'Leave empty or provide lot number.
,	@SerialList varchar(max) = ''  -- 'Leave empty or supply list of serials.
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

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
/*	Validate supplier code. */
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
	--rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Look for first serial. */
if	@FirstSerial > '' begin

	--- <Call>	
	set	@CallProcName = 'SPORTAL.usp_Q_Preobjects_BySupplierBatch'

	execute @ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierBatch
			@SupplierCode = @SupplierCode
		,	@FirstSerial = @FirstSerial
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
/*	Look for lot number. */
else if
	@LotNumber > '' begin

	--- <Call>	
	set	@CallProcName = 'SPORTAL.usp_Q_Preobjects_BySupplierLot'

	execute @ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierLot
			@SupplierCode = @SupplierCode
		,	@LotNumber = @LotNumber
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
/*	Look for serial list. */
else if
	@SerialList > '' begin

	--- <Call>	
	set	@CallProcName = 'SPORTAL.usp_Q_Preobjects_BySupplierSerialList'

	execute @ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierSerialList
			@SupplierCode = @SupplierCode
		,	@SerialList = @SerialList
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
/*	Default to all objects for supplier. */
else begin
	--- <Call>	
	set	@CallProcName = 'SPORTAL.usp_Q_Preobjects_BySupplier'

	execute @ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplier
			@SupplierCode = @SupplierCode
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
,	@FirstSerial varchar(12) = '' -- 'Leave empty or pass first serial for batch.
,	@LotNumber varchar(100) = ''  -- 'Leave empty or provide lot number.
,	@SerialList varchar(max) = ''  -- 'Leave empty or supply list of serials.

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_ByAnyMethod
	@SupplierCode = @SupplierCode
,	@FirstSerial = @FirstSerial
,	@LotNumber = @LotNumber
,	@SerialList = @SerialList
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
go

