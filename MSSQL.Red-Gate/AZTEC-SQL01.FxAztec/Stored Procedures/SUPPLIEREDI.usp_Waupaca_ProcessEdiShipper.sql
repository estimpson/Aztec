SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SUPPLIEREDI].[usp_Waupaca_ProcessEdiShipper]
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
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
						[@User] = @User
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
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
		@CallProcName sysname
	,	@TableName sysname
	,	@ProcName sysname
	,	@ProcReturn integer
	,	@ProcResult integer
	,	@Error integer
	,	@RowCount integer

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
	--- </Error Handling>

	/*	Record initial transaction count. */
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount

	begin try

		---	<ArgumentValidation>

		---	</ArgumentValidation>

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
		/*	Create SUPPLIEREDI ship notice. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNotices'
			
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
				wsn.RawDocumentGUID
			,	wsn.ShipperID
			,	wsn.BillOfLadingNumber
			,	wsn.ShipFromCode
			,	wsn.ShipToCode
			,	wsn.ShipDT
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
			where
				wsn.Status = 0
				and wsn.ShipperLineStatus = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			

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

		/*	Create SUPPLIEREDI ship notice lines. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice lines'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeLines'
			
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
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	wsnl.PurchaseOrderRef
			,	Quantity = sum(wsnl.Quantity)
			,	wsnl.PartCode
			,	wsnl.PurchaseOrderNumber
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
					and wsn.ShipperLineStatus= wsn.Status
			where
				wsn.Status = 0
				and wsnl.Status = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			group by
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	wsnl.PurchaseOrderRef
			,	wsnl.PartCode
			,	wsnl.PurchaseOrderNumber
				
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			
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

		/*	Create SUPPLIEREDI ship notice objects. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice objects'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeObjects'
			
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
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	SupplierSerial = null
			,	SupplierParentSerial = null
			,	SupplierPackageType = null
			,	SupplierLot = wsn.BillOfLadingNumber
			,	ObjectQuantity = wsnl.Quantity
			,	wsnl.PartCode
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
					and wsn.ShipperLineStatus= wsn.Status
			where
				wsn.Status = 0
				and wsnl.Status = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			

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

		/*	Process shipment. */
		set @TocMsg = 'Process shipment'
		begin
			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_Process'
			execute @ProcReturn = SUPPLIEREDI.usp_Process
					@TranDT = @TranDT out
				,	@Result = @ProcResult out
				,	@Debug = @cDebug
				,	@DebugMsg = @cDebugMsg out
		
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

		/*	Set shipper line(s) to completed. */
		set @TocMsg = 'Set shipper line(s) to completed'
		begin
			--- <Update rows="1+">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = snl.RawDocumentGUID
					and wsnl.RowID = snl.RowID
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.ReceiverHeaders rh
						join dbo.ReceiverLines rl
							on rl.ReceiverID = rh.ReceiverID
						join dbo.ReceiverObjects ro
							on ro.ReceiverLineID = rl.ReceiverLineID
					where
						rh.SupplierASNGuid = snh.RawDocumentGuid
						and wsnl.PartCode = ro.PartCode
						and ro.Serial > 0
				)
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGUID
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
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

		/*	Set shipper to completed. */
		set	@TocMsg = 'Set shipper to completed'
		begin
			--- <Update rows="1">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGUID
					)
				and not exists
				(	select
						*
					from
						FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
					where
						snl.Status = 0
						and exists
						(	select
								*
							from
								dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
							where
								convert(uniqueidentifier, rows.Value) = snl.RawDocumentGUID
						)
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
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'B831EB6C-3AAB-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Debug = 1

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out
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
