SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [EDIToyota].[usp_Stage_1]
	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
AS
set nocount on
set ansi_warnings on
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Look for documents already in the queue.*/
if	exists
	(	select
			1
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	)
	or exists
	(	select
			1
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin
	goto queueError
end

/*	Move new and reprocessed Chrysler 862s and 830s to Staging. */
/*		Set new and requeued documents to in process.*/
--- <Update rows="*">
set	@TableName = 'EDI.EDIDocuments'

if	exists
	(	select
			1
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status in
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) begin
	
	update
		ed
	set
		Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '862'
		and  left(ed.EDIStandard,6) = '00TOYO' 
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status in
			(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
			,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
			)
		and not exists
		(	select
				1
			from
				EDI.EDIDocuments ed
			where
				ed.Type = '862'
				and  left(ed.EDIStandard,6) = '00TOYO' 
				--and ed.TradingPartner in ( 'MPT MUNCIE' )
				and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
		)
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		GOTO queueError
	END
END
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDI.EDIDocuments'

if	exists
	(	select
			1
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status in
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) begin
		
	update
		ed
	set
		Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '830'
		and  left(ed.EDIStandard,6) = '00TOYO' 
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status in
			(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
			,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
			)
		and not exists
		(	select
				1
			from
				EDI.EDIDocuments ed
			where
				ed.Type = '830'
				and  left(ed.EDIStandard,6) = '00TOYO' 
				--and ed.TradingPartner in ( 'MPT MUNCIE' )
				and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
		)

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		GOTO queueError
	END
END
--- </Update>

/*	Prepare data for Staging Tables...*/
/*		- prepare Ship Schedules...*/
if	exists
	(	select
			1
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin

/*			- prepare Ship Schedules Headers.*/
	declare
		@ShipScheduleHeaders table
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
	)

	insert
		@ShipScheduleHeaders
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
	,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	,	DocNumber
	,	ControlNumber
	,	DocumentDT = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[1]', 'datetime'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[1]', 'datetime'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '862'
		and  left(ed.EDIStandard,6) = '00TOYO' 
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	--select * from @ShipScheduleHeaders

/*			- prepare Ship Schedules Supplemental.*/
	begin

		declare
			@ShipScheduleSupplemental table
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
		,	UserDefined1 varchar(50) --Dock Code
		,	UserDefined2 varchar(50) --Line Feed Code	
		,	UserDefined3 varchar(50) --Reserve Line Feed Code
		,	UserDefined4 varchar(50) --Zone code
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

		declare
			@ShipScheduleSupplementalTemp1 table
		(	RawDocumentGUID uniqueidentifier
		,	ReleaseNo varchar(50)
		,	ShipToCode varchar(50)
		,	ConsigneeCode varchar(50)
		,	ShipFromCode varchar(50)
		,	SupplierCode varchar(50)	
		,	Data xml
		)

		declare
			@ShipScheduleSupplementalTemp2 table
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
		)

		declare
			@ShipScheduleSupplementalTemp3 table
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
		,	Value varchar (50)
		)

		insert
			@ShipScheduleSupplementalTemp1
		(	RawDocumentGUID
		,	ReleaseNo 
		,	ShipToCode 
		,	ConsigneeCode 
		,	ShipFromCode 
		,	SupplierCode	
		,	Data	
		)
	
		select
			RawDocumentGUID
		,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	--	,	ShipToCode = coalesce(EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)'), EDIData.Releases.value('(../SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')) -- Use if Dock Code is used as Fx Destination
		,	ShipToCode = coalesce
				(	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')
				,	EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
				, 	EDIData.Releases.value('(../SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				, 	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				) -- Use if Material Issuer is used as Fx Destination
		,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
		,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
		,	SupplierCode = coalesce
				(	nullif(ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)'), '')
				,	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				)
		,	Data = EDIData.Releases.query('.')
		from
			@ShipScheduleHeaders ed
			cross apply ed.Data.nodes('/TRN-862/LOOP-LIN') as EDIData(Releases)
	
		insert
			@ShipScheduleSupplementalTemp2
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
		,	ReleaseNo 
		,	ShipToCode 
		,	ConsigneeCode 
		,	ShipFromCode 
		,	SupplierCode	
		,	CustomerPart =ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerPO = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerPOLine = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerModelYear = ''
		,	CustomerECL = ''
		,	Data = EDIData.Data.query('.')
	
		from
			@ShipScheduleSupplementalTemp1 ed
			cross apply ed.data.nodes('/LOOP-LIN/SEG-REF') as EDIData(Data)
		order by
			2
		,	3
		,	7

		insert
			@ShipScheduleSupplementalTemp3
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
			RawDocumentGUID
		,	ReleaseNo 
		,	ShipToCode 
		,	ConsigneeCode 
		,	ShipFromCode 
		,	SupplierCode	
		,	CustomerPart 
		,	CustomerPO
		, CustomerPOLine 
		,	CustomerModelYear
		,	CustomerECL
		,	ValueQualifier	=	ed.data.value('(/SEG-REF/DE[@code="0128"])[1]', 'varchar(50)')	
		,	Value		=	ed.data.value('(/SEG-REF/DE[@code="0127"])[1]', 'varchar(50)')	
	
		from
			@ShipScheduleSupplementalTemp2 ed
		order by
			2
		,	3
		,	7

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
		,	UserDefined4 = max(case when ValueQualifier = 'RU' then Value end) --Route - Indicates what truck is picing up. To be used to create a unique pickup in Fx ( per route abd pickup date) asb FT 2016-06-20
		,	UserDefined5 = max(case when ValueQualifier = 'WS' then Value end)
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
			@ShipScheduleSupplementalTemp3
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

		--select * From @ShipScheduleSupplementalTemp1
		--select * From @ShipScheduleSupplementalTemp2
		--select * From @ShipScheduleSupplementalTemp3
		--select * from @ShipScheduleSupplemental
	end

/*			- prepare Ship Schedules Releases.*/
	begin

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
		,	UserDefined1 varchar(50) 
		,	UserDefined2 varchar(50) 
		,	UserDefined3 varchar(50) 
		,	UserDefined4 varchar(50)
		,	UserDefined5 varchar(50)
		,	DateDue varchar(50)
		,	QuantityDue varchar(50)
		,	QuantityType varchar(50)
	
		)

		declare
			@ShipSchedulesTemp1 table
		(	RawDocumentGUID uniqueidentifier
		,	ReleaseNo varchar(50)
		,	ShipToCode varchar(50)
		,	ConsigneeCode varchar(50)
		,	ShipFromCode varchar(50)
		,	SupplierCode varchar(50)	
		,	Data xml
		)

		declare
			@ShipSchedulesTemp2 table
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
		,	RouteCode VARCHAR(50)	
		,	Data xml
		)

		declare
			@ShipSchedulesTemp3 table
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
			@ShipSchedulesTemp1
		(	RawDocumentGUID
		,	ReleaseNo 
		,	ShipToCode 
		,	ConsigneeCode 
		,	ShipFromCode 
		,	SupplierCode	
		,	Data	
		)
	
		select
			RawDocumentGUID
		,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
		--	,	ShipToCode = coalesce(EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)'), EDIData.Releases.value('(../SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')) -- Use if Dock Code is used as Fx Destination
		,	ShipToCode = coalesce
				(	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')
				,	EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
				, 	EDIData.Releases.value('(../SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				, 	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				) -- Use if Material Issuer is used as Fx Destination
		,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
		,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
		,	SupplierCode = coalesce
				(	nullif(ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)'), '')
				,	ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
				)
		,	Data = EDIData.Releases.query('.')
		from
			@ShipScheduleHeaders ed
			cross apply ed.Data.nodes('/TRN-862/LOOP-LIN') as EDIData(Releases)
	
		insert
			@ShipSchedulesTemp2
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
		,	RouteCode
		,	Data	
		)
		select
			RawDocumentGUID
		,	ReleaseNo 
		,	ShipToCode 
		,	ConsigneeCode 
		,	ShipFromCode 
		,	SupplierCode	
		,	CustomerPart =ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerPO = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerPOLine = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
		,	CustomerModelYear = ''
		,	CustomerECL = ''
		,	RouteCode = ed.Data.value('(	for $a in LOOP-LIN/SEG-REF/DE[@code="0128"] where $a="RU" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)')
		,	Data = EDIData.Data.query('.')
	
		from
			@ShipSchedulesTemp1 ed
			cross apply ed.Data.nodes('/LOOP-LIN/LOOP-SHP,/LOOP-LIN/LOOP-FST') as EDIData(Data)
		order by
			2
		,	3
		,	7
		
		insert
			@ShipSchedulesTemp3
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
		,	UserDefined1 = coalesce
				(	Data.value ('(/LOOP-SHP/SEG-REF [DE[.="MK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
				,	Data.value ('(/LOOP-FST/SEG-REF [DE[.="MK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
				)
		,	UserDefined2 = ''
		,	UserDefined3 = ''
		,	UserDefined4 = RouteCode
		,	UserDefined5 = ''
		,	DateDue = coalesce
				(	Data.value('(/LOOP-SHP/SEG-SHP/DE[@code="0373"])[1]', 'varchar(50)')
				,	Data.value('(/LOOP-FST/SEG-FST/DE[@code="0373"])[1]', 'varchar(50)')
				)
		,	QuantityDue = coalesce
				(	Data.value('(/LOOP-SHP/SEG-SHP/DE[@code="0380"])[1]', 'varchar(50)')
				,	Data.value('(/LOOP-FST/SEG-FST/DE[@code="0380"])[1]', 'varchar(50)')
				)
		,	QuantityType = coalesce
				(	Data.value('(/LOOP-SHP/SEG-SHP/DE[@code="0673"])[1]', 'varchar(50)')
				,	Data.value('(/LOOP-FST/SEG-FST/DE[@code="0673"])[1]', 'varchar(50)')
				)
		from
			@ShipSchedulesTemp2

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
		,	UserDefined1
		,	UserDefined2
		,	UserDefined3
		,	UserDefined4
		,	UserDefined5 
		,	DateDue 
		,	QuantityDue 
		,	QuantityType 
		)

		SELECT
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
		,	UserDefined1 = UserDefined1
		,	UserDefined2 = ''
		,	UserDefined3 = ''
		,	UserDefined4 = UserDefined4
		,	UserDefined5 = ''
		,	DateDue 
		,	QuantityDue 
		,	QuantityType
	
		FROM
			@ShipSchedulesTemp3
		ORDER BY
		 2,3,7
 
		--select * From @ShipSchedulesTemp1
		--select * From @ShipSchedulesTemp2
		--select * From @ShipSchedulesTemp3
		--select * From @ShipSchedules
	end
END

/*		- prepare Release Plans...*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) 
	begin
/*			- prepare Release Plans Headers.*/
	declare
		@PlanningHeaders table
	(	RawDocumentGUID uniqueidentifier
	, Data xml
	,	DocumentImportDT datetime
	,	TradingPartner varchar(50)
	,	DocType varchar(6)
	,	Version varchar(20)
	,	ReleaseNo varchar(30)
	,	DocNumber varchar(50)
	,	ControlNumber varchar(10)
	,	DocumentDT datetime
	)

	insert
		@PlanningHeaders
	(	RawDocumentGUID
	, Data
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
	, ed.Data
	,	DocumentImportDT = ed.RowCreateDT
	,	TradingPartner
	,	DocType = ed.Type
	,	Version
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	DocNumber
	,	ControlNumber
	,	DocumentDT = ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[3]', 'datetime')
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '830'
		and  left(ed.EDIStandard,6) = '00TOYO'
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

/*			- prepare Release Plans Supplemental.*/
	--Begin Transaction
		declare
		@PlanningSupplemental table
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
	,	UserDefined1 varchar(50) --Dock Code
	,	UserDefined2 varchar(50) --Line Feed Code	
	,	UserDefined3 varchar(50) --Reserve Line Feed Code
	,	UserDefined4 varchar(50) --Zone code
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

	declare
		@PlanningSupplementalTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)	
	,	Data xml
	)

	declare
		@PlanningSupplementalTemp2 table
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
	)

	declare
		@PlanningSupplementalTemp3 table
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
	,	Value varchar (50)
	)

	insert
		@PlanningSupplementalTemp1
	(	RawDocumentGUID
	,	ReleaseNo 
	,	ShipToCode 
	,	ConsigneeCode 
	,	ShipFromCode 
	,	SupplierCode	
	,	Data	
	)
	
	select
		RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode =  coalesce
			(	nullif(ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),'')
			,	ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')
			,	EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
			,	ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)')
			)
	,	ConsigneeCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@PlanningHeaders ed
		cross apply ed.Data.nodes('/TRN-830/LOOP-LIN') as EDIData(Releases)

	
		insert
		@PlanningSupplementalTemp2
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
	,	ReleaseNo 
	,	ShipToCode 
	,	ConsigneeCode 
	,	ShipFromCode 
	,	SupplierCode	
	,	CustomerPart = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	,	CustomerPO = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	, CustomerPOLine = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	,	CustomerModelYear = ''
	,	CustomerECL = ''
	,	Data = EDIData.Data.query('.')
	
	from
		@PlanningSupplementalTemp1 ed
		cross apply ed.data.nodes('/LOOP-LIN/SEG-REF') as EDIData(Data)
	order by
		2
	,	3
	,	7

	Insert
	@PlanningSupplementalTemp3
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
		RawDocumentGUID
	,	ReleaseNo 
	,	ShipToCode 
	,	ConsigneeCode 
	,	ShipFromCode 
	,	SupplierCode	
	,	CustomerPart 
	,	CustomerPO
	, CustomerPOLine 
	,	CustomerModelYear
	,	CustomerECL
	,	ValueQualifier	=	Data.value('(/SEG-REF/DE[@code="0128"])[1]', 'varchar(50)')	
	,	Value		=	Data.value('(/SEG-REF/DE[@code="0127"])[1]', 'varchar(50)')	
	
	from
		@PlanningSupplementalTemp2 ed
	order by
		2
	,	3
	,	7
		
	insert
		@PlanningSupplemental
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
		@PlanningSupplementalTemp3
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
	,Value


