
/*
Create Procedure.FxEDI.EDI4010_WAUPACA.usp_StageShipNotices.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI4010_WAUPACA.usp_StageShipNotices'), 'IsProcedure') = 1 begin
	drop procedure EDI4010_WAUPACA.usp_StageShipNotices
end
go

create procedure EDI4010_WAUPACA.usp_StageShipNotices
	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on
	
	declare
		@StagingProcedureSchema sysname = schema_name(objectproperty(@@procid, 'SchemaID'))
	,	@StagingProcedureName sysname = object_name(@@procid)
	--	@StagingProcedureSchema sysname = 'EDI4010_WAUPACA'
	--,	@StagingProcedureName sysname = 'usp_StageShipNotice'

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

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + @StagingProcedureSchema + '.' + @StagingProcedureName
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
		USP_Name = @StagingProcedureSchema + '.' + @StagingProcedureName
	,	BeginDT = getdate()
	,	InArguments = convert
			(	varchar(max)
			,	(	select
						[@TranDT] = @TranDT
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

	set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI4010_WAUPACA.usp_Test
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
		/*	Ensure queue is empty (queue error). */
		set @TocMsg = 'Ensure queue is empty (queue error)'
		if	exists
			(	select
					*
				from
					EDI.EDIDocuments ed
					join EDI.XML_TradingPartners_StagingDefinition xtpsd
						on xtpsd.DocumentTradingPartner = ed.TradingPartner
						and xtpsd.DocumentType = ed.Type
				where
					ed.Status = 100
					and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
					and xtpsd.StagingProcedureName = @StagingProcedureName
			)
		begin
			/*	Queue error raised below. */

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

			/*	Raise queue error. */
			raiserror ('There are already documents in process.  Use %s.usp_ClearQueue to clear the queue if necessary.', 16, 1, @StagingProcedureSchema)
		end

		/*	Move new/reprocessed documents to in process otherwise done. */
		set @TocMsg = 'Move new/reprocessed documents to in process otherwise done'
		if	exists
				(	select
						*
					from
						EDI.EDIDocuments ed
						join EDI.XML_TradingPartners_StagingDefinition xtpsd
							on xtpsd.DocumentTradingPartner = ed.TradingPartner
							and xtpsd.DocumentType = ed.Type
					where
						ed.Status in (0,2)
						and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
						and xtpsd.StagingProcedureName = @StagingProcedureName
				)
		begin
			--- <Update rows="1+">
			set	@TableName = 'EDI.EDIDocuments'

			update
				ed
			set
				Status = 100
			from
				EDI.EDIDocuments ed
				join EDI.XML_TradingPartners_StagingDefinition xtpsd
					on xtpsd.DocumentTradingPartner = ed.TradingPartner
					and xtpsd.DocumentType = ed.Type
			where
				ed.Status in (0, 2)
				and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
				and xtpsd.StagingProcedureName = @StagingProcedureName
				and not exists
					(	select
							*
						from
							EDI.EDIDocuments ed
							join EDI.XML_TradingPartners_StagingDefinition xtpsd
								on xtpsd.DocumentTradingPartner = ed.TradingPartner
								and xtpsd.DocumentType = ed.Type
						where
							ed.Status = 100
							and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
							and xtpsd.StagingProcedureName = @StagingProcedureName
					)

			select
				@Error = @@Error,
				@RowCount = @@Rowcount

			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
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
		else begin
			goto done
		end

		/*	Prepare ship notices.  */
		set @TocMsg = 'Prepare ship notices'
		begin
			declare
				@ShipNoticeHeaders table
			(	RawDocumentGUID uniqueidentifier
			,	Data xml
			,	DocumentImportDT datetime
			,	TradingPartner varchar(50)
			,	DocType varchar(6)
			,	Version varchar(20)
			,	ShipperID varchar(50)
			,	DocNumber varchar(50)
			,	ControlNumber varchar(10)
			,	DocumentDT datetime
			)

			insert
				@ShipNoticeHeaders
			(	RawDocumentGUID
			,	Data
			,	DocumentImportDT
			,	TradingPartner
			,	DocType
			,	Version
			,	ShipperID
			,	DocNumber
			,	ControlNumber
			,	DocumentDT
			)
			select
				RawDocumentGUID = ed.GUID
			,	Data = ed.Data
			,	DocumentImportDT = ed.RowCreateDT
			,	TradingPartner
			,	DocType = ed.Type
			,	Version
			,	ShipperID = ed.Data.value('(/TRN-856/SEG-BSN/DE[@code="0396"])[1]', 'varchar(50)')
			,	DocNumber
			,	ControlNumber
			,	DocumentDT = coalesce
					(	ed.Data.value('(/TRN-856/SEG-BSN/DE[@code="0373"])[2]', 'datetime')
					,	ed.Data.value('(/TRN-856/SEG-BSN/DE[@code="0373"])[1]', 'datetime')
					)
			from
				EDI.EDIDocuments ed
				join EDI.XML_TradingPartners_StagingDefinition xtpsd
					on xtpsd.DocumentTradingPartner = ed.TradingPartner
					and xtpsd.DocumentType = ed.Type
			where
				ed.Status = 100
				and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
				and xtpsd.StagingProcedureName = @StagingProcedureName
				
			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipNoticeHeaders', * from @ShipNoticeHeaders snh
			end

			declare
				@ShipNotices table
			(	RawDocumentGUID uniqueidentifier
			,	ShipperID varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	PackagingCode varchar(50)
			,	LadingQty varchar(50)
			,	GrossWeight varchar(50)
			,	Carrier varchar(50)
			,	TransMode varchar(50)
			,	Trailer varchar(50)
			,	Data xml
			)

			insert
				@ShipNotices
			(	RawDocumentGUID
			,	ShipperID
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	PackagingCode
			,	LadingQty
			,	GrossWeight
			,	Carrier
			,	TransMode
			,	Trailer
			,	Data
			)
			select
				snh.RawDocumentGUID
			,	ShipperID = snh.ShipperID
			,	ShipToCode = LOOP_HL.Data.value('(LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	ConsigneeCode = ''
			,	ShipToCode = LOOP_HL.Data.value('(LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	PackagingCode = LOOP_HL.Data.value('(SEG-TD1/DE[@code="0103"])[last()]', 'varchar(50)')
			,	LadingQty = LOOP_HL.Data.value('(SEG-TD1/DE[@code="0080"])[last()]', 'varchar(50)')
			,	GrossWeight = LOOP_HL.Data.value('(SEG-TD1 [DE[.="G"][@code="0187"]]/DE[@code="0081"])[last()]', 'varchar(50)')
			,	Carrier = LOOP_HL.Data.value('(SEG-TD5/DE[@code="0067"])[last()]', 'varchar(50)')
			,	TransMode = LOOP_HL.Data.value('(SEG-TD5/DE[@code="0091"])[last()]', 'varchar(50)')
			,	Trailer = LOOP_HL.Data.value('(SEG-TD3/DE[@code="0207"])[last()]', 'varchar(50)')
			,	Data = LOOP_HL.Data.query('.')
			from
				@ShipNoticeHeaders snh
				outer apply snh.Data.nodes('/TRN-856/LOOP-HL[SEG-HL/DE[.="S"][@code="0735"]]') as LOOP_HL(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipNotices', * from @ShipNotices sn
			end

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

		/*	Prepare shipper orders. */
		set @TocMsg = 'Prepare shipper orders'
		begin
			declare
				@ShipNoticeOrders table
			(	RawDocumentGUID uniqueidentifier
			,	ShipperID varchar(50)
			,	PurchaseOrder varchar(50)
			,	IdNumber varchar(50)
			,	Data xml
			)
			
			insert
				@ShipNoticeOrders
			(	RawDocumentGUID
			,	ShipperID
			,	PurchaseOrder
			,	IdNumber
			,	Data
			)
			select
				snh.RawDocumentGUID
			,	snh.ShipperID
			,	PurchaseOrder = LOOP_HL.Data.value('(SEG-PRF/DE)[1]', 'varchar(50)')
			,	IdNumber = LOOP_HL.Data.value('(SEG-HL/DE[@code="0628"])[1]', 'varchar(50)')
			,	Data = LOOP_HL.Data.query('.')
			from
				@ShipNoticeHeaders snh
				outer apply snh.Data.nodes('/TRN-856/LOOP-HL[SEG-HL/DE[.="O"][@code="0735"]]') as LOOP_HL(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipNoticeOrders', * from @ShipNoticeOrders sno
			end

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

		/*	Prepare shipper lines */
		set @TocMsg = 'Prepare shipper lines'

		begin
			declare
				@ShipNoticeLines table
			(	RawDocumentGUID uniqueidentifier
			,	ShipperID varchar(50)
			,	PartNumber varchar(50)
			,	Quantity varchar(50)
			,	Unit varchar(50)
			,	Loads varchar(50)
			,	QuantityPerLoad varchar(50)
			,	IdNumber varchar(50)
			,	Data xml
			)
			
			insert
				@ShipNoticeLines
			(	RawDocumentGUID
			,	ShipperID
			,	PartNumber
			,	Quantity
			,	Unit
			,	Loads
			,	QuantityPerLoad
			,	IdNumber
			,	Data
			)
			select
				snh.RawDocumentGUID
			,	snh.ShipperID
			,	PartNumber = LOOP_HL.Data.value('(SEG-LIN/DE[@code="0234"])[1]', 'varchar(50)')
			,	Quantity = LOOP_HL.Data.value('(SEG-SN1/DE[@code="0382"])[1]', 'varchar(50)')
			,	Unit = LOOP_HL.Data.value('(SEG-SN1/DE[@code="0355"])[1]', 'varchar(50)')
			,	Loads = LOOP_HL.Data.value('(LOOP-CLD/SEG-CLD/DE[@code="0622"])[1]', 'varchar(50)')
			,	QuantityPerLoad = LOOP_HL.Data.value('(LOOP-CLD/SEG-CLD/DE[@code="0382"])[1]', 'varchar(50)')
			,	sno.IdNumber
			,	Data = LOOP_HL.Data.query('.')
			from
				@ShipNoticeOrders sno
				join @ShipNoticeHeaders snh
					on snh.RawDocumentGUID = sno.RawDocumentGUID
				cross apply snh.Data.nodes('/TRN-856/LOOP-HL[SEG-HL/DE[.="I"][@code="0735"]]') as LOOP_HL(Data)
			where
				sno.IdNumber = LOOP_HL.Data.value('(SEG-HL/DE[@code="0734"])[1]', 'varchar(50)')
		
			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipNoticeLines', * from @ShipNoticeLines snl
			end

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

		/*	Write to ship notice tables. */
		set @TocMsg = 'Write to release plan tables. '
		begin
			insert
				EDI4010_WAUPACA.ShipNoticeHeaders
			(	RawDocumentGUID
			,	DocumentImportDT
			,	TradingPartner
			,	DocType
			,	Version
			,	Release
			,	DocNumber
			,	ControlNumber
			,	DocumentDT
			)
			select
				snh.RawDocumentGUID
			,	snh.DocumentImportDT
			,	snh.TradingPartner
			,	snh.DocType
			,	snh.Version
			,	snh.ShipperID
			,	snh.DocNumber
			,	snh.ControlNumber
			,	snh.DocumentDT
			from
				@ShipNoticeHeaders snh

			insert
				EDI4010_WAUPACA.ShipNotices
			(	RawDocumentGUID
			,	ShipperID
			,	ShipToCode
			,	ShipFromCode
			,	PackageCode
			,	LadingQty
			,	GrossWeight
			,	Carrier
			,	TransMode
			,	Trailer
			)
			select
				sn.RawDocumentGUID
			,	sn.ShipperID
			,	sn.ShipToCode
			,	sn.ShipFromCode
			,	sn.PackagingCode
			,	sn.LadingQty
			,	sn.GrossWeight
			,	sn.Carrier
			,	sn.TransMode
			,	sn.Trailer
			from
				@ShipNotices sn

			insert
				EDI4010_WAUPACA.ShipNoticeOrders
			(	RawDocumentGUID
			,	ShipperID
			,	PurchaseOrder
			)
			select
				sno.RawDocumentGUID
			,	sno.ShipperID
			,	sno.PurchaseOrder
			from
				@ShipNoticeOrders sno

			insert
				EDI4010_WAUPACA.ShipNoticeLines
			(	RawDocumentGUID
			,	ShipperID
			,	PurchaseOrder
			,	PartNumber
			,	Quantity
			,	Unit
			,	Loads
			,	QuantityPerLoad
			)
			select
				snl.RawDocumentGUID
			,	snl.ShipperID
			,	sno.PurchaseOrder
			,	snl.PartNumber
			,	snl.Quantity
			,	snl.Unit
			,	snl.Loads
			,	snl.QuantityPerLoad
			from
				@ShipNoticeLines snl
				join @ShipNoticeOrders sno
					on sno.RawDocumentGUID = snl.RawDocumentGUID
					and sno.ShipperID = snl.ShipperID
					and sno.IdNumber = snl.IdNumber

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

			if	@Debug & 0x01 = 0x01 begin	
				select
					'ShipNoticeHeaders', *
				from
					EDI4010_WAUPACA.ShipNoticeHeaders snh
				where
					exists (select * from @ShipNoticeHeaders snhL where snhL.RawDocumentGUID = snh.RawDocumentGUID)

				select
					'ShipNotices', *
				from
					EDI4010_WAUPACA.ShipNotices sn
				where
					exists (select * from @ShipNoticeHeaders snhL where snhL.RawDocumentGUID = sn.RawDocumentGUID)

				select
					'ShipNoticeOrders', *
				from
					EDI4010_WAUPACA.ShipNoticeOrders sno
				where
					exists (select * from @ShipNoticeHeaders snhL where snhL.RawDocumentGUID = sno.RawDocumentGUID)

				select
					'ShipNoticeLines', *
				from
					EDI4010_WAUPACA.ShipNoticeLines snl
				where
					exists (select * from @ShipNoticeHeaders snhL where snhL.RawDocumentGUID = snl.RawDocumentGUID)

			end
		end

		done:
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

		if	@Debug & 0x01 = 0x01 begin
			exec FXSYS.usp_LongPrint @DebugMsg
		end

		---	<Return>
		set	@Result = 0
		return
			--@Result
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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI4010_WAUPACA.usp_StageShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Debug = 1

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

