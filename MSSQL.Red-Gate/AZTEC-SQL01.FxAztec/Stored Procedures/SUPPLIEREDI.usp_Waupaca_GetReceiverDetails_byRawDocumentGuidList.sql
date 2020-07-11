SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SUPPLIEREDI].[usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList]
	@RawDocumentGuidList varchar(max)
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
						[@RawDocumentGuidList] = @RawDocumentGuidList
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
		/*	Return list of receiver details. */
		set @TocMsg = 'Return list of receiver details'
		begin
			select
				rh.ReceiverID
			,	rh.ReceiverNumber
			,	rh.Type
			,	rh.Status
			,	rh.ShipFrom
			,	rh.Plant
			,	rh.ConfirmedSID
			,	rh.TrackingNumber
			,	rh.ReceiveDT
			,	rh.PutawayDT
			,	rh.Note
			,	rh.SupplierASNGuid
			,	rl.PartCode
			,	rl.PONumber
			,	ro.Serial
			,	ro.QtyObject
			,	ro.Lot
			from
				dbo.ReceiverHeaders rh
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
				join dbo.ReceiverObjects ro
					on ro.ReceiverLineID = rl.ReceiverLineID
					and ro.Serial > 0
			where
				exists
				(	select
						*
					from
						SUPPLIEREDI.WaupacaShipNotices wsn
						join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
							on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
						join dbo.po_header ph
							on ph.po_number = wsnl.PurchaseOrderNumber
						left join dbo.part_vendor pv
							on pv.vendor = wsn.ShipFromCode
							and pv.part = wsnl.PartCode
						join
						(	select
								RawDocumentGUID = convert(uniqueidentifier, rows.Value)
							from
								dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						) docs on docs.RawDocumentGUID = wsnl.RawDocumentGUID
					where
						rh.ConfirmedSID = wsn.ShipperID
						and rh.ShipFrom = wsn.ShipFromCode
						and rh.Plant = ph.ship_to_destination
				)
			order by
				rl.PartCode

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

		---	<CloseTran Implicit=Yes>
		if	(2 & @@OPTIONS) = 1 begin
			commit tran
		end
		---	</CloseTran Implicit=Yes>

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
	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
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