--Select * From @PlanningSupplementalTemp1
--Select * From @PlanningSupplementalTemp2
--Select * From @PlanningSupplementalTemp3
--Select * From @PlanningSupplemental

--Rollback Transaction


/*			- prepare Release Plan Releases.*/
	--Begin Transaction

declare
		@PlanningReleases table
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

	declare
		@PlanningReleasesTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)	
	,	Data xml
	)

	declare
		@PlanningReleasesTemp2 table
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
	)


	declare
		@PlanningReleasesTemp3 table
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
		@PlanningReleasesTemp1
	(	RawDocumentGUID
	,	ReleaseNo 
	,	ShipToCode 
	,	ConsigneeCode 
	,	ShipFromCode 
	,	SupplierCode	
	,	Data	
	)
	
	select
		RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode =  coalesce
			(	nullif(ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),'')
			,	ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="MI"][@code="0098"]]/DE[@code="0093"])[1]', 'varchar(50)')
			,	EDIData.Releases.value('(./SEG-REF [DE[.="DK"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
			,	ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)')
			)
	,	ConsigneeCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@PlanningHeaders ed
		cross apply ed.Data.nodes('/TRN-830/LOOP-LIN') as EDIData(Releases)
	
	
		insert
		@PlanningReleasesTemp2
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
	,	ReleaseNo 
	,	ShipToCode 
	,	ConsigneeCode 
	,	ShipFromCode 
	,	SupplierCode	
	,	CustomerPart = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	,	CustomerPO = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	, CustomerPOLine = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	,	CustomerModelYear = ''
	,	CustomerECL = ''
	,	Data = EDIData.Data.query('.')
	
	from
		@PlanningReleasesTemp1 ed
		cross apply ed.Data.nodes('/LOOP-LIN/LOOP-SDP/SEG-FST') as EDIData(Data)
	order by
		2
	,	3
	,	7



			
	insert
		@PlanningReleasesTemp3
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
	,	UserDefined1 = Data.value ('(/SEG-FST [DE[.="DO"][@code="0128"]]/DE[@code="0127"])[1]', 'varchar(50)')
	,	UserDefined2 = ''
	,	UserDefined3 = ''
	,	UserDefined4 = ''
	,	UserDefined5 = ''
	,	DateDue = Data.value('(/SEG-FST/DE[@code="0373"])[1]', 'varchar(50)')
	,	QuantityDue = Data.value('(/SEG-FST/DE[@code="0380"])[1]', 'varchar(50)')
	,	QuantityType = Data.value('(/SEG-FST/DE[@code="0680"])[1]', 'varchar(50)')
 
	
	from
		@PlanningReleasesTemp2

