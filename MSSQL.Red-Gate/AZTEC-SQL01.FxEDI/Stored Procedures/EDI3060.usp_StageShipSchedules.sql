SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI3060].[usp_StageShipSchedules]
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
		@LogID int

	insert
		FXSYS.USP_Calls
	(	USP_Name
	,	BeginDT
	,	InArguments
	)
	select
		USP_Name = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)
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

	set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI3060.usp_Test
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
		declare
			@StagingProcedureSchema sysname = schema_name(objectproperty(@@procid, 'SchemaID'))
		,	@StagingProcedureName sysname = object_name(@@procid)

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

		/*	Prepare ship schedules. */
		set @TocMsg = 'Prepare ship schedules'
		begin
			--declare
			--	#ShipScheduleHeaders table
			create table
				#ShipScheduleHeaders
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

			create primary xml index ix1 on #ShipScheduleHeaders(Data)

			insert
				#ShipScheduleHeaders
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
					(	ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)')
					,	ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)')
					)
			,	DocNumber
			,	ControlNumber
			,	DocumentDT = coalesce
					(	ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[2]', 'datetime')
					,	ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[1]', 'datetime')
					)
			from
				EDI.EDIDocuments ed
			where
				ed.Type = '862'
				and ed.Version = '003060'
				and ed.Status = 100
				
			if	@Debug & 0x01 = 0x01 begin	
				select
					'#ShipScheduleHeaders'
				,	ssh.RawDocumentGUID
				--,	ssh.Data
				,	ssh.DocumentImportDT
				,	ssh.TradingPartner
				,	ssh.DocType
				,	ssh.Version
				,	ssh.ReleaseNo
				,	ssh.DocNumber
				,	ssh.ControlNumber
				,	ssh.DocumentDT
				,	ssh.RowID
				from
					#ShipScheduleHeaders ssh
			end

			--return

			declare
				@ShipSchedules table
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
			--,	ParentData xml
			)

			insert
				@ShipSchedules
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
			--,	ParentData
			)
			select
				RawDocumentGUID
			,	ReleaseNo = ssh.ReleaseNo
			,	ShipToCode = coalesce(LOOP_LIN.Data.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ssh.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'))
			,	ConsigneeCode = ssh.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	ShipFromCode = ssh.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	SupplierCode = ssh.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
			,	CustomerPart = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerPO = LOOP_LIN.Data.value('(for $a in SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerPOLine = LOOP_LIN.Data.value('(for $a in SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	CustomerModelYear = ''
			,	CustomerECL = ''
			,	Data = LOOP_LIN.Data.query('.')
			--,	ParentData = LOOP_LIN.Data.query('..')
			from
				#ShipScheduleHeaders ssh
				cross apply ssh.Data.nodes('/TRN-862/LOOP-LIN') as LOOP_LIN(Data)
			
			if	@Debug & 0x01 = 0x01 begin	
				select
					'@ShipSchedules'
				,	ss.RawDocumentGUID
				,	ss.ReleaseNo
				,	ss.ShipToCode
				,	ss.ConsigneeCode
				,	ss.ShipFromCode
				,	ss.SupplierCode
				,	ss.CustomerPart
				,	ss.CustomerPO
				,	ss.CustomerPOLine
				,	ss.CustomerModelYear
				,	ss.CustomerECL
				--,	ss.Data
				from
					@ShipSchedules ss
				order by
					ss.CustomerPart
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

		--return
		
		/*	Read supplementals. */
		set @TocMsg = 'Read supplementals'
		begin
			declare
				@ShipScheduleSupplementalTemp1 table
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
				@ShipScheduleSupplementalTemp1
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
				ss.RawDocumentGUID
			,	ss.ReleaseNo
			,	ss.ShipToCode
			,	ss.ConsigneeCode
			,	ss.ShipFromCode
			,	ss.SupplierCode
			,	ss.CustomerPart
			,	ss.CustomerPO
			,	ss.CustomerPOLine
			,	ss.CustomerModelYear
			,	ss.CustomerECL
			,	ValueQualifier = ss.Data.value('(LOOP-LIN/SEG-REF/DE[@code="0128"])[1]', 'varchar(50)')
			,	Value = ss.Data.value('(LOOP-LIN/SEG-REF/DE[@code="0127"])[1]', 'varchar(50)')
			from
				@ShipSchedules ss

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipScheduleSupplementalTemp1', * from @ShipScheduleSupplementalTemp1 ssst
			end

			declare @ShipScheduleSupplemental table
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
				@ShipScheduleSupplemental
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
			,	UserDefined1 = max(case when ValueQualifier = 'DK' then Value end)
			,	UserDefined2 = max(case when ValueQualifier = 'LF' then Value end)
			,	UserDefined3 = max(case when ValueQualifier = 'RL' then Value end)
			,	UserDefined4 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined5 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined6 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined7 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined8 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined9 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined10 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined11 = max(case when ValueQualifier = '11Z' then Value end)
			,	UserDefined12 = max(case when ValueQualifier = '12Z' then Value end)
			,	UserDefined13 = max(case when ValueQualifier = '13Z' then Value end)
			,	UserDefined14 = max(case when ValueQualifier = '14Z' then Value end)
			,	UserDefined15 = max(case when ValueQualifier = '15Z' then Value end)
			,	UserDefined16 = max(case when ValueQualifier = '16Z' then Value end)
			,	UserDefined17 = max(case when ValueQualifier = '17Z' then Value end)
			,	UserDefined18 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined19 = max(case when ValueQualifier = '??' then Value end)
			,	UserDefined20 = max(case when ValueQualifier = '??' then Value end)
			from
				@ShipScheduleSupplementalTemp1
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

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipScheduleSupplemental', * from @ShipScheduleSupplemental sss
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
		
		--return

		/*	Read ship accums. */
		set @TocMsg = 'Read ship accums'
		begin
			declare
				@ShipScheduleAccumsTemp1 table
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
				@ShipScheduleAccumsTemp1
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
				ss.RawDocumentGUID
			,	ss.ReleaseNo
			,	ss.ShipToCode
			,	ss.ConsigneeCode
			,	ss.ShipFromCode
			,	ss.SupplierCode
			,	ss.CustomerPart
			,	ss.CustomerPO
			,	ss.CustomerPOLine
			,	ss.CustomerModelYear
			,	ss.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	ReceivedAccum = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	ReceivedAccumBeginDT = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="051" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	ReceivedAccumEndDT = coalesce
					(	LOOP_SHP. Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="052" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
					,	LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="051" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)')
					)
			,	ReceivedQty = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	ReceivedQtyDT = LOOP_SHP.Data.value('(for $a in SEG-SHP/DE[@code="0374"] where $a="050" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	ReceivedShipper = LOOP_SHP.Data.value('(for $a in SEG-REF/DE[@code="0128"] where $a="SI" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)') 
			from
				@ShipSchedules ss
				cross apply ss.Data.nodes('/LOOP-LIN/LOOP-SHP') as LOOP_SHP(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipScheduleAccumsTemp1', * from @ShipScheduleAccumsTemp1 ssat
			end

			declare
				@ShipScheduleAccums table
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
				@ShipScheduleAccums
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
				@ShipScheduleAccumsTemp1
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
				select '@ShipScheduleAccums', * from @ShipScheduleAccums ssa order by ssa.CustomerPart
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

		--return
		
		/*	Read auth accums. */
		set @TocMsg = 'Read auth accums'
		begin
			declare
				@ShipScheduleAuthAccumsTemp1 table
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
			,	AuthAccum varchar(50)
			,	AuthAccumBeginDT varchar(50)
			,	AuthAccumEndDT varchar(50)
			)

			insert
				@ShipScheduleAuthAccumsTemp1
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
			)
			select
				ss.RawDocumentGUID
			,	ss.ReleaseNo
			,	ss.ShipToCode
			,	ss.ConsigneeCode
			,	ss.ShipFromCode
			,	ss.SupplierCode
			,	ss.CustomerPart
			,	ss.CustomerPO
			,	ss.CustomerPOLine
			,	ss.CustomerModelYear
			,	ss.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = ''
			,	AuthAccum = LOOP_ATH.Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
			,	AuthAccumBeginDT = LOOP_ATH.Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0374"] where $a="051" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
			,	AuthAccumEndDT = LOOP_ATH.Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0374"] where $a="052" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)') 
			from
				@ShipSchedules ss
				cross apply ss.Data.nodes('/LOOP-LIN/LOOP-ATH') as LOOP_ATH(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipScheduleAuthAccumsTemp1', * from @ShipScheduleAuthAccumsTemp1 ssaat
			end

			declare
				@ShipScheduleAuthAccums table
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
			)

			insert
				@ShipScheduleAuthAccums
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
			,	AuthAccum = max(case when AuthAccum is not null then AuthAccum end)
			,	AuthAccumBeginDT = max(case when AuthAccumBeginDT is not null then AuthAccumBeginDT end)
			,	AuthAccumEndDT = max(case when AuthAccumEndDT is not null then AuthAccumEndDT end)
			from
				@ShipScheduleAuthAccumsTemp1
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
				select '@ShipScheduleAuthAccums', * from @ShipScheduleAuthAccums ssaa
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
		
		/*	Read ship schedule releases. */
		set @TocMsg = 'Read ship schedule releases'
		begin
			declare
				@ShipScheduleReleases table
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
				@ShipScheduleReleases
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
				ss.RawDocumentGUID
			,	ss.ReleaseNo
			,	ss.ShipToCode
			,	ss.ConsigneeCode
			,	ss.ShipFromCode
			,	ss.SupplierCode
			,	ss.CustomerPart
			,	ss.CustomerPO
			,	ss.CustomerPOLine
			,	ss.CustomerModelYear
			,	ss.CustomerECL
			,	UserDefined1 = ''
			,	UserDefined2 = ''
			,	UserDefined3 = ''
			,	UserDefined4 = ''
			,	UserDefined5 = SEG_FST.Data.value('(for $a in DE[@code="0128"] where $a="DO" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)')
			,	DateDue = SEG_FST.Data.value('(DE[@code="0373"])[1]', 'varchar(50)')
			,	QuantityDue = SEG_FST.Data.value('(DE[@code="0380"])[1]', 'varchar(50)')
			,	QuantityType = SEG_FST.Data.value('(DE[@code="0680"])[1]', 'varchar(50)')
			from
				@ShipSchedules ss
				cross apply ss.Data.nodes('/LOOP-LIN/LOOP-FST[not(LOOP-JIT)]/SEG-FST') as SEG_FST(Data)

			if	@Debug & 0x01 = 0x01 begin	
				select '@ShipScheduleReleases', * from @ShipScheduleReleases
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

		--return
		
		/*	Write to ship schedule tables. */
		set @TocMsg = 'Write to ship schedule tables. '
		begin
			insert
				EDI3060.ShipScheduleHeaders
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
				ssh.RawDocumentGUID
			,	ssh.DocumentImportDT
			,	ssh.TradingPartner
			,	ssh.DocType
			,	ssh.Version
			,	ssh.ReleaseNo
			,	ssh.DocNumber
			,	ssh.ControlNumber
			,	ssh.DocumentDT
			from
				#ShipScheduleHeaders ssh
			
			insert
				EDI3060.ShipScheduleSupplemental
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
				sss.RawDocumentGUID
			,	sss.ReleaseNo
			,	sss.ShipToCode
			,	sss.ConsigneeCode
			,	sss.ShipFromCode
			,	sss.SupplierCode
			,	sss.CustomerPart
			,	sss.CustomerPO
			,	sss.CustomerPOLine
			,	sss.CustomerModelYear
			,	sss.CustomerECL
			,	sss.UserDefined1
			,	sss.UserDefined2
			,	sss.UserDefined3
			,	sss.UserDefined4
			,	sss.UserDefined5
			,	sss.UserDefined6
			,	sss.UserDefined7
			,	sss.UserDefined8
			,	sss.UserDefined9
			,	sss.UserDefined10
			,	sss.UserDefined11
			,	sss.UserDefined12
			,	sss.UserDefined13
			,	sss.UserDefined14
			,	sss.UserDefined15
			,	sss.UserDefined16
			,	sss.UserDefined17
			,	sss.UserDefined18
			,	sss.UserDefined19
			,	sss.UserDefined20
			from
				@ShipScheduleSupplemental sss

			insert
				EDI3060.ShipScheduleAccums
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
				ssa.RawDocumentGUID
			,	ssa.ReleaseNo
			,	ssa.ShipToCode
			,	ssa.ConsigneeCode
			,	ssa.ShipFromCode
			,	ssa.SupplierCode
			,	ssa.CustomerPart
			,	ssa.CustomerPO
			,	ssa.CustomerPOLine
			,	ssa.CustomerModelYear
			,	ssa.CustomerECL
			,	ssa.UserDefined1
			,	ssa.UserDefined2
			,	ssa.UserDefined3
			,	ssa.UserDefined4
			,	ssa.UserDefined5
			,	LastQtyReceived = nullif(ssa.ReceivedQty, '')
			,	LastQtyDT =
					case
						when datalength(ssa.ReceivedQtyDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', ssa.ReceivedQtyDT)
						when datalength(ssa.ReceivedQtyDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', ssa.ReceivedQtyDT)
						else convert(datetime, ssa.ReceivedQtyDT)
					end
			,	LastShipper = ssa.ReceivedShipper
			,	LastAccumQty = nullif(ssa.ReceivedAccum, '')
			,	LastAccumDT =
					case
						when datalength(ssa.ReceivedAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', ssa.ReceivedAccumEndDT)
						when datalength(ssa.ReceivedAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', ssa.ReceivedAccumEndDT)
						else convert(datetime, ssa.ReceivedAccumEndDT)
					end
			from
				@ShipScheduleAccums ssa

			insert
				EDI3060.ShipScheduleAuthAccums
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
			)
			select
				ssaa.RawDocumentGUID
			,	ssaa.ReleaseNo
			,	ssaa.ShipToCode
			,	ssaa.ConsigneeCode
			,	ssaa.ShipFromCode
			,	ssaa.SupplierCode
			,	ssaa.CustomerPart
			,	ssaa.CustomerPO
			,	ssaa.CustomerPOLine
			,	ssaa.CustomerModelYear
			,	ssaa.CustomerECL
			,	PriorCUMStartDT =
					case
						when datalength(ssaa.AuthAccumBeginDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', ssaa.AuthAccumBeginDT)
						when datalength(ssaa.AuthAccumBeginDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', ssaa.AuthAccumBeginDT)
						else convert(datetime, ssaa.AuthAccumBeginDT)
					end
			,	PriorCUMEndDT =
					case
						when datalength(ssaa.AuthAccumEndDT) = 6
							then FXSYS.udf_GetDT('YYMMDD', ssaa.AuthAccumEndDT)
						when datalength(ssaa.AuthAccumEndDT) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', ssaa.AuthAccumEndDT)
						else convert(datetime, ssaa.AuthAccumEndDT)
					end
			,	PriorCUM = nullif(ssaa.AuthAccum, '')
			from
				@ShipScheduleAuthAccums ssaa
			
			insert
				EDI3060.ShipScheduleReleases
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
			,	UserDefined5
			,	ScheduleType
			,	ReleaseQty
			,	ReleaseDT
			)
			select
				ssr.RawDocumentGUID
			,	ssr.ReleaseNo
			,	ssr.ShipToCode
			,	ssr.ConsigneeCode
			,	ssr.ShipFromCode
			,	ssr.SupplierCode
			,	ssr.CustomerPart
			,	ssr.CustomerPO
			,	ssr.CustomerPOLine
			,	ssr.CustomerModelYear
			,	ssr.CustomerECL
			,	ssr.UserDefined5
			,	ScheduleType = ssr.QuantityType
			,	ReleaseQty = nullif(ssr.QuantityDue, '')
			,	ReleaseDT =
					case
						when datalength(ssr.DateDue) = 6
							then FXSYS.udf_GetDT('YYMMDD', ssr.DateDue)
						when datalength(ssr.DateDue) = 8
							then FXSYS.udf_GetDT('CCYYMMDD', ssr.DateDue)
						else convert(datetime, ssr.DateDue)
					end
			from
				@ShipScheduleReleases ssr

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
	@ProcReturn = EDI3060.usp_StageShipSchedules
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
