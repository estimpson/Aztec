
/*
Create Procedure.Fx.dbo.usp_SQA_StageObject.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_SQA_StageObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_SQA_StageObject
end
go

create procedure dbo.usp_SQA_StageObject
	@OperatorCode varchar(5)
,	@Serial int
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
declare
	@notificationFlag bit = 0

/*	Only process boxes that have parts with Shipping Quality Alert flag.*/
declare
	@part varchar(25)
,	@shipperID int

select
	@part = o.part
,	@shipperID = o.shipper
from
	dbo.object o
where
	o.serial = @Serial

if	exists
		(	select
				*
			from
				dbo.SQA_Parts sp
			where
				sp.PartCode = @part
				and sp.Status >= 0
		) begin

/*		Determine if quality alert already exists. */
	declare
		@ShipperQualityBatchNumber varchar(50)

	set	@ShipperQualityBatchNumber = 'SQA_' + right('0000000000' + convert(varchar, @shipperID), 9) + '_' + @part

	if	not exists
		(	select
				*
			from
				dbo.InventoryControl_QualityBatch_Headers icqbh
			where
				icqbh.QualityBatchNumber = @ShipperQualityBatchNumber
		) begin
       
		--- <Call?
		declare
			@Description varchar(255)
		
		set	@Description = 'Shipping Qualityer Alert (' + @ShipperQualityBatchNumber + ')'

		set	@CallProcName = 'dbo.usp_InventoryControl_QualityBatch_NewHeader'
		execute
			@ProcReturn = dbo.usp_InventoryControl_QualityBatch_NewHeader 
				@User = @OperatorCode
			,	@Description = @Description
			,	@QualityBatchNumber = @ShipperQualityBatchNumber
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

	/*	Determine if notification is required (quality batch hasn't started or is already completed and this line item is ready to ship). */
	set	@notificationFlag =
			case
				when exists
					(	select
							*
						from
							dbo.InventoryControl_QualityBatchHeaders icqbh
							join dbo.shipper_detail sd
								on sd.shipper = @shipperID
								and sd.part_original = @part
						where
							icqbh.QualityBatchNumber = @ShipperQualityBatchNumber
							and icqbh.Status in (0, 2)
							and sd.qty_required <=
								(	select
										sum(std_quantity)
									from
										dbo.object o
									where
										o.shipper = @shipperID
										and o.part = @part
								)
					) then 1
				else 0
			end
    
	/*	Add box to quality batch. */ 
	--- <Call>
	set	@CallProcName = 'dbo.usp_InventoryControl_QualityBatch_AddObject'
	execute
		@ProcReturn = dbo.usp_InventoryControl_QualityBatch_AddObject
			@User = @OperatorCode
		,	@QualityBatchNumber = @ShipperQualityBatchNumber
		,	@Serial = @Serial
		,	@NewUserDefinedStatus = 'SQA Hold'
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

	/*	Reopen a closed sort. Open when alerting. */
	--- <Update rows="1">
	set	@TableName = 'dbo.InventoryControl_QualityBatchHeaders'
		
	update
		icqbh
	set
		Status = case when icqbh.Status = 2 then 1 when @notificationFlag = 1 then 1 else icqbh.Status end
    ,	SortEndDT = null
    ,	SortCount =
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
	
end

/*	Send notification if required. */
if	@notificationFlag = 1 begin
	--- <Call>	
	set	@CallProcName = 'custom.usp_SQA_StagedShipmentNotificationNotice'
	execute
		@ProcReturn = custom.usp_SQA_StagedShipmentNotificationNotice
			@ShipperQualityBatchNumber = @ShipperQualityBatchNumber
		,	@NotificationPart = @part
		,	@TranDT = @TranDT out
		,	@Result = @ProcResult out
        ,	@Email = 1
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		print 'Error'
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		print 'Proc Return'
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		print 'Proc Result'
		return	@Result
	end
	--- </Call>
end
--- </Body>

select
	*
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
		join dbo.InventoryControl_QualityBatchObjects icqbo
			on icqbh.QualityBatchNumber = icqbo.QualityBatchNumber
where
	icqbh.QualityBatchNumber = @ShipperQualityBatchNumber
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
	@ProcReturn = dbo.usp_SQA_StageObject
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
go