INSERT 
		@PlanningReleases
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

	SELECT
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
	,	UserDefined1 = UserDefined1
	,	UserDefined2 = ''
	,	UserDefined3 = ''
	,	UserDefined4 = ''
	,	UserDefined5 = ''
	,	DateDue 
	,	QuantityDue 
	,	QuantityType
	
	FROM
		@PlanningReleasesTemp3

ORDER BY
 2,3,7,17
	 

	 

		--Select * From @PlanningReleasessTemp1
		--Select * From @PlanningReleasessTemp2
		--Select * From @PlanningReleasessTemp3
		--Select * From @PlanningReleasess
		--order by
		--2,3,7,17

		--Rollback Transaction

END

/*	Write data to Staging Tables...*/
/*		- write Ship Schedules...*/
/*			- write Headers.*/
if	exists
	(	select
			*
		from
			@ShipScheduleHeaders fh
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingShipScheduleHeaders'

	insert
		FxAztec.EDIToyota.StagingShipScheduleHeaders
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
		RawDocumentGUID
	,	DocumentImportDT
	,	TradingPartner
	,	DocType
	,	Version
	,	ReleaseNo
	,	DocNumber
	,	ControlNumber
	,	DocumentDT
	from
		@ShipScheduleHeaders fh

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*			- write Supplemental.*/
if	exists
	(	select
			*
		from
			@ShipScheduleSupplemental fs
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingShipScheduleSupplemental'
	
	insert 
		FxAztec.EDIToyota.StagingShipScheduleSupplemental
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
	,	UserDefined1 -- Dock Code
	,	UserDefined2 -- Line Feed Code
	,	UserDefined3 -- Zone Code
	,	UserDefined4 -- Route Code
	,	UserDefined5 
	,	UserDefined6 
	,	UserDefined7 
	,	UserDefined8 
	,	UserDefined9 
	,	UserDefined10 
	,	UserDefined11 --Line11
	,	UserDefined12 --Line12
	,	UserDefined13 --Line13
	,	UserDefined14 --Line14
	,	UserDefined15 --Line15
	,	UserDefined16 --Line16
	,	UserDefined17 --Line17
	,	UserDefined18 
	,	UserDefined19 
	,	UserDefined20 
    from
        @ShipScheduleSupplemental fs
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*			- write Releases.*/
if	exists
	(	select
			*
		from
			@ShipSchedules fr	
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingShipSchedules'

	insert
		FxAztec.EDIToyota.StagingShipSchedules
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
	,	ScheduleType
	,	ReleaseQty
	,	ReleaseDT
	, UserDefined1
	, UserDefined4
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
	,	QuantityType
	,	ReleaseQty = convert(numeric(20,6),nullif(QuantityDue,''))
	,	ReleaseDT = case		when datalength(DateDue) = '6'
												then dbo.udf_GetDT('YYMMDD', DateDue)
												when datalength(DateDue) = '8'
												then dbo.udf_GetDT('CCYYMMDD', DateDue)
												else convert(datetime, DateDue)
												End
		,UserDefined1
		,UserDefined4
	from
		@ShipSchedules
	

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END


----------------------------------------------------------------------------------------------------------
/*		- write Release Plans...*/
/*			- write Headers.*/
if	exists
	(	select
			*
		from
			@PlanningHeaders fh
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingPlanningHeaders'

	insert
		FxAztec.EDIToyota.StagingPlanningHeaders
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
		RawDocumentGUID
	,	DocumentImportDT
	,	TradingPartner
	,	DocType
	,	Version
	,	ReleaseNo
	,	DocNumber
	,	ControlNumber
	,	DocumentDT
	from
		@PlanningHeaders fh

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*			- write Supplemental.*/
if	exists
	(	select
			*
		from
			@PlanningSupplemental ps
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingShipScheduleSupplemental'
	
	insert 
		FxAztec.EDIToyota.StagingPlanningSupplemental
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
  ,	UserDefined1 -- Dock Code
	,	UserDefined2 -- Line Feed Code
	,	UserDefined3 -- Zone Code
	,	UserDefined4
	,	UserDefined5 
	,	UserDefined6 
	,	UserDefined7 
	,	UserDefined8 
	,	UserDefined9 
	,	UserDefined10 
	,	UserDefined11 --Line11
	,	UserDefined12 --Line12
	,	UserDefined13 --Line13
	,	UserDefined14 --Line14
	,	UserDefined15 --Line15
	,	UserDefined16 --Line16
	,	UserDefined17 --Line17
	,	UserDefined18 
	,	UserDefined19 
	,	UserDefined20 
   from
       @PlanningSupplemental

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*			- write Releases.*/
if	exists
	(	select
			*
		from
			@PlanningReleases fr
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIToyota.StagingPlanningReleases'

	insert
		FxAztec.EDIToyota.StagingPlanningReleases
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
	,	QuantityQualifier
	,	Quantity 
	,	QuantityType
	,	DateType
	,	DateDT
	,	DateDTFormat
	)
	select
		RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode
	,	CustomerPart
	, CustomerPO			
	,	CustomerPOLine		
	,	CustomerModelYear 
	,	CustomerECL	
	,	UserDefined1
	,	UserDefined2
	,	UserDefined3
	,	UserDefined4
	,	UserDefined5
	,	''
	,	''
	,	nullif(QuantityDue,'')
	,	QuantityType
	,	''
	,	case		when datalength(DateDue) = '6'
												then dbo.udf_GetDT('YYMMDD', DateDue)
												when datalength(DateDue) = '8'
												then dbo.udf_GetDT('CCYYMMDD', DateDue)
												else convert(datetime, DateDue)
												End
	,	''
	from
		@PlanningReleases
	
		

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*	Set in process documents to processed...*/
/*		- 862s.*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin
	--- <Update rows="*">
	set	@TableName = 'EDIToyota.ShipScheduleHeaders'
	
	update
		ed
	set
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '862'
		and  left(ed.EDIStandard,6) = '00TOYO' 
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Update>
END

/*		- 830s.*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00TOYO' 
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin
	--- <Update rows="*">
	set	@TableName = 'EDI.EDIDocuments'
	
	update
		ed
	set
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '830'
		and  left(ed.EDIStandard,6) = '00TOYO' 
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Update>
END
--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

---	<Error>
queueError:

set	@Result = 100
	raiserror ('Toyota documents already in process.  Use EDIToyota.usp_ClearQueue to clear the queue if necessary.', 16, 1)
	RETURN
	
--- </Error>

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
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

begin transaction

execute
	@ProcReturn = EDIToyota.usp_Stage_1
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go


Select 'StagingSSHeaders'
select
	*
from
	FxAztec.EDIToyota.StagingShipScheduleHeaders sfh

Select 'StagingSSchedules'
select
	*
from
	FxAztec.EDIToyota.StagingShipSchedules sfr

Select 'StagingSSAccums'
select 
	*
from
	FxAztec.EDIToyota.StagingShipScheduleAccums sfs

Select 'StagingSSSupplemental'
select 
	*
from
	FxAztec.EDIToyota.StagingShipScheduleSupplemental sfs
go

Select 'PlanningHeaders'
select
	*
from
	FxAztec.EDIToyota.StagingPlanningHeaders sfh

Select 'PlanningReleases'
select
	*
from
	FxAztec.EDIToyota.StagingPlanningReleases sfr

Select 'PlanningAccums'	
select 
	*
from
	FxAztec.EDIToyota.StagingPlanningAccums sfa
Select 'PlanningAuthAccums'	

select 
	*
from
	FxAztec.EDIToyota.StagingPlanningAuthAccums sfa

Select 'PlanningSupplemental'	
select 
	*
from
	FxAztec.EDIToyota.StagingPlanningSupplemental sfa



rollback
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
