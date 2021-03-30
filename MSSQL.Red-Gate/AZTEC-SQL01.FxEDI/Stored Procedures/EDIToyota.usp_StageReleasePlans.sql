SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDIToyota].[usp_StageReleasePlans]
	@TranDT datetime = null out
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

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)
	end
	--- </TIC>

	--- <SP Begin Logging>
	declare
		@StagingProcedureSchema sysname = schema_name(objectproperty(@@procid, 'SchemaID'))
	,	@StagingProcedureName sysname = object_name(@@procid)

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

	set	@ProcName = @StagingProcedureSchema + '.' + @StagingProcedureName  -- e.g. EDIToyota.usp_Test
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

		/*	Prepare release plans. */
		set @TocMsg = 'Prepare release plans'
		begin
			--declare
			--	@ReleasePlanHeaders table
			create table
				#ReleasePlanHeaders
			(	RawDocumentGUID uniqueidentifier
			,	Data xml
			,	DocumentImportDT datetime
			,	TradingPartner varchar(50)
			,	DocType varchar(6)
			,	Version varchar(20)
			,	ReleaseNo varchar(30)
			,	DocNumber varchar(50)
			,	ControlNumber varchar(10)
			,	DocumentDT datetime
			,	RowID int not null IDENTITY(1, 1) primary key
			)

			create primary xml index ix1 on #ReleasePlanHeaders(Data)

			insert
				#ReleasePlanHeaders
			(	RawDocumentGUID
			,	Data
			,	DocumentImportDT
			,	TradingPartner
			,	DocType
			,	Version
			,	ReleaseNo
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
			,	ReleaseNo = coalesce
					(	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'), '')
					,	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'), '')
					)
			,	DocNumber
			,	ControlNumber
			,	DocumentDT = coalesce
					(	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[4]', 'datetime'), '1900-01-01')
					,	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[3]', 'datetime'), '1900-01-01')
					,	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[2]', 'datetime'), '1900-01-01')
					,	nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[1]', 'datetime'), '1900-01-01')
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
				select '#ReleasePlanHeaders', * from #ReleasePlanHeaders rph
			end

			declare
				@ReleasePlans table
			--create table
			--	@ReleasePlans
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)	
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)
			,	Data xml
			,	RowID int not null IDENTITY(1, 1) primary key
			)

			--create primary xml index ix1 on @ReleasePlans(Data)
			--create xml index ix2 on @ReleasePlans(Data) using xml index ix1 for value

			insert
				@ReleasePlans
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	Data
			)
			select
				RawDocumentGUID
			,	ReleaseNo = rph.ReleaseNo
			,	ShipToCode = coalesce
					(	rph.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),
						rph.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)'),
						LOOP_LIN.Data.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)'),
						rph.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)')
					)
			,	ConsigneeCode = rph.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	ShipFromCode = rph.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	SupplierCode = rph.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	CustomerPart = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerPO = LOOP_LIN.Data.value('(for $a in SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerPOLine = LOOP_LIN.Data.value('(for $a in SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerModelYear = ''
			,	CustomerECL = ''
			,	Data = LOOP_LIN.Data.query('.')
			from
				#ReleasePlanHeaders rph
				cross apply rph.Data.nodes('/TRN-830/LOOP-LIN') as LOOP_LIN(Data)
			
			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlans', * from @ReleasePlans rp
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
		
		/*	Read supplementals. */
		set @TocMsg = 'Read supplementals'
		begin
			declare
				@ReleasePlanSupplementalTemp1 table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)
			,	ValueQualifier varchar(50)
			,	Value varchar(50)
			)

			insert
				@ReleasePlanSupplementalTemp1
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	ValueQualifier
			,	Value
			)
			select
				rp.RawDocumentGUID
			,	rp.ReleaseNo
			,	rp.ShipToCode
			,	rp.ConsigneeCode
			,	rp.ShipFromCode
			,	rp.SupplierCode
			,	rp.CustomerPart
			,	rp.CustomerPO
			,	rp.CustomerPOLine
			,	rp.CustomerModelYear
			,	rp.CustomerECL
			,	ValueQualifier = rp.Data.value('(/LOOP-LIN/SEG-REF/DE[@code="0128"])[1]', 'varchar(50)')
			,	Value = rp.Data.value('(/LOOP-LIN/SEG-REF/DE[@code="0127"])[1]', 'varchar(50)')
			from
				@ReleasePlans rp

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanSupplementalTemp1', * from @ReleasePlanSupplementalTemp1 rpst
			end

			declare @ReleasePlanSupplemental table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)
			,	UserDefined1 varchar(50)  --Dock Code
			,	UserDefined2 varchar(50)  --Line Feed Code	
			,	UserDefined3 varchar(50)  --Reserve Line Feed Code
			,	UserDefined4 varchar(50)  --Zone code
			,	UserDefined5 varchar(50)
			,	UserDefined6 varchar(50)
			,	UserDefined7 varchar(50)
			,	UserDefined8 varchar(50)
			,	UserDefined9 varchar(50)
			,	UserDefined10 varchar(50)
			,	UserDefined11 varchar(50) --11Z
			,	UserDefined12 varchar(50) --12Z
			,	UserDefined13 varchar(50) --13Z
			,	UserDefined14 varchar(50) --14Z
			,	UserDefined15 varchar(50) --15Z
			,	UserDefined16 varchar(50) --16Z
			,	UserDefined17 varchar(50) --17Z
			,	UserDefined18 varchar(50)
			,	UserDefined19 varchar(50)
			,	UserDefined20 varchar(50)
			)

			insert
				@ReleasePlanSupplemental
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	UserDefined6
			,	UserDefined7
			,	UserDefined8
			,	UserDefined9
			,	UserDefined10
			,	UserDefined11
			,	UserDefined12
			,	UserDefined13
			,	UserDefined14
			,	UserDefined15
			,	UserDefined16
			,	UserDefined17
			,	UserDefined18
			,	UserDefined19
			,	UserDefined20
			)
			select
				rpst.RawDocumentGUID
			,	rpst.ReleaseNo
			,	rpst.ShipToCode
			,	rpst.ConsigneeCode
			,	rpst.ShipFromCode
			,	rpst.SupplierCode
			,	rpst.CustomerPart
			,	rpst.CustomerPO
			,	rpst.CustomerPOLine
			,	rpst.CustomerModelYear
			,	rpst.CustomerECL
			,	UserDefined1 = max(case when rpst.ValueQualifier = 'DK' then Value end)
			,	UserDefined2 = max(case when rpst.ValueQualifier = 'LF' then Value end)
			,	UserDefined3 = max(case when rpst.ValueQualifier = 'RL' then Value end)
			,	UserDefined4 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined5 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined6 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined7 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined8 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined9 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined10 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined11 = max(case when rpst.ValueQualifier = '11Z' then Value end)
			,	UserDefined12 = max(case when rpst.ValueQualifier = '12Z' then Value end)
			,	UserDefined13 = max(case when rpst.ValueQualifier = '13Z' then Value end)
			,	UserDefined14 = max(case when rpst.ValueQualifier = '14Z' then Value end)
			,	UserDefined15 = max(case when rpst.ValueQualifier = '15Z' then Value end)
			,	UserDefined16 = max(case when rpst.ValueQualifier = '16Z' then Value end)
			,	UserDefined17 = max(case when rpst.ValueQualifier = '17Z' then Value end)
			,	UserDefined18 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined19 = max(case when rpst.ValueQualifier = '??' then Value end)
			,	UserDefined20 = max(case when rpst.ValueQualifier = '??' then Value end)
			from
				@ReleasePlanSupplementalTemp1 rpst
			group by
				rpst.RawDocumentGUID
			,	rpst.ReleaseNo
			,	rpst.ShipToCode
			,	rpst.ConsigneeCode
			,	rpst.ShipFromCode
			,	rpst.SupplierCode
			,	rpst.CustomerPart
			,	rpst.CustomerPO
			,	rpst.CustomerPOLine
			,	rpst.CustomerModelYear
			,	rpst.CustomerECL

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanSupplemental', * from @ReleasePlanSupplemental rps
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
		
		/*	Read ship accums. */
		set @TocMsg = 'Read ship accums'
		begin
			declare
				@ReleasePlanAccumsTemp1 table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)	
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)	
			,	UserDefined1 varchar(50) 
			,	UserDefined2 varchar(50) 
			,	UserDefined3 varchar(50) 
			,	UserDefined4 varchar(50)
			,	UserDefined5 varchar(50)
			,	ReceivedAccum varchar(50)
			,	ReceivedAccumBeginDT varchar(50)
			,	ReceivedAccumEndDT varchar(50)
			,	ReceivedQty varchar(50)
			,	ReceivedQtyDT varchar(50)
			,	ReceivedShipper varchar(50)
			)

			insert
				@ReleasePlanAccumsTemp1
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	ReceivedAccum
			,	ReceivedAccumBeginDT
			,	ReceivedAccumEndDT
			,	ReceivedQty
			,	ReceivedQtyDT
			,	ReceivedShipper
			)
			select
				rp.RawDocumentGUID
			,	rp.ReleaseNo
			,	rp.ShipToCode
			,	rp.ConsigneeCode
			,	rp.ShipFromCode
			,	rp.SupplierCode
			,	rp.CustomerPart
			,	rp.CustomerPO
			,	rp.CustomerPOLine
			,	rp.CustomerModelYear
			,	rp.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	ReceivedAccum = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	ReceivedAccumBeginDT = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="051" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	ReceivedAccumEndDT =LOOP_SHP. Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="052" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	ReceivedQty = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	ReceivedQtyDT = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="050" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	ReceivedShipper = LOOP_SHP.Data.value('(for $a in SEG-REF/DE[@code="0128"] where $a="SI" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)') 
			from
				@ReleasePlans rp
				cross apply rp.Data.nodes('/LOOP-LIN/LOOP-SHP') as LOOP_SHP(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanAccumsTemp1', * from @ReleasePlanAccumsTemp1 rpat
			end

			declare
				@ReleasePlanAccums table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)	
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)	
			,	UserDefined1 varchar(50) 
			,	UserDefined2 varchar(50) 
			,	UserDefined3 varchar(50) 
			,	UserDefined4 varchar(50)
			,	UserDefined5 varchar(50)
			,	ReceivedAccum varchar(50)
			,	ReceivedAccumBeginDT varchar(50)
			,	ReceivedAccumEndDT varchar(50)
			,	ReceivedQty varchar(50)
			,	ReceivedQtyDT varchar(50)
			,	ReceivedShipper varchar(50)
			)

			insert
				@ReleasePlanAccums
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	ReceivedAccum
			,	ReceivedAccumBeginDT
			,	ReceivedAccumEndDT
			,	ReceivedQty
			,	ReceivedQtyDT
			,	ReceivedShipper
			)
			select
				RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	ReceivedAccum = max(case when ReceivedAccum is not null then ReceivedAccum end)
			,	ReceivedAccumBeginDT = max(case when ReceivedAccumBeginDT is not null then ReceivedAccumBeginDT end)
			,	ReceivedAccumEndDT = max(case when ReceivedAccumEndDT is not null then ReceivedAccumEndDT end)
			,	ReceivedQty = max(case when ReceivedQty is not null then ReceivedQty end)
			,	ReceivedQtyDT = max(case when ReceivedQtyDT is not null then ReceivedQtyDT end)
			,	ReceivedShipper = max(case when ReceivedShipper is not null then ReceivedShipper end)
			from
				@ReleasePlanAccumsTemp1
			group by
				RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanAccums', * from @ReleasePlanAccums rpa
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
		
		/*	Read auth accums. */
		set @TocMsg = 'Read auth accums'
		begin
			declare
				@ReleasePlanAuthAccumsTemp1 table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)	
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)	
			,	UserDefined1 varchar(50) 
			,	UserDefined2 varchar(50) 
			,	UserDefined3 varchar(50) 
			,	UserDefined4 varchar(50)
			,	UserDefined5 varchar(50)
			,	AuthAccum varchar(50)
			,	AuthAccumBeginDT varchar(50)
			,	AuthAccumEndDT varchar(50)
			,	FabAccum varchar(50)
			,	FabAccumBeginDT varchar(50)
			,	FabAccumEndDT varchar(50)
			,	RawAccum varchar(50)
			,	RawAccumBeginDT varchar(50)
			,	RawAccumEndDT varchar(50)
			)

			insert
				@ReleasePlanAuthAccumsTemp1
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	AuthAccum
			,	AuthAccumBeginDT
			,	AuthAccumEndDT 
			,	FabAccum
			,	FabAccumBeginDT
			,	FabAccumEndDT
			,	RawAccum
			,	RawAccumBeginDT
			,	RawAccumEndDT 
			)
			select
				rp.RawDocumentGUID
			,	rp.ReleaseNo
			,	rp.ShipToCode
			,	rp.ConsigneeCode
			,	rp.ShipFromCode
			,	rp.SupplierCode
			,	rp.CustomerPart
			,	rp.CustomerPO
			,	rp.CustomerPOLine
			,	rp.CustomerModelYear
			,	rp.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	AuthAccum = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	AuthAccumBeginDT = coalesce(SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'), SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  ) 
			,	AuthAccumEndDT = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)') 
			,	FabAccum = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	FabAccumBeginDT = coalesce(SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'), SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  )
			,	FabAccumEndDT = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	RawAccum = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	RawAccumBeginDT = coalesce(SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'), SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  )
			,	RawAccumEndDT = SEG_ATH.Data.value('(for $a in DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			--,	SEG_ATH.Data.query('.')
			from
				@ReleasePlans rp
				cross apply rp.Data.nodes('/LOOP-LIN/SEG-ATH') as SEG_ATH(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanAuthAccumsTemp1', * from @ReleasePlanAuthAccumsTemp1 rpaat
			end

			declare
				@ReleasePlanAuthAccums table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)
			,	UserDefined1 varchar(50)
			,	UserDefined2 varchar(50)
			,	UserDefined3 varchar(50)
			,	UserDefined4 varchar(50)
			,	UserDefined5 varchar(50)
			,	AuthAccum varchar(50)
			,	AuthAccumBeginDT varchar(50)
			,	AuthAccumEndDT varchar(50)
			,	FabAccum varchar(50)
			,	FabAccumBeginDT varchar(50)
			,	FabAccumEndDT varchar(50)
			,	RawAccum varchar(50)
			,	RawAccumBeginDT varchar(50)
			,	RawAccumEndDT varchar(50)
			)

			insert
				@ReleasePlanAuthAccums
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	AuthAccum
			,	AuthAccumBeginDT
			,	AuthAccumEndDT 
			,	FabAccum
			,	FabAccumBeginDT
			,	FabAccumEndDT
			,	RawAccum
			,	RawAccumBeginDT
			,	RawAccumEndDT 
			)
			select
				RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	AuthAccum = max(case when AuthAccum is not Null then AuthAccum end)
			,	AuthAccumBeginDT = max(case when AuthAccumBeginDT is not Null then AuthAccumBeginDT end)
			,	AuthAccumEndDT = max(case when AuthAccumEndDT is not Null then AuthAccumEndDT end)
			,	FabAccum = max(case when FabAccum is not Null then FabAccum end)
			,	FabAccumBeginDT = max(case when FabAccumBeginDT is not Null then FabAccumBeginDT end)
			,	FabAccumEndDT = max(case when FabAccumEndDT is not Null then FabAccumEndDT end)
			,	RawAccum = max(case when RawAccum is not Null then RawAccum end)
			,	RawAccumBeginDT = max(case when RawAccumBeginDT is not Null then RawAccumBeginDT end)
			,	RawAccumEndDT = max(case when RawAccumEndDT is not Null then RawAccumEndDT end)
			from
				@ReleasePlanAuthAccumsTemp1
			group by
				RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanAuthAccums', * from @ReleasePlanAuthAccums rpaa
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
		
		/*	Read planning releases. */
		set @TocMsg = 'Read ship schedule releases'
		begin
			declare
				@ReleasePlanReleases table
			(	RawDocumentGUID uniqueidentifier
			,	ReleaseNo varchar(50)
			,	ShipToCode varchar(50)
			,	ConsigneeCode varchar(50)
			,	ShipFromCode varchar(50)
			,	SupplierCode varchar(50)	
			,	CustomerPart varchar(50)
			,	CustomerPO varchar(50)
			,	CustomerPOLine varchar(50)
			,	CustomerModelYear varchar(50)
			,	CustomerECL varchar(50)	
			,	UserDefined1 varchar(50) 
			,	UserDefined2 varchar(50) 
			,	UserDefined3 varchar(50) 
			,	UserDefined4 varchar(50)
			,	UserDefined5 varchar(50)
			,	DateDue varchar(50)
			,	QuantityDue varchar(50)
			,	QuantityType varchar(50)
			)

			insert
				@ReleasePlanReleases
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	DateDue
			,	QuantityDue
			,	QuantityType
			)
			select
				rp.RawDocumentGUID
			,	rp.ReleaseNo
			,	rp.ShipToCode
			,	rp.ConsigneeCode
			,	rp.ShipFromCode
			,	rp.SupplierCode
			,	rp.CustomerPart
			,	rp.CustomerPO
			,	rp.CustomerPOLine
			,	rp.CustomerModelYear
			,	rp.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = SEG_FST.Data.value('(for $a in DE[@code="0128"] where $a="DO" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)')
			,	DateDue = SEG_FST.Data.value('(DE[@code="0373"])[1]', 'varchar(50)')
			,	QuantityDue = SEG_FST.Data.value('(DE[@code="0380"])[1]', 'varchar(50)')
			,	QuantityType = SEG_FST.Data.value('(DE[@code="0680"])[1]', 'varchar(50)')
			from
				@ReleasePlans rp
				cross apply rp.Data.nodes('/LOOP-LIN/LOOP-SDP/SEG-FST') as SEG_FST(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ReleasePlanReleases', * from @ReleasePlanReleases rpr
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
		
		/*	Write to release plan tables. */
		set @TocMsg = 'Write to ship schedule tables. '
		begin
			insert
				FxAztec.EDIToyota.PlanningHeaders
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
				rph.RawDocumentGUID
			,	rph.DocumentImportDT
			,	rph.TradingPartner
			,	rph.DocType
			,	rph.Version
			,	rph.ReleaseNo
			,	rph.DocNumber
			,	rph.ControlNumber
			,	rph.DocumentDT
			from
				#ReleasePlanHeaders rph
			
			insert
				FxAztec.EDIToyota.PlanningSupplemental
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	UserDefined6
			,	UserDefined7
			,	UserDefined8
			,	UserDefined9
			,	UserDefined10
			,	UserDefined11
			,	UserDefined12
			,	UserDefined13
			,	UserDefined14
			,	UserDefined15
			,	UserDefined16
			,	UserDefined17
			,	UserDefined18
			,	UserDefined19
			,	UserDefined20
			)
			select
				rps.RawDocumentGUID
			,	rps.ReleaseNo
			,	rps.ShipToCode
			,	rps.ConsigneeCode
			,	rps.ShipFromCode
			,	rps.SupplierCode
			,	rps.CustomerPart
			,	rps.CustomerPO
			,	rps.CustomerPOLine
			,	rps.CustomerModelYear
			,	rps.CustomerECL
			,	rps.UserDefined1
			,	rps.UserDefined2
			,	rps.UserDefined3
			,	rps.UserDefined4
			,	rps.UserDefined5
			,	rps.UserDefined6
			,	rps.UserDefined7
			,	rps.UserDefined8
			,	rps.UserDefined9
			,	rps.UserDefined10
			,	rps.UserDefined11
			,	rps.UserDefined12
			,	rps.UserDefined13
			,	rps.UserDefined14
			,	rps.UserDefined15
			,	rps.UserDefined16
			,	rps.UserDefined17
			,	rps.UserDefined18
			,	rps.UserDefined19
			,	rps.UserDefined20
			from
				@ReleasePlanSupplemental rps

			insert
				FxAztec.EDIToyota.PlanningAccums
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	LastQtyReceived
			,	LastQtyDT
			,	LastShipper
			,	LastAccumQty
			,	LastAccumDT
			)
			select
				rpa.RawDocumentGUID
			,	rpa.ReleaseNo
			,	rpa.ShipToCode
			,	rpa.ConsigneeCode
			,	rpa.ShipFromCode
			,	rpa.SupplierCode
			,	rpa.CustomerPart
			,	rpa.CustomerPO
			,	rpa.CustomerPOLine
			,	rpa.CustomerModelYear
			,	rpa.CustomerECL
			,	rpa.UserDefined1
			,	rpa.UserDefined2
			,	rpa.UserDefined3
			,	rpa.UserDefined4
			,	rpa.UserDefined5
			,	LastQtyReceived = nullif(rpa.ReceivedQty, '')
			,	LastQtyDT =
					case
						when datalength(rpa.ReceivedQtyDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpa.ReceivedQtyDT)
						when datalength(rpa.ReceivedQtyDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpa.ReceivedQtyDT)
						else convert(datetime, rpa.ReceivedQtyDT)
					end
			,	LastShipper = rpa.ReceivedShipper
			,	LastAccumQty = nullif(rpa.ReceivedAccum, '')
			,	LastAccumDT =
					case
						when datalength(rpa.ReceivedAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpa.ReceivedAccumEndDT)
						when datalength(rpa.ReceivedAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpa.ReceivedAccumEndDT)
						else convert(datetime, rpa.ReceivedAccumEndDT)
					end
			from
				@ReleasePlanAccums rpa

			insert
				FxAztec.EDIToyota.PlanningAuthAccums
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	PriorCUMStartDT
			,	PriorCUMEndDT
			,	PriorCUM
			,	FABCUMStartDT
			,	FABCUMEndDT
			,	FABCUM
			,	RAWCUMStartDT
			,	RAWCUMEndDT
			,	RAWCUM
			)
			select
				rpaa.RawDocumentGUID
			,	rpaa.ReleaseNo
			,	rpaa.ShipToCode
			,	rpaa.ConsigneeCode
			,	rpaa.ShipFromCode
			,	rpaa.SupplierCode
			,	rpaa.CustomerPart
			,	rpaa.CustomerPO
			,	rpaa.CustomerPOLine
			,	rpaa.CustomerModelYear
			,	rpaa.CustomerECL
			,	PriorCUMStartDT =
					case
						when datalength(rpaa.AuthAccumBeginDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.AuthAccumBeginDT)
						when datalength(rpaa.AuthAccumBeginDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.AuthAccumBeginDT)
						else convert(datetime, rpaa.AuthAccumBeginDT)
					end
			,	PriorCUMEndDT =
					case
						when datalength(rpaa.AuthAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.AuthAccumEndDT)
						when datalength(rpaa.AuthAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.AuthAccumEndDT)
						else convert(datetime, rpaa.AuthAccumEndDT)
					end
			,	PriorCUM = nullif(rpaa.AuthAccum, '')
			,	FABCUMStartDT =
					case
						when datalength(rpaa.FabAccumBeginDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.FabAccumBeginDT)
						when datalength(rpaa.FabAccumBeginDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.FabAccumBeginDT)
						else convert(datetime, rpaa.FabAccumBeginDT)
					end
			,	FABCUMEndDT =
					case
						when datalength(rpaa.FabAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.FabAccumEndDT)
						when datalength(rpaa.AuthAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.FabAccumEndDT)
						else convert(datetime, rpaa.FabAccumEndDT)
					end
			,	FABCUM = nullif(rpaa.FabAccum, '')
			,	RAWCUMStartDT =
					case
						when datalength(rpaa.RawAccumBeginDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.RawAccumBeginDT)
						when datalength(rpaa.RawAccumBeginDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.RawAccumBeginDT)
						else convert(datetime, rpaa.RawAccumBeginDT)
					end
			,	RAWCUMEndDT =
					case
						when datalength(rpaa.RawAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpaa.RawAccumEndDT)
						when datalength(rpaa.RawAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpaa.RawAccumEndDT)
						else convert(datetime, rpaa.RawAccumEndDT)
					end
			,	RAWCUM = nullif(rpaa.RawAccum, '')
			from
				@ReleasePlanAuthAccums rpaa
			
			insert
				FxAztec.EDIToyota.PlanningReleases
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	SupplierCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerPOLine
			,	CustomerModelYear
			,	CustomerECL
			,	UserDefined1
			,	UserDefined2
			,	UserDefined3
			,	UserDefined4
			,	UserDefined5
			,	ScheduleType
			,	ReleaseQty 
			,	ReleaseDT
			)
			select
				rpr.RawDocumentGUID
			,	rpr.ReleaseNo
			,	rpr.ShipToCode
			,	rpr.ConsigneeCode
			,	rpr.ShipFromCode
			,	rpr.SupplierCode
			,	rpr.CustomerPart
			,	rpr.CustomerPO
			,	rpr.CustomerPOLine
			,	rpr.CustomerModelYear
			,	rpr.CustomerECL
			,	rpr.UserDefined1
			,	rpr.UserDefined2
			,	rpr.UserDefined3
			,	rpr.UserDefined4
			,	rpr.UserDefined5
			,	ScheduleType = rpr.QuantityType
			,	ReleaseQty = nullif(rpr.QuantityDue, '')
			,	ReleaseDT =
					case
						when datalength(rpr.DateDue) = 6
							then FXSYS.udf_GetDT('YYMMDD', rpr.DateDue)
						when datalength(rpr.DateDue) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', rpr.DateDue)
						else convert(datetime, rpr.DateDue)
					end
			from
				@ReleasePlanReleases rpr

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
		
		/*	Set in process documents to processed. */
		set @TocMsg = 'Set in process documents to processed'
		begin
			--- <Update rows="1+">
			set	@TableName = 'EDI.EDIDocuments'
			
			update
				ed
			set
				Status = 1
			from
				EDI.EDIDocuments ed
				join EDI.XML_TradingPartners_StagingDefinition xtpsd
					on xtpsd.DocumentTradingPartner = ed.TradingPartner
					and xtpsd.DocumentType = ed.Type
			where
				ed.Status = 100
				and xtpsd.StagingProcedureSchema = @StagingProcedureSchema
				and xtpsd.StagingProcedureName = @StagingProcedureName
			
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
		--- </Body>

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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDIToyota.usp_StageReleasePlans
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
GO
