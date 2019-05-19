SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SPORTAL].[usp_SupplierShipments_ProcessASN]
	@SupplierCode varchar(10)
,	@ShipperID varchar(50)
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on

	--- <TIC>
	declare
		@cDebug int = @Debug + 2 -- Proc level

	if	@Debug & 0x01 = 0x01 begin
		declare
			@TicDT datetime = getdate()
		,	@TocDT datetime
		,	@TimeDiff varchar(max)
		,	@TocMsg varchar(max)
		,	@cDebugMsg varchar(max)

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
	end
	--- </TIC>

	--- <SP Begin Logging>
	declare
		@LogID int

	insert
		FXSYS.USP_Calls
	(	USP_Name
	,	BeginDT
	,	InArguments
	)
	select
		USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
	,	BeginDT = getdate()
	,	InArguments = convert
			(	varchar(max)
			,	(	select
						[@SupplierCode] = @SupplierCode
					,	[@ShipperID] = @ShipperID
					,	[@TranDT] = @TranDT
					,	[@Result] = @Result
					,	[@Debug] = @Debug
					,	[@DebugMsg] = @DebugMsg
					for xml raw			
				)
			)

	set	@LogID = scope_identity()
	--- </SP Begin Logging>

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

	/*	Record initial transaction count. */
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount

	begin try

		---	<ArgumentValidation>

		---	</ArgumentValidation>

		--- <Body>
		--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
		if	@TranCount = 0 begin
			begin tran @ProcName
		end
		else begin
			save tran @ProcName
		end
		set	@TranDT = coalesce(@TranDT, GetDate())
		--- </Tran>

		--- <Body>
		/*	Create SUPPLIEREDI Ship Notice. */
		set @TocMsg = 'Create SUPPLIEREDI Ship Notice'
		begin
			insert
				SUPPLIEREDI.ShipNotices
			(	RawDocumentGUID
			,	ShipperID
			,	BillOfLadingNumber
			,	ShipFromCode
			,	ShipToCode
			,	ShipDT
			)
			select
				RawDocumentGUID = ssa.RowGUID
			,	ShipperID = ssa.ShipperID
			,	BillOfLadingNumber = ssa.BOLNumber
			,	ShipFromCode = ssa.SupplierCode
			,	ShipToCode = ssa.Destination
			,	ShipDT = @TranDT
			from
				SPORTAL.SupplierShipmentsASN ssa
			where
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID

			insert
				SUPPLIEREDI.ShipNoticeLines
			(	RawDocumentGUID
			,	SupplierPart
			,	PurchaseOrderRef
			,	Quantity
			,	PartCode
			,	PurchaseOrderNumber
			)
			select
				RawDocumentGUID = ssa.RowGUID
			,	SupplierPart = ssal.Part
			,	PurchaseOrderRef = ssal.Part
			,	Quantity = ssal.Quantity
			,	PartCode = ssal.Part
			,	PurchaseOrderNumber = convert(varchar(50), ph.po_number)
			from
				SPORTAL.SupplierShipmentsASNLines ssal
				join SPORTAL.SupplierShipmentsASN ssa
					on ssa.RowID = ssal.SupplierShipmentsASNRowID
				outer apply
					(	select top(1)
							ph.po_number
						from
							dbo.po_header ph
						where
							ph.ship_to_destination = ssa.Destination
							and ph.plant = ssa.SupplierCode
							and ph.blanket_part = ssal.Part
						order by
							ph.po_number desc
					) ph
			where
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID
			
			insert
				SUPPLIEREDI.ShipNoticeObjects
			(	RawDocumentGUID
			,	SupplierPart
			,	SupplierSerial
			,	SupplierParentSerial
			,	SupplierPackageType
			,	SupplierLot
			,	ObjectQuantity
			,	PartCode
			)
			select
				RawDocumentGUID = ssa.RowGUID
			,	SupplierPart = ssal.Part
			,	SupplierSerial = ssal.RowID
			,	SupplierParentSerial = null
			,	SupplierPackageType = null
			,	SupplierLot = ssa.ShipperID
			,	ObjectQuantity = ssal.Quantity
			,	PartCode = ssal.Part
			from
				SPORTAL.SupplierShipmentsASNLines ssal
				join SPORTAL.SupplierShipmentsASN ssa
					on ssa.RowID = ssal.SupplierShipmentsASNRowID
			where
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end

		/*	Process Ship Notice. */
		set @TocMsg = 'Process Ship Notice'
		begin
			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_Process'
			
			execute @ProcReturn = SUPPLIEREDI.usp_Process
				@TranDT = @TranDT out
			,	@Result = @Result out
			,	@Debug = @cDebug
			,	@DebugMsg = @cDebugMsg out
			
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>
							
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		/*	Mark Ship Notice as processed. */
		set @TocMsg = 'Mark Ship Notice as processed'
		begin
			update
				ssa
			set ssa.Status = 1
			from
				SPORTAL.SupplierShipmentsASN ssa
			where
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID
				
			update
				ssal
			set ssal.Status = 1
			from
				SPORTAL.SupplierShipmentsASNLines ssal
				join SPORTAL.SupplierShipmentsASN ssa
					on ssa.RowID = ssal.SupplierShipmentsASNRowID
				cross apply
					(	select top(1)
							ph.po_number
						from
							dbo.po_header ph
						where
							ph.ship_to_destination = ssa.Destination
							and ph.plant = ssa.SupplierCode
							and ph.blanket_part = ssal.Part
						order by
							ph.po_number desc
					) ph
			where
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID
				
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		--- </Body>

		---	<CloseTran AutoCommit=Yes>
		if	@TranCount = 0 begin
			commit tran @ProcName
		end
		---	</CloseTran AutoCommit=Yes>

		--- <SP End Logging>
		update
			uc
		set	EndDT = getdate()
		,	OutArguments = convert
				(	varchar(max)
				,	(	select
							[@TranDT] = @TranDT
						,	[@Result] = @Result
						,	[@DebugMsg] = @DebugMsg
						for xml raw			
					)
				)
		from
			FXSYS.USP_Calls uc
		where
			uc.RowID = @LogID
		--- </SP End Logging>

		--- <TIC/TOC END>
		if	@Debug & 0x3F = 0x01 begin
			set @DebugMsg = @DebugMsg + char(13) + char(10)
			print @DebugMsg
		end
		--- </TIC/TOC END>

		---	<Return>
		set	@Result = 0
		return
			@Result
		--- </Return>
	end try
	begin catch
		declare
			@errorSeverity int
		,	@errorState int
		,	@errorMessage nvarchar(2048)
		,	@xact_state int
	
		select
			@errorSeverity = error_severity()
		,	@errorState = error_state ()
		,	@errorMessage = error_message()
		,	@xact_state = xact_state()

		execute FXSYS.usp_PrintError

		if	@xact_state = -1 begin 
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount = 0 begin
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount > 0 begin
			rollback transaction @ProcName
			execute FXSYS.usp_LogError
		end

		raiserror(@errorMessage, @errorSeverity, @errorState)
	end catch
end

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
	@FinishedPart varchar(25) = 'ALC0598-HC02'
,	@ParentHeirarchID hierarchyid

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_SupplierShipments_ProcessASN
	@FinishedPart = @FinishedPart
,	@ParentHeirarchID = @ParentHeirarchID
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
