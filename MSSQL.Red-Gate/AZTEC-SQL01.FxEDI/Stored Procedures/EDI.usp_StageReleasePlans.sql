SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI].[usp_StageReleasePlans]
	@DocumentGUIDList nvarchar(max) = null
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		/*	Build new release plan headers. */
		set @TocMsg = 'Build new release plan headers'
		begin
			create table #NewReleasePlanHeader
			(	ProcessGUID uniqueidentifier default(newsequentialid()) not null primary key
			,	DocumentGUID uniqueidentifier not null
			,	ReceiveDT datetime not null
			,	TradingPartner varchar(50) not null
			,	DocType varchar(6) not null
			,	Version varchar(20) not null
			,	ICN int null
			,	TransactionSetPurposeCode varchar(3) null
			,	ReferenceIdentification varchar(80) null
			,	DocumentDate date null
			,	ScheduleTypeQualifier varchar(3) null
			,	HorizonStartDate date null
			,	HorizonEndDate date null
			,	ReleaseNumber varchar(35) null
			,	ReferenceIdentification2 varchar(80) null
			,	ContractNumber varchar(30) null
			,	PurchaseOrderNumber varchar(22) null
			,	ScheduleQuantityQualifier char(1) null

			,	ProductGroup varchar(80) null
			,	CustomReference varchar(80) null

			,	Data xml not null
			)

			insert
				#NewReleasePlanHeader
			(	DocumentGUID
			,	ReceiveDT
			,	TradingPartner
			,	DocType
			,	Version
			,	ICN

			,	TransactionSetPurposeCode
			,	ReferenceIdentification
			,	DocumentDate
			,	ScheduleTypeQualifier
			,	HorizonStartDate
			,	HorizonEndDate
			,	ReleaseNumber
			,	ContractNumber
			,	PurchaseOrderNumber
			,	ScheduleQuantityQualifier

			,	ProductGroup
			,	CustomReference

			,	Data
			)
			select
				ed.GUID
			,	ed.RowCreateDT
			,	ed.TradingPartner
			,	ed.Type
			,	ed.Version
			,	ICN = TRN_INFO.Data.value('@ICN', 'int')

			,	TransactionSetPurposeCode = SEG_BFR.Data.value('(DE[@code="0353"])[1]', 'char(2)')
			,	ReferenceIdentification   = SEG_BFR.Data.value('(DE[@code="0127"])[1]', 'varchar(80)')
			,	DocumentDate              = SEG_BFR.Data.value('(DE[@code="0373"])[3]', 'date') -- At least for Ford
			,	ScheduleTypeQualifier     = SEG_BFR.Data.value('(DE[@code="0675"])[1]', 'char(2)')
			,	HorizonStartDate          = SEG_BFR.Data.value('(DE[@code="0373"])[1]', 'date') -- At least for Ford
			,	HorizonEndDate            = SEG_BFR.Data.value('(DE[@code="0373"])[2]', 'date') -- At least for Ford
			,	ReleaseNumber             = SEG_BFR.Data.value('(DE[@code="0328"])[1]', 'varchar(30)')
			,	ContractNumber            = SEG_BFR.Data.value('(DE[@code="0367"])[1]', 'varchar(30)')
			,	PurchaseOrderNumber       = SEG_BFR.Data.value('(DE[@code="0324"])[1]', 'varchar(22)')
			,	ScheduleQuantityQualifier = SEG_BFR.Data.value('(DE[@code="0676"])[1]', 'char(1)')

			,	ProductGroup    = SEG_REF_PG.Data.value('(DE[@code="0127"])[1]', 'varchar(80)')
			,	CustomReference = SEG_REF_ZZ.Data.value('(DE[@code="0127"])[1]', 'varchar(80)')

			,	ed.Data
			from
				FxEDI.EDI.EDIDocuments ed
				left join EDI.XML_TradingPartners_StagingDefinition xtpsd
					on xtpsd.DocumentTradingPartner = ed.TradingPartner
					and xtpsd.DocumentType = ed.Type
				cross apply
					ed.Data.nodes('/TRN-830/TRN-INFO') as TRN_INFO(Data)
				cross apply
					ed.Data.nodes('/TRN-830/SEG-BFR') as SEG_BFR(Data)
				outer apply
					ed.Data.nodes('/TRN-830/SEG-REF[DE[@code="0128"][.="PG"]]') as SEG_REF_PG(Data)
				outer apply
					ed.Data.nodes('/TRN-830/SEG-REF[DE[@code="0128"][.="ZZ"]]') as SEG_REF_ZZ(Data)
			where
				ed.Type = '830'
				and
				(	(	@ProcName = xtpsd.StagingProcedureSchema + '.' + xtpsd.StagingProcedureName
						and ed.Status = 0
					)
					or	exists
						(	select
								*
							from
								FxAztec.dbo.fn_SplitStringToRows(@DocumentGUIDList, ',') fsstr
							where
								convert(uniqueidentifier, fsstr.Value) = ed.GUID
						)
				)

			if	@@ROWCOUNT = 0 begin
				goto done
			end

			if	@Debug & 0x10 = 0x10 begin

				select
					'#NewReleasePlanHeader'
				,	*
				from
					#NewReleasePlanHeader nrph
			end

			create primary xml index ixml_#NewReleasePlanHeader on #NewReleasePlanHeader(Data)

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

		/*	Build new release plan order headers. */
		set @TocMsg = 'Build new release plan order headers'
		begin
			create table
				#NewReleasePlanOrderHeader
			(	ProcessGUID uniqueidentifier not null
			,	DocumentGUID uniqueidentifier not null
			,	OrderHeaderGUID uniqueidentifier default(newsequentialid()) not null primary key

			,	CustomerPart varchar(50) null
			,	PartDescription varchar(50) null
			,	PurchaseOrderNumber varchar(50) null
			,	PurchaseOrderLine varchar(50) null
			,	EngineeringLevel varchar(50) null
			,	DrawingNumber varchar(50) null
			,	FinishNumber varchar(50) null
			,	ReleaseNumber varchar(50) null
			,	SupplierPart varchar(50) null

			,	UnitOfMeasurement varchar(3) null

			,	ShipToCode varchar(50) null
			,	ShipToName varchar(50) null
			,	ShipToAddress1 varchar(50) null
			,	ShipToAddress2 varchar(50) null
			,	ShipToCity varchar(50) null
			,	ShipToStateProvince varchar(50) null
			,	ShipToPostalCode varchar(50) null
			,	ShipToCountry varchar(50) null
			,	ShipToLocationQualifier varchar(3) null
			,	ShipToLocationIdentifier varchar(50) null
			,	ShipToCountrySubdivisionCode varchar(3) null

			,	ShipFromCode varchar(50) null
			,	ShipFromName varchar(50) null
			,	ShipFromAddress1 varchar(50) null
			,	ShipFromAddress2 varchar(50) null
			,	ShipFromCity varchar(50) null
			,	ShipFromStateProvince varchar(50) null
			,	ShipFromPostalCode varchar(50) null
			,	ShipFromCountry varchar(50) null
			,	ShipFromLocationQualifier varchar(3) null
			,	ShipFromLocationIdentifier varchar(50) null
			,	ShipFromCountrySubdivisionCode varchar(3) null

			,	SoldByCode varchar(50) null
			,	SoldByName varchar(50) null
			,	SoldByAddress1 varchar(50) null
			,	SoldByAddress2 varchar(50) null
			,	SoldByCity varchar(50) null
			,	SoldByStateProvince varchar(50) null
			,	SoldByPostalCode varchar(50) null
			,	SoldByCountry varchar(50) null
			,	SoldByLocationQualifier varchar(3) null
			,	SoldByLocationIdentifier varchar(50) null
			,	SoldByCountrySubdivisionCode varchar(3) null

			,	ConsignedToCode varchar(50) null
			,	ConsignedToName varchar(50) null
			,	ConsignedToAddress1 varchar(50) null
			,	ConsignedToAddress2 varchar(50) null
			,	ConsignedToCity varchar(50) null
			,	ConsignedToStateProvince varchar(50) null
			,	ConsignedToPostalCode varchar(50) null
			,	ConsignedToCountry varchar(50) null
			,	ConsignedToLocationQualifier varchar(3) null
			,	ConsignedToLocationIdentifier varchar(50) null
			,	ConsignedToCountrySubdivisionCode varchar(3) null

			,	MaterialIssuerCode varchar(50) null
			,	MaterialIssuerName varchar(50) null
			,	MaterialIssuerAddress1 varchar(50) null
			,	MaterialIssuerAddress2 varchar(50) null
			,	MaterialIssuerCity varchar(50) null
			,	MaterialIssuerStateProvince varchar(50) null
			,	MaterialIssuerPostalCode varchar(50) null
			,	MaterialIssuerCountry varchar(50) null
			,	MaterialIssuerLocationQualifier varchar(3) null
			,	MaterialIssuerLocationIdentifier varchar(50) null
			,	MaterialIssuerCountrySubdivisionCode varchar(3) null

			,	BillToCode varchar(50) null
			,	BillToName varchar(50) null
			,	BillToAddress1 varchar(50) null
			,	BillToAddress2 varchar(50) null
			,	BillToCity varchar(50) null
			,	BillToStateProvince varchar(50) null
			,	BillToPostalCode varchar(50) null
			,	BillToCountry varchar(50) null
			,	BillToLocationQualifier varchar(3) null
			,	BillToLocationIdentifier varchar(50) null
			,	BillToCountrySubdivisionCode varchar(3) null

			,	ExpeditorContactName varchar(50) null
			,	ExpeditorTelephone varchar(50) null
			,	ExpeditorRequestReferenceNumber varchar(50) null
	
			,	PackingMarks11Z varchar(50) null
			,	PackingMarks12Z varchar(50) null
			,	PackingMarks13Z varchar(50) null
			,	PackingMarks14Z varchar(50) null
			,	PackingMarks15Z varchar(50) null
			,	PackingMarks16Z varchar(50) null
			,	PackingMarks17Z varchar(50) null

			,	ModelYear varchar(20) null
			,	DockCode varchar(20) null
			,	LineFeedCode varchar(20) null
			,	ReserveLineFeedCode varchar(20) null
			,	WarehouseStorage varchar(20) null

			,	LastShippedQty numeric(20,6) null
			,	LastShippedDate date null
			,	LastShippedID varchar(50) null
			,	LastShippedAccum numeric(20,6) null
			,	LastShippedBeginDate date null
			,	LastShippedEndDate date null

			,	HorizonAccum numeric(20,6) null
			,	HorizonStartDate Date null
			,	HorizonEndDate Date null

			,	RawAuthorizationAccum numeric(20,6) null
			,	RawAuthorizationStartDate Date null
			,	RawAuthorizationEndDate Date null
	
			,	FabAuthorizationAccum numeric(20,6) null
			,	FabAuthorizationStartDate Date null
			,	FabAuthorizationEndDate Date null
			,	Data xml not null
			)

			insert
				#NewReleasePlanOrderHeader
			(	ProcessGUID
			,	DocumentGUID

			,	CustomerPart
			,	PartDescription
			,	EngineeringLevel
			,	DrawingNumber
			,	FinishNumber

			,	SupplierPart

			,	PurchaseOrderNumber
			,	PurchaseOrderLine
			,	ReleaseNumber

			,	ShipToCode
			,	ShipToName
			,	ShipToAddress1
			,	ShipToAddress2
			,	ShipToCity
			,	ShipToStateProvince
			,	ShipToPostalCode
			,	ShipToCountry

			,	ShipFromCode
			,	ShipFromName
			,	ShipFromAddress1
			,	ShipFromAddress2
			,	ShipFromCity
			,	ShipFromStateProvince
			,	ShipFromPostalCode
			,	ShipFromCountry

			,	SoldByCode
			,	SoldByName
			,	SoldByAddress1
			,	SoldByAddress2
			,	SoldByCity
			,	SoldByStateProvince
			,	SoldByPostalCode
			,	SoldByCountry

			,	ConsignedToCode
			,	ConsignedToName
			,	ConsignedToAddress1
			,	ConsignedToAddress2
			,	ConsignedToCity
			,	ConsignedToStateProvince
			,	ConsignedToPostalCode
			,	ConsignedToCountry

			,	MaterialIssuerCode
			,	MaterialIssuerName
			,	MaterialIssuerAddress1
			,	MaterialIssuerAddress2
			,	MaterialIssuerCity
			,	MaterialIssuerStateProvince
			,	MaterialIssuerPostalCode
			,	MaterialIssuerCountry

			,	BillToCode
			,	BillToName
			,	BillToAddress1
			,	BillToAddress2
			,	BillToCity
			,	BillToStateProvince
			,	BillToPostalCode
			,	BillToCountry

			,	DockCode
			,	LineFeedCode

			,	LastShippedQty
			,	LastShippedDate
			,	LastShippedID

			,	LastShippedAccum
			,	LastShippedBeginDate
			,	LastShippedEndDate

			,	HorizonAccum
			,	HorizonStartDate
			,	HorizonEndDate

			,	RawAuthorizationAccum
			,	RawAuthorizationStartDate
			,	RawAuthorizationEndDate

			,	FabAuthorizationAccum
			,	FabAuthorizationStartDate
			,	FabAuthorizationEndDate

			,	UnitOfMeasurement

			,	Data
			)
			select
				ed.ProcessGUID
			,	ed.DocumentGUID

			,	CustomerPart        = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	PartDescription     = coalesce(LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="PD" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)'), LOOP_LIN.Data.value('(SEG-PID[DE[@code="0349"][.="F"]]/DE[@code="0352"])[1]', 'varchar(80)'))
			,	EngineeringLevel    = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="EC" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	DrawingNumber       = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="DR" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	FinishNumber        = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="FI" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')

			,	SupplierPart        = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="VP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')

			,	PurchaseOrderNumber = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	PurchaseOrderLine   = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
			,	ReleaseNumber       = LOOP_LIN.Data.value ('(for $a in SEG-LIN/DE[@code="0235"] where $a="RN" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')

			,	ShipToCode          = coalesce(LOOP_N1_ST.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)'))
			,	ShipToName          = coalesce(LOOP_N1_ST.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)'))
			,	ShipToAddress1      = coalesce(LOOP_N1_ST.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)'))
			,	ShipToAddress2      = coalesce(LOOP_N1_ST.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)'))
			,	ShipToCity          = coalesce(LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)'))
			,	ShipToStateProvince = coalesce(LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')    , LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)'))
			,	ShipToPostalCode    = coalesce(LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)'), LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)'))
			,	ShipToCountry       = coalesce(LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)') , LOOP_LIN_LOOP_N1_ST.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)'))

			,	ShipFromCode          = LOOP_N1_SF.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)')
			,	ShipFromName          = LOOP_N1_SF.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)')
			,	ShipFromAddress1      = LOOP_N1_SF.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)')
			,	ShipFromAddress2      = LOOP_N1_SF.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)')
			,	ShipFromCity          = LOOP_N1_SF.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)')
			,	ShipFromStateProvince = LOOP_N1_SF.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')
			,	ShipFromPostalCode    = LOOP_N1_SF.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)')
			,	ShipFromCountry       = LOOP_N1_SF.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)')

			,	SupplierCode          = LOOP_N1_SU.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)')
			,	SupplierName          = LOOP_N1_SU.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)')
			,	SupplierAddress1      = LOOP_N1_SU.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)')
			,	SupplierAddress2      = LOOP_N1_SU.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)')
			,	SupplierCity          = LOOP_N1_SU.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)')
			,	SupplierStateProvince = LOOP_N1_SU.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')
			,	SupplierPostalCode    = LOOP_N1_SU.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)')
			,	SupplierCountry       = LOOP_N1_SU.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)')

			,	ConsigneeCode          = LOOP_N1_IC.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)')
			,	ConsigneeName          = LOOP_N1_IC.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)')
			,	ConsigneeAddress1      = LOOP_N1_IC.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)')
			,	ConsigneeAddress2      = LOOP_N1_IC.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)')
			,	ConsigneeCity          = LOOP_N1_IC.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)')
			,	ConsigneeStateProvince = LOOP_N1_IC.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')
			,	ConsigneePostalCode    = LOOP_N1_IC.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)')
			,	ConsigneeCountry       = LOOP_N1_IC.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)')

			,	MaterialIssuerCode          = LOOP_N1_MI.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)')
			,	MaterialIssuerName          = LOOP_N1_MI.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)')
			,	MaterialIssuerAddress1      = LOOP_N1_MI.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)')
			,	MaterialIssuerAddress2      = LOOP_N1_MI.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)')
			,	MaterialIssuerCity          = LOOP_N1_MI.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)')
			,	MaterialIssuerStateProvince = LOOP_N1_MI.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')
			,	MaterialIssuerPostalCode    = LOOP_N1_MI.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)')
			,	MaterialIssuerCountry       = LOOP_N1_MI.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)')

			,	BillToCode          = LOOP_N1_BT.Data.value('(./SEG-N1[1]/DE[@code="0067"])[1]', 'varchar(80)')
			,	BillToName          = LOOP_N1_BT.Data.value('(./SEG-N1[1]/DE[@code="0093"])[1]', 'varchar(60)')
			,	BillToAddress1      = LOOP_N1_BT.Data.value('(./SEG-N3[1]/DE[@code="0166"])[1]', 'varchar(55)')
			,	BillToAddress2      = LOOP_N1_BT.Data.value('(./SEG-N3[1]/DE[@code="0166"])[2]', 'varchar(55)')
			,	BillToCity          = LOOP_N1_BT.Data.value('(./SEG-N4[1]/DE[@code="0019"])[1]', 'varchar(30)')
			,	BillToStateProvince = LOOP_N1_BT.Data.value('(./SEG-N4[1]/DE[@code="0156"])[1]', 'char(2)')
			,	BillToPostalCode    = LOOP_N1_BT.Data.value('(./SEG-N4[1]/DE[@code="0116"])[1]', 'varchar(15)')
			,	BillToCountry       = LOOP_N1_BT.Data.value('(./SEG-N4[1]/DE[@code="0026"])[1]', 'varchar(3)')

			,	DockCode        = LOOP_LIN.Data.value ('(SEG-REF[DE[@code="0128"][.="DK"]]/DE[@code="0127"])[1]', 'varchar(20)')
			,	LineFeedCode    = LOOP_LIN.Data.value ('(SEG-REF[DE[@code="0128"][.="LF"]]/DE[@code="0127"])[1]', 'varchar(20)')

			,	LastShippedQty        = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="01"]]/SEG-SHP/DE[@code="0380"])[1]', 'float')
			,	LastShippedDate       = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="01"]]/SEG-SHP/DE[@code="0373"])[1]', 'date')
			,	LastShippedID         = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="01"]]/SEG-REF[DE[@code="0128"][.="SI"]]/DE[@code="0127"])[1]', 'varchar(80)')

			,	LastShippedAccum      = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="02"]]/SEG-SHP/DE[@code="0380"])[1]', 'float')
			,	LastShippedBeginDate  = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="02"]]/SEG-SHP/DE[@code="0373"])[1]', 'date')
			,	LastShippedEndDate    = LOOP_LIN.Data.value('(LOOP-SHP[SEG-SHP/DE[@code="0673"][.="02"]]/SEG-SHP/DE[@code="0373"])[2]', 'date')

			,	HorizonAccum     = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="PQ"]]/DE[@code="0380"])[1]', 'float')
			,	HorizonStartDate = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="PQ"]]/DE[@code="0373"])[2]', 'date')
			,	HorizonEndDate   = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="PQ"]]/DE[@code="0373"])[1]', 'date')

			,	RawAuthorizationAccum     = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="MT"]]/DE[@code="0380"])[1]', 'float')
			,	RawAuthorizationStartDate = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="MT"]]/DE[@code="0373"])[2]', 'date')
			,	RawAuthorizationEndDate   = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="MT"]]/DE[@code="0373"])[1]', 'date')

			,	FabAuthorizationAccum     = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="FI"]]/DE[@code="0380"])[1]', 'float')
			,	FabAuthorizationStartDate = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="FI"]]/DE[@code="0373"])[2]', 'date')
			,	FabAuthorizationEndDate   = LOOP_LIN.Data.value('(SEG-ATH[DE[@code="0672"][.="FI"]]/DE[@code="0373"])[1]', 'date')

			,	UnitOfMeasurement = LOOP_LIN.Data.value('(SEG-UNT/DE[@code="0355"])[1]', 'varchar(3)')

			,	LOOP_LIN.Data.query('.')
			from
				--EDI.EDIDocument ed
				#NewReleasePlanHeader ed
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-LIN') as LOOP_LIN(Data)
				outer apply
					LOOP_LIN.Data.nodes('./LOOP-N1 [SEG-N1 [DE [.="ST"][@code="0098"]]]') as LOOP_LIN_LOOP_N1_ST(Data) 

				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="BT"][@code="0098"]]]') as LOOP_N1_BT(Data) 
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="IC"][@code="0098"]]]') as LOOP_N1_IC(Data) 
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="SF"][@code="0098"]]]') as LOOP_N1_SF(Data) 
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="MI"][@code="0098"]]]') as LOOP_N1_MI(Data) 
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="ST"][@code="0098"]]]') as LOOP_N1_ST(Data) 
				outer apply
					ed.Data.nodes('/TRN-830/LOOP-N1 [SEG-N1 [DE [.="SU"][@code="0098"]]]') as LOOP_N1_SU(Data) 

			if	@Debug & 0x10 = 0x10 begin

				select
					'#NewReleasePlanOrderHeader'
				,	*
				from
					#NewReleasePlanOrderHeader nrpoh
			end

			create primary xml index ixml_#NewReleasePlanOrderHeader on #NewReleasePlanOrderHeader(Data)
				
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
		
		/*	Build new release plan releases. */
		set @TocMsg = 'Build new release plan releases'
		begin
			create table
				#NewReleasePlanRelease
			(	ProcessGUID uniqueidentifier not null
			,	DocumentGUID uniqueidentifier not null
			,	OrderHeaderGUID uniqueidentifier not null
			,	ReleaseGUID uniqueidentifier default(newsequentialid()) not null unique

			,	AccumQuantity numeric(20,6) null
			,	DiscreteQuantity numeric(20,6) null
			,	ReleasePeriodCode varchar(3)  null
			,	ReleaseTypeCode char(1) null
			,	ReleaseDateTime datetime null
			,	ReleaseBeginDate date null

			,	ScheduleQuantityQualifier char(1) null
			,	ReferenceAccum numeric(20,6) null

			,	RowID int not null IDENTITY(1, 1) primary key
			)

			insert
				#NewReleasePlanRelease
			(	ProcessGUID
			,	DocumentGUID
			,	OrderHeaderGUID

			,	AccumQuantity
			,	DiscreteQuantity
			,	ReleasePeriodCode
			,	ReleaseTypeCode
			,	ReleaseDateTime
			,	ReleaseBeginDate

			,	ScheduleQuantityQualifier
			,	ReferenceAccum
			)
			select
				ed.ProcessGUID
			,	ed.DocumentGUID
			,	ed.OrderHeaderGUID

			,	AccumQuantity     = case when rtrim(nrph.ScheduleQuantityQualifier) = 'C' then LOOP_FST.Data.value('(DE[@code="0380"])[1]', 'float') end
			,	DiscreteQuantity  = case when rtrim(nrph.ScheduleQuantityQualifier) = 'A' then LOOP_FST.Data.value('(DE[@code="0380"])[1]', 'float') end
			,	ReleasePeriodCode = LOOP_FST.Data.value('(DE[@code="0680"])[1]', 'char(1)')
			,	ReleaseTypeCode   = LOOP_FST.Data.value('(DE[@code="0681"])[1]', 'char(1)')
			,	ReleaseDate       = case when LOOP_FST.Data.value('(DE[@code="0681"])[1]', 'char(1)') = 'F' then LOOP_FST.Data.value('(DE[@code="0373"])[2]', 'date') else LOOP_FST.Data.value('(DE[@code="0373"])[1]', 'date') end
			,	ReleaseBeginDate  = case when LOOP_FST.Data.value('(DE[@code="0681"])[1]', 'char(1)') = 'F' then LOOP_FST.Data.value('(DE[@code="0373"])[1]', 'date') else null end

			,	rtrim(nrph.ScheduleQuantityQualifier)
			,	coalesce(ed.LastShippedAccum, ed.HorizonAccum,0)
			from
				#NewReleasePlanOrderHeader ed
				join #NewReleasePlanHeader nrph
					on nrph.DocumentGUID = ed.DocumentGUID
				cross apply
					ed.Data.nodes('LOOP-LIN/SEG-FST, LOOP-LIN/LOOP-SDP/SEG-FST') as LOOP_FST(Data)

			if	@Debug & 0x10 = 0x10 begin

				select
					'#NewReleasePlanRelease (Orig)'
				,	*
				from
					#NewReleasePlanRelease nrpr
			end

			update
				nrpr
			set
				AccumQuantity = nrprA.AccumQuantity
			from
				#NewReleasePlanRelease nrpr
				join
					(	select
							AccumQuantity = ReferenceAccum + sum(nrpr.DiscreteQuantity) over(partition by nrpr.OrderHeaderGUID order by nrpr.ReleaseDateTime)
						,	nrpr.RowID
						from
							#NewReleasePlanRelease nrpr
					) nrprA
					on nrprA.RowID = nrpr.RowID
			where
				nrpr.ScheduleQuantityQualifier = 'A'

			update
				nrpr
			set DiscreteQuantity = nrpr.AccumQuantity - coalesce(nrpr2.AccumQuantity, nrpr.ReferenceAccum)
			from
				#NewReleasePlanRelease nrpr
				left join #NewReleasePlanRelease nrpr2
					on nrpr2.RowID + 1 = nrpr.RowID
					and nrpr2.OrderHeaderGUID = nrpr.OrderHeaderGUID
			where
				nrpr.ScheduleQuantityQualifier = 'C'

			if	@Debug & 0x10 = 0x10 begin

				select
					'#NewReleasePlanRelease (Final)'
				,	*
				from
					#NewReleasePlanRelease nrpr
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
		
		/*	Write out data and set status. */
		set @TocMsg = 'Write out data and set status'
		begin
			insert
				FxAztec.EDI.DocumentHeader
			(	ProcessGUID
			,	DocumentGUID

			,	ReceiveDT
			,	TradingPartner
			,	DocType
			,	Version
			,	ICN
			,	TransactionSetPurposeCode
			,	ReferenceIdentification
			,	DocumentDate
			,	ScheduleTypeQualifier
			,	HorizonStartDate
			,	HorizonEndDate
			,	ReleaseNumber
			,	ReferenceIdentification2
			,	ContractNumber
			,	PurchaseOrderNumber
			,	ScheduleQuantityQualifier
			,	ProductGroup
			,	CustomReference
			)
			select
				nrph.ProcessGUID
			,	nrph.DocumentGUID

			,	nrph.ReceiveDT
			,	nrph.TradingPartner
			,	nrph.DocType
			,	nrph.Version
			,	nrph.ICN
			,	nrph.TransactionSetPurposeCode
			,	nrph.ReferenceIdentification
			,	nrph.DocumentDate
			,	nrph.ScheduleTypeQualifier
			,	nrph.HorizonStartDate
			,	nrph.HorizonEndDate
			,	nrph.ReleaseNumber
			,	nrph.ReferenceIdentification2
			,	nrph.ContractNumber
			,	nrph.PurchaseOrderNumber
			,	nrph.ScheduleQuantityQualifier
			,	nrph.ProductGroup
			,	nrph.CustomReference
			from
				#NewReleasePlanHeader nrph

			insert
				FxAztec.EDI.OrderHeader
			(	ProcessGUID
			,	DocumentGUID
			,	OrderHeaderGUID

			,	CustomerPart
			,	PartDescription
			,	PurchaseOrderNumber
			,	PurchaseOrderLine
			,	EngineeringLevel
			,	DrawingNumber
			,	FinishNumber
			,	ReleaseNumber
			,	SupplierPart
			,	UnitOfMeasurement
			,	ShipToCode
			,	ShipToName
			,	ShipToAddress1
			,	ShipToAddress2
			,	ShipToCity
			,	ShipToStateProvince
			,	ShipToPostalCode
			,	ShipToCountry
			,	ShipToLocationQualifier
			,	ShipToLocationIdentifier
			,	ShipToCountrySubdivisionCode
			,	ShipFromCode
			,	ShipFromName
			,	ShipFromAddress1
			,	ShipFromAddress2
			,	ShipFromCity
			,	ShipFromStateProvince
			,	ShipFromPostalCode
			,	ShipFromCountry
			,	ShipFromLocationQualifier
			,	ShipFromLocationIdentifier
			,	ShipFromCountrySubdivisionCode
			,	SoldByCode
			,	SoldByName
			,	SoldByAddress1
			,	SoldByAddress2
			,	SoldByCity
			,	SoldByStateProvince
			,	SoldByPostalCode
			,	SoldByCountry
			,	SoldByLocationQualifier
			,	SoldByLocationIdentifier
			,	SoldByCountrySubdivisionCode
			,	ConsignedToCode
			,	ConsignedToName
			,	ConsignedToAddress1
			,	ConsignedToAddress2
			,	ConsignedToCity
			,	ConsignedToStateProvince
			,	ConsignedToPostalCode
			,	ConsignedToCountry
			,	ConsignedToLocationQualifier
			,	ConsignedToLocationIdentifier
			,	ConsignedToCountrySubdivisionCode
			,	MaterialIssuerCode
			,	MaterialIssuerName
			,	MaterialIssuerAddress1
			,	MaterialIssuerAddress2
			,	MaterialIssuerCity
			,	MaterialIssuerStateProvince
			,	MaterialIssuerPostalCode
			,	MaterialIssuerCountry
			,	MaterialIssuerLocationQualifier
			,	MaterialIssuerLocationIdentifier
			,	MaterialIssuerCountrySubdivisionCode
			,	BillToCode
			,	BillToName
			,	BillToAddress1
			,	BillToAddress2
			,	BillToCity
			,	BillToStateProvince
			,	BillToPostalCode
			,	BillToCountry
			,	BillToLocationQualifier
			,	BillToLocationIdentifier
			,	BillToCountrySubdivisionCode
			,	ExpeditorContactName
			,	ExpeditorTelephone
			,	ExpeditorRequestReferenceNumber
			,	PackingMarks11Z
			,	PackingMarks12Z
			,	PackingMarks13Z
			,	PackingMarks14Z
			,	PackingMarks15Z
			,	PackingMarks16Z
			,	PackingMarks17Z
			,	ModelYear
			,	DockCode
			,	LineFeedCode
			,	ReserveLineFeedCode
			,	WarehouseStorage
			,	LastShippedQty
			,	LastShippedDate
			,	LastShippedID
			,	LastShippedAccum
			,	LastShippedBeginDate
			,	LastShippedEndDate
			,	HorizonAccum
			,	HorizonStartDate
			,	HorizonEndDate
			,	RawAuthorizationAccum
			,	RawAuthorizationStartDate
			,	RawAuthorizationEndDate
			,	FabAuthorizationAccum
			,	FabAuthorizationStartDate
			,	FabAuthorizationEndDate
			)

			select
				nrpoh.ProcessGUID
			,	nrpoh.DocumentGUID
			,	nrpoh.OrderHeaderGUID

			,	nrpoh.CustomerPart
			,	nrpoh.PartDescription
			,	nrpoh.PurchaseOrderNumber
			,	nrpoh.PurchaseOrderLine
			,	nrpoh.EngineeringLevel
			,	nrpoh.DrawingNumber
			,	nrpoh.FinishNumber
			,	nrpoh.ReleaseNumber
			,	nrpoh.SupplierPart
			,	nrpoh.UnitOfMeasurement
			,	nrpoh.ShipToCode
			,	nrpoh.ShipToName
			,	nrpoh.ShipToAddress1
			,	nrpoh.ShipToAddress2
			,	nrpoh.ShipToCity
			,	nrpoh.ShipToStateProvince
			,	nrpoh.ShipToPostalCode
			,	nrpoh.ShipToCountry
			,	nrpoh.ShipToLocationQualifier
			,	nrpoh.ShipToLocationIdentifier
			,	nrpoh.ShipToCountrySubdivisionCode
			,	nrpoh.ShipFromCode
			,	nrpoh.ShipFromName
			,	nrpoh.ShipFromAddress1
			,	nrpoh.ShipFromAddress2
			,	nrpoh.ShipFromCity
			,	nrpoh.ShipFromStateProvince
			,	nrpoh.ShipFromPostalCode
			,	nrpoh.ShipFromCountry
			,	nrpoh.ShipFromLocationQualifier
			,	nrpoh.ShipFromLocationIdentifier
			,	nrpoh.ShipFromCountrySubdivisionCode
			,	nrpoh.SoldByCode
			,	nrpoh.SoldByName
			,	nrpoh.SoldByAddress1
			,	nrpoh.SoldByAddress2
			,	nrpoh.SoldByCity
			,	nrpoh.SoldByStateProvince
			,	nrpoh.SoldByPostalCode
			,	nrpoh.SoldByCountry
			,	nrpoh.SoldByLocationQualifier
			,	nrpoh.SoldByLocationIdentifier
			,	nrpoh.SoldByCountrySubdivisionCode
			,	nrpoh.ConsignedToCode
			,	nrpoh.ConsignedToName
			,	nrpoh.ConsignedToAddress1
			,	nrpoh.ConsignedToAddress2
			,	nrpoh.ConsignedToCity
			,	nrpoh.ConsignedToStateProvince
			,	nrpoh.ConsignedToPostalCode
			,	nrpoh.ConsignedToCountry
			,	nrpoh.ConsignedToLocationQualifier
			,	nrpoh.ConsignedToLocationIdentifier
			,	nrpoh.ConsignedToCountrySubdivisionCode
			,	nrpoh.MaterialIssuerCode
			,	nrpoh.MaterialIssuerName
			,	nrpoh.MaterialIssuerAddress1
			,	nrpoh.MaterialIssuerAddress2
			,	nrpoh.MaterialIssuerCity
			,	nrpoh.MaterialIssuerStateProvince
			,	nrpoh.MaterialIssuerPostalCode
			,	nrpoh.MaterialIssuerCountry
			,	nrpoh.MaterialIssuerLocationQualifier
			,	nrpoh.MaterialIssuerLocationIdentifier
			,	nrpoh.MaterialIssuerCountrySubdivisionCode
			,	nrpoh.BillToCode
			,	nrpoh.BillToName
			,	nrpoh.BillToAddress1
			,	nrpoh.BillToAddress2
			,	nrpoh.BillToCity
			,	nrpoh.BillToStateProvince
			,	nrpoh.BillToPostalCode
			,	nrpoh.BillToCountry
			,	nrpoh.BillToLocationQualifier
			,	nrpoh.BillToLocationIdentifier
			,	nrpoh.BillToCountrySubdivisionCode
			,	nrpoh.ExpeditorContactName
			,	nrpoh.ExpeditorTelephone
			,	nrpoh.ExpeditorRequestReferenceNumber
			,	nrpoh.PackingMarks11Z
			,	nrpoh.PackingMarks12Z
			,	nrpoh.PackingMarks13Z
			,	nrpoh.PackingMarks14Z
			,	nrpoh.PackingMarks15Z
			,	nrpoh.PackingMarks16Z
			,	nrpoh.PackingMarks17Z
			,	nrpoh.ModelYear
			,	nrpoh.DockCode
			,	nrpoh.LineFeedCode
			,	nrpoh.ReserveLineFeedCode
			,	nrpoh.WarehouseStorage
			,	nrpoh.LastShippedQty
			,	nrpoh.LastShippedDate
			,	nrpoh.LastShippedID
			,	nrpoh.LastShippedAccum
			,	nrpoh.LastShippedBeginDate
			,	nrpoh.LastShippedEndDate
			,	nrpoh.HorizonAccum
			,	nrpoh.HorizonStartDate
			,	nrpoh.HorizonEndDate
			,	nrpoh.RawAuthorizationAccum
			,	nrpoh.RawAuthorizationStartDate
			,	nrpoh.RawAuthorizationEndDate
			,	nrpoh.FabAuthorizationAccum
			,	nrpoh.FabAuthorizationStartDate
			,	nrpoh.FabAuthorizationEndDate
			from
				#NewReleasePlanOrderHeader nrpoh

			insert
				FxAztec.EDI.OrderRelease
			(	ProcessGUID
			,	DocumentGUID
			,	OrderHeaderGUID
			,	ReleaseGUID

			,	AccumQuantity
			,	DiscreteQuantity
			,	ReleasePeriodCode
			,	ReleaseTypeCode
			,	ReleaseDateTime
			,	ReleaseBeginDate
			,	ScheduleQuantityQualifier
			,	ReferenceAccum
			)
			select
				nrpr.ProcessGUID
			,	nrpr.DocumentGUID
			,	nrpr.OrderHeaderGUID
			,	nrpr.ReleaseGUID

			,	nrpr.AccumQuantity
			,	nrpr.DiscreteQuantity
			,	nrpr.ReleasePeriodCode
			,	nrpr.ReleaseTypeCode
			,	nrpr.ReleaseDateTime
			,	nrpr.ReleaseBeginDate
			,	nrpr.ScheduleQuantityQualifier
			,	nrpr.ReferenceAccum
			from
				#NewReleasePlanRelease nrpr

			update
				ed
			set ed.Status = 1
			from
				FxEDI.EDI.EDIDocument ed
				join #NewReleasePlanHeader nrph
					on nrph.DocumentGUID = ed.GUID
				
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
	@ProcReturn = EDI.usp_StageReleasePlans
	@TranDT = @TranDT out
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
