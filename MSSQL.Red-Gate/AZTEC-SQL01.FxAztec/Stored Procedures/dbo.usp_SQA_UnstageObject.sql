SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_SQA_UnstageObject]
	@OperatorCode varchar(5)
,	@Serial int
,	@FromShipperID int
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

---	</ArgumentValidation>

--- <Body>
/*	Only process boxes that have parts with Shipping Quality Alert flag. */
declare
	@part varchar(25)

set	@part =
		(	select
				o.part
			from
				dbo.object o
			where
				o.serial = @Serial
		)

if	exists
		(	select
				*
			from
				dbo.SQA_Parts sp
			where
				sp.PartCode = @part
		) begin

/*		Remove object from quality batch. */
	declare
		@ShipperQualityBatchNumber varchar(50)

	set	@ShipperQualityBatchNumber = 'SQA_' + right('0000000000' + convert(varchar, @FromShipperID), 9) + '_' + @part
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_QualityBatch_RemoveObject'
	execute
		@ProcReturn = dbo.usp_InventoryControl_QualityBatch_RemoveObject
			@User = @OperatorCode
		,	@QualityBatchNumber = @ShipperQualityBatchNumber
		,	@Serial = @Serial
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
	
	/*	Adjust sort count. */
	--- <Update rows="1">
	set	@TableName = 'dbo.InventoryControl_QualityBatchHeaders'
		
	update
		icqbh
	set
		SortCount =
			(	select
					SortCount = count(*)
				from
					dbo.InventoryControl_QualityBatchObjects icqbo
				where
					icqbo.QualityBatchNumber = @ShipperQualityBatchNumber
			)
	,	Type = 2 --(select dbo.udf_TypeValue('dbo.InventoryControl_QualityBatchHeaders', 'SQA'))
	from
		dbo.InventoryControl_QualityBatchHeaders icqbh
	where
		icqbh.QualityBatchNumber = @ShipperQualityBatchNumber
		
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
	
/*		Set object status back to approved. */
	--- <Call>
	set	@CallProcName = 'dbo.usp_InventoryControl_Quality'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Quality
			@User = @OperatorCode
		,	@Serial = @Serial
		,	@NewUserDefinedStatus = 'Approved'
		,	@Notes = 'Removed from shipper.'
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
	if	@ProcResult not in (0, 100) begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end
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
	@ProcReturn = dbo.usp_SQA_UnstageObject
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
