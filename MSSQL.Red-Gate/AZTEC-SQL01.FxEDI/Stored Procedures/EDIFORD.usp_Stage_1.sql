SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [EDIFORD].[usp_Stage_1]
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
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	)
	or exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00FORD'
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
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status in
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) begin

	update
		ed
	set
		Status =
			case
				when ed.TradingPartner = 'Ford Motor Company - Education' then -1
				else 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
			end
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '862'
		and  left(ed.EDIStandard,6) = '00FORD'
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
				and  left(ed.EDIStandard,6) = '00FORD'
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
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status in
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) begin

	update
		ed
	set
		Status =
			case
				when ed.TradingPartner = 'Ford Motor Company - Education' then -1
				else 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
			end
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '830'
		and  left(ed.EDIStandard,6) = '00FORD'
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
				and  left(ed.EDIStandard,6) = '00FORD'
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
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '862'
			and  left(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin

/*			- prepare Ship Schedules Headers.*/
	declare
		@ShipScheduleHeaders table
	(	RawDocumentGUID UNIQUEIDENTIFIER
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
	,	DocumentDT = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[2]', 'datetime'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0373"])[1]', 'datetime'))
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '862'
		and  left(ed.EDIStandard,6) = '00FORD'
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

/*			- prepare Ship Schedules Supplemental.*/
--Begin Transaction

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
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
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
	,	CustomerPart = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="BP" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	,	CustomerPO = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PO" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
	, CustomerPOLine = ed.Data.value('(	for $a in LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="PL" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)')
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

	Insert
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
	,	ValueQualifier	=	Data.value('(/SEG-REF/DE[@code="0128"])[1]', 'varchar(50)')
	,	Value		=	Data.value('(/SEG-REF/DE[@code="0127"])[1]', 'varchar(50)')

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

--Select * From @ShipScheduleSupplementalTemp1
--Select * From @ShipScheduleSupplementalTemp2
--Select * From @ShipScheduleSupplementalTemp3
--Select * From @ShipScheduleSupplemental

--Rollback Transaction

/*			- prepare Ship Schedules Accums.*/

	--Begin Transaction

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

	declare
		@ShipScheduleAccumsTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)
	,	Data xml
	)

	declare
		@ShipScheduleAccumsTemp2 table
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
		@ShipScheduleAccumsTemp3 table
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
	,	Data
	)

	select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@ShipScheduleHeaders ed
		cross apply ed.Data.nodes('/TRN-862/LOOP-LIN') as EDIData(Releases)


	insert
		@ShipScheduleAccumsTemp2
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
		@ShipScheduleAccumsTemp1 ed
		cross apply ed.data.nodes('/LOOP-LIN/LOOP-SHP') as EDIData(Data)
	order by
		2
	,	3
	,	7


	insert
		@ShipScheduleAccumsTemp3
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
	,	ReceivedAccum = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	ReceivedAccumBeginDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	ReceivedAccumEndDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)')
	,	ReceivedQty = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	ReceivedQtyDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	ReceivedShipper = Data.value('(for $a in LOOP-SHP/SEG-REF/DE[@code="0128"] where $a="SI" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)')

	from
		@ShipScheduleAccumsTemp2

Insert
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
	,	ReceivedAccum = max(case when ReceivedAccum is not Null then ReceivedAccum end)
	,	ReceivedAccumBeginDT = max(case when ReceivedAccumBeginDT is not Null then ReceivedAccumBeginDT end)
	,	ReceivedAccumEndDT = max(case when ReceivedAccumEndDT is not Null then ReceivedAccumEndDT end)
	,	ReceivedQty = max(case when ReceivedQty is not Null then ReceivedQty end)
	,	ReceivedQtyDT = max(case when ReceivedQtyDT is not Null then ReceivedQtyDT end)
	,	ReceivedShipper = max(case when ReceivedShipper is not Null then ReceivedShipper end)

	from
		@ShipScheduleAccumsTemp3
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


--Select * From @ShipScheduleAccumsTemp1
--Select * From @ShipScheduleAccumsTemp2
--Select * From @ShipScheduleAccumsTemp3
--Select * From @ShipScheduleAccums

--Rollback Transaction




/*			- Prepare Ship Schedules Auth Accums.*/
--Begin Transaction

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

	declare
		@ShipScheduleAuthAccumsTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)
	,	Data xml
	)

	declare
		@ShipScheduleAuthAccumsTemp2 table
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
		@ShipScheduleAuthAccumsTemp3 table
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
		@ShipScheduleAuthAccumsTemp1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode
	,	Data
	)

	select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@ShipScheduleHeaders ed
		cross apply ed.Data.nodes('/TRN-862/LOOP-LIN') as EDIData(Releases)


		insert
		@ShipScheduleAuthAccumsTemp2
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
		@ShipScheduleAuthAccumsTemp1 ed
		cross apply ed.data.nodes('/LOOP-LIN/LOOP-ATH') as EDIData(Data)
	order by
		2
	,	3
	,	7


	insert
		@ShipScheduleAuthAccumsTemp3
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
	,	AuthAccum = Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	AuthAccumBeginDT = Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0374"] where $a="051" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	AuthAccumEndDT = Data.value('(for $a in LOOP-ATH/SEG-ATH/DE[@code="0374"] where $a="052" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')

	from
		@ShipScheduleAuthAccumsTemp2

Insert
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
	,	AuthAccum = max(case when AuthAccum is not Null then AuthAccum end)
	,	AuthAccumBeginDT = max(case when AuthAccumBeginDT is not Null then AuthAccumBeginDT end)
	,	AuthAccumEndDT = max(case when AuthAccumEndDT is not Null then AuthAccumEndDT end)

	from
		@ShipScheduleAuthAccumsTemp3
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


--Select * From @ShipScheduleAuthAccumsTemp1
--Select * From @ShipScheduleAuthAccumsTemp2
--Select * From @ShipScheduleAuthAccumsTemp3
--Select * From @ShipScheduleAuthAccums

--Rollback Transaction





/*			- prepare Ship Schedules Releases.*/


--Begin Transaction

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
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0328"])[1]', 'varchar(30)'), ed.Data.value('(/TRN-862/SEG-BSS/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
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
		@ShipSchedulesTemp1 ed
		cross apply ed.Data.nodes('/LOOP-LIN/LOOP-FST[not(LOOP-JIT)]/SEG-FST') as EDIData(Data)
	order by
		2
	,	3
	,	7

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
		@ShipSchedulesTemp1 ed
		cross apply ed.Data.nodes('/LOOP-LIN/LOOP-FST/LOOP-JIT/SEG-JIT') as EDIData(Data)
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
	,	UserDefined1 = ''
	,	UserDefined2 = ''
	,	UserDefined3 = ''
	,	UserDefined4 = ''
	,	UserDefined5 = ''
	,	DateDue = Data.value('(/SEG-FST/DE[@code="0373"])[1]', 'varchar(50)')
	,	QuantityDue = Data.value('(/SEG-FST/DE[@code="0380"])[1]', 'varchar(50)')
	,	QuantityType = Data.value('(/SEG-FST/DE[@code="0680"])[1]', 'varchar(50)')


	from
		@ShipSchedulesTemp2

INSERT
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
	,	UserDefined1 = ''
	,	UserDefined2 = ''
	,	UserDefined3 = ''
	,	UserDefined4 = ''
	,	UserDefined5 = ''
	,	DateDue
	,	QuantityDue
	,	QuantityType

	FROM
		@ShipSchedulesTemp3

ORDER BY
 2,3,7


		--Select * From @ShipSchedulesTemp1
		--Select * From @ShipSchedulesTemp2
		--Select * From @ShipSchedulesTemp3
		--Select * From @ShipSchedules

		--Rollback Transaction
END

/*		- prepare Release Plans...*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Type = '830'
			and  left(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	)
	begin
/*			- prepare Release Plans Headers.*/
	declare
		@PlanningHeaders table
	(	RawDocumentGUID UNIQUEIDENTIFIER
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
		@PlanningHeaders
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
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	DocNumber
	,	ControlNumber
	,	DocumentDT = ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0373"])[3]', 'datetime')
	from
		EDI.EDIDocuments ed
	where
		ed.Type = '830'
		and  left(ed.EDIStandard,6) = '00FORD'
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
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'), ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)'))
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

--Select * From @PlanningSupplementalTemp1
--Select * From @PlanningSupplementalTemp2
--Select * From @PlanningSupplementalTemp3
--Select * From @PlanningSupplemental

--Rollback Transaction

/*			- prepare Release Plans Accums.*/
--Begin Transaction

declare
		@PlanningAccums table
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

	declare
		@PlanningAccumsTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)
	,	Data xml
	)

	declare
		@PlanningAccumsTemp2 table
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
		@PlanningAccumsTemp3 table
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
		@PlanningAccumsTemp1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode
	,	Data
	)

select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'), ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@PlanningHeaders ed
		cross apply ed.Data.nodes('/TRN-830/LOOP-LIN') as EDIData(Releases)

		insert
		@PlanningAccumsTemp2
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
		@PlanningAccumsTemp1 ed
		cross apply ed.data.nodes('/LOOP-LIN/LOOP-SHP') as EDIData(Data)
	order by
		2
	,	3
	,	7


	insert
		@PlanningAccumsTemp3
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
	,	ReceivedAccum = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	ReceivedAccumBeginDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	ReceivedAccumEndDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="02" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)')
	,	ReceivedQty = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	ReceivedQtyDT = Data.value('(for $a in LOOP-SHP/SEG-SHP/DE[@code="0673"] where $a="01" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	ReceivedShipper = Data.value('(for $a in LOOP-SHP/SEG-REF/DE[@code="0128"] where $a="SI" return $a/../DE[. >> $a][@code="0127"][1])[1]', 'varchar(30)')

	from
		@PlanningAccumsTemp2

Insert
		@PlanningAccums
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
	,	ReceivedAccum = max(case when ReceivedAccum is not Null then ReceivedAccum end)
	,	ReceivedAccumBeginDT = max(case when ReceivedAccumBeginDT is not Null then ReceivedAccumBeginDT end)
	,	ReceivedAccumEndDT = max(case when ReceivedAccumEndDT is not Null then ReceivedAccumEndDT end)
	,	ReceivedQty = max(case when ReceivedQty is not Null then ReceivedQty end)
	,	ReceivedQtyDT = max(case when ReceivedQtyDT is not Null then ReceivedQtyDT end)
	,	ReceivedShipper = max(case when ReceivedShipper is not Null then ReceivedShipper end)

	from
		@PlanningAccumsTemp3
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


--Select * From @PlanningAccumsTemp1
--Select * From @PlanningAccumsTemp2
--Select * From @PlanningAccumsTemp3
--Select * From @PlanningAccums

--Rollback Transaction


/* -Prepare Planning Auth Accums.*/

--Begin Transaction

declare
		@PlanningAuthAccums table
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

	declare
		@PlanningAuthAccumsTemp1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(50)
	,	ConsigneeCode varchar(50)
	,	ShipFromCode varchar(50)
	,	SupplierCode varchar(50)
	,	Data xml
	)

	declare
		@PlanningAuthAccumsTemp2 table
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
		@PlanningAuthAccumsTemp3 table
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
		@PlanningAuthAccumsTemp1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode
	,	Data
	)

	select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'), ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)'))
	,	ConsigneeCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="IC"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	ShipFromCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SF"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	SupplierCode = ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="SU"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)')
	,	Data = EDIData.Releases.query('.')
	from
		@PlanningHeaders ed
		cross apply ed.Data.nodes('/TRN-830/LOOP-LIN') as EDIData(Releases)


		insert
		@PlanningAuthAccumsTemp2
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
		@PlanningAuthAccumsTemp1 ed
		cross apply ed.data.nodes('/LOOP-LIN/SEG-ATH') as EDIData(Data)
	order by
		2
	,	3
	,	7


	insert
		@PlanningAuthAccumsTemp3
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
	,	AuthAccum = Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	AuthAccumBeginDT = coalesce(Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'),Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  )
	,	AuthAccumEndDT = Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="PQ" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	FabAccum = Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	FabAccumBeginDT =  coalesce(Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'),Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  )
	,	FabAccumEndDT =   Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="FI" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	,	RawAccum = Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0380"][1])[1]', 'varchar(30)')
	,	RawAccumBeginDT =   coalesce(Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][2])[1]', 'varchar(30)'),Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')  )
	,	RawAccumEndDT =  Data.value('(for $a in SEG-ATH/DE[@code="0672"] where $a="MT" return $a/../DE[. >> $a][@code="0373"][1])[1]', 'varchar(30)')
	from
		@PlanningAuthAccumsTemp2

Insert
		@PlanningAuthAccums
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
		@PlanningAuthAccumsTemp3
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


--Select * From @PlanningAuthAccumsTemp1
--Select * From @PlanningAuthAccumsTemp2
--Select * From @PlanningAuthAccumsTemp3
--Select * From @PlanningAuthAccums

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
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo = coalesce(nullif(ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0328"])[1]', 'varchar(30)'),''), ed.Data.value('(/TRN-830/SEG-BFR/DE[@code="0127"])[1]', 'varchar(30)'))
	,	ShipToCode = coalesce(EDIData.Releases.value('(../SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'),ed.Data.value('(/TRN-830/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(50)'), ed.Data.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)'))
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
		cross apply ed.Data.nodes('/LOOP-LIN/LOOP-SDP[not(LOOP-JIT)]/SEG-FST') as EDIData(Data)
	order by
		2
	,	3
	,	7

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
		cross apply ed.Data.nodes('/LOOP-LIN/LOOP-SDP/LOOP-JIT/SEG-JIT') as EDIData(Data)
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
	,	UserDefined1 = ''
	,	UserDefined2 = ''
	,	UserDefined3 = ''
	,	UserDefined4 = ''
	,	UserDefined5 =  Data.value('(/SEG-FST/DE[@code="0681"])[1]', 'varchar(50)')
	,	DateDue = CASE WHEN Data.value('(/SEG-FST/DE[@code="0681"])[1]', 'varchar(50)') = 'F' THEN Data.value('(/SEG-FST/DE[@code="0373"])[2]', 'varchar(50)') ELSE Data.value('(/SEG-FST/DE[@code="0373"])[1]', 'varchar(50)') END
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
	,	ReleaseNo+'_'+UserDefined5
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
	,	DateDue
	,	QuantityDue
	,	QuantityType

	FROM
		@PlanningReleasesTemp3

ORDER BY
 2,3,7,17


		--Select * From @PlanningReleasesTemp1
		--Select * From @PlanningReleasesTemp2
		--Select * From @PlanningReleasesTemp3
		--Select * From @PlanningReleases
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
	set	@TableName = 'FxAztec.EDIFORD.StagingShipScheduleHeaders'

	insert
		FxAztec.EDIFORD.StagingShipScheduleHeaders
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
	set	@TableName = 'FxAztec.EDIFORD.StagingShipScheduleSupplemental'

	insert
		FxAztec.EDIFORD.StagingShipScheduleSupplemental
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

/*			- write Accums.*/
----------------------------------------------------------------------------------------------------------------------

if	exists
	(	select
			*
		from
			@ShipScheduleAccums fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIFORD.StagingShipScheduleAccums'

	insert  FxAztec.EDIFORD.StagingShipScheduleAccums
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
  ,	ReferenceNo
  ,	LastQtyReceived
  ,	LastQtyDT
	,	LastShipper
  ,	LastAccumQty
  ,	LastAccumDT

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
	,	ReferenceNo = ''
	, LastQtyReceived = ReceivedQty
	, LastQtyDT = case		when datalength(ReceivedQtyDT) = '6'
												then dbo.udf_GetDT('YYMMDD', ReceivedQtyDT)
												when datalength(ReceivedQtyDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', ReceivedQtyDT)
												else convert(datetime, ReceivedQtyDT)
								End
		, LastShipper =  ReceivedShipper
		, LastAccumQty = ReceivedAccum
		, LastAccumDT = case		when datalength(ReceivedAccumEndDT) = '6'
														then dbo.udf_GetDT('YYMMDD', ReceivedAccumEndDT)
														when datalength(ReceivedAccumEndDT) = '8'
														then dbo.udf_GetDT('CCYYMMDD', ReceivedAccumEndDT)
														else convert(datetime, ReceivedAccumEndDT)
								End
    from
        @ShipScheduleAccums

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

if	exists
	(	select
			*
		from
			@ShipScheduleAuthAccums fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIFORD.StagingShipScheduleAuthAccums'

	insert
		FxAztec.EDIFORD.StagingShipScheduleAuthAccums
	(
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
  ,	PriorCUMStartDT
  ,	PriorCUMEndDT
  ,	PriorCUM
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
  , PriorCUMStartDT =  case		when datalength(AuthAccumBeginDT) = '6'
												then dbo.udf_GetDT('YYMMDD', AuthAccumBeginDT)
												when datalength(AuthAccumBeginDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', AuthAccumBeginDT)
												else convert(datetime, AuthAccumBeginDT)
												End
    ,   PriorCUMEndDT = case		when datalength(AuthAccumEndDT) = '6'
												then dbo.udf_GetDT('YYMMDD', AuthAccumEndDT)
												when datalength(AuthAccumEndDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', AuthAccumEndDT)
												else convert(datetime, AuthAccumEndDT)
												End
    ,   PriorCUM = AuthAccum
    from
        @ShipScheduleAuthAccums


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
	set	@TableName = 'FxAztec.EDIFORD.StagingShipSchedules'

	insert
		FxAztec.EDIFORD.StagingShipSchedules
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
	,	ReleaseQty = convert(int,QuantityDue)
	,	ReleaseDT = case		when datalength(DateDue) = '6'
												then dbo.udf_GetDT('YYMMDD', DateDue)
												when datalength(DateDue) = '8'
												then dbo.udf_GetDT('CCYYMMDD', DateDue)
												else convert(datetime, DateDue)
												End
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
	set	@TableName = 'FxAztec.EDIFORD.StagingPlanningHeaders'

	insert
		FxAztec.EDIFORD.StagingPlanningHeaders
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
	set	@TableName = 'FxAztec.EDIFORD.StagingShipScheduleSupplemental'

	insert
		FxAztec.EDIFORD.StagingPlanningSupplemental
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

/*			- write Accums.*/
------------------------------------------------------------------------------------------------------------------------

if	exists
	(	select
			*
		from
			@PlanningAccums fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIFORD.StagingPlanningAccums'

	insert
		FxAztec.EDIFORD.StagingPlanningAccums
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
	,	ReferenceNo
	,	LastQtyReceived
	,	LastQtyDT
	, LastShipper
	,	LastAccumQty
	,	LastAccumDT

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
	,	ReferenceNo = ''
	, LastQtyReceived = ReceivedQty
	, LastQtyDT = case		when datalength(ReceivedQtyDT) = '6'
												then dbo.udf_GetDT('YYMMDD', ReceivedQtyDT)
												when datalength(ReceivedQtyDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', ReceivedQtyDT)
												else convert(datetime, ReceivedQtyDT)
								End
		, LastShipper =  ReceivedShipper
		, LastAccumQty = ReceivedAccum
		, LastAccumDT = case		when datalength(ReceivedAccumEndDT) = '6'
														then dbo.udf_GetDT('YYMMDD', ReceivedAccumEndDT)
														when datalength(ReceivedAccumEndDT) = '8'
														then dbo.udf_GetDT('CCYYMMDD', ReceivedAccumEndDT)
														else convert(datetime, ReceivedAccumEndDT)
								End
    from
        @PlanningAccums


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

/*			- write Planning Auth Accums.*/
if	exists
	(	select
			1
		from
			@PlanningAuthAccums fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIFORD.StagingPlanningAuthAccums'

	insert
		FxAztec.EDIFORD.StagingPlanningAuthAccums
	(
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
	,	PriorCUM
  ,	PriorCUMStartDT
  ,	PriorCUMEndDT
  ,	FabCUM
	,	FabCUMStartDT
  ,	FabCUMEndDT
  ,	RawCUM
	,	RawCUMStartDT
  ,	RawCUMEndDT

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
	,	PriorCum = AuthAccum
	, PriorCUMStartDT = case		when datalength(AuthAccumBeginDT) = '6'
												then dbo.udf_GetDT('YYMMDD', AuthAccumBeginDT)
												when datalength(AuthAccumBeginDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', AuthAccumBeginDT)
												else convert(datetime, AuthAccumBeginDT)
												End
	, PriorCUMEndDT = case		when datalength(AuthAccumEndDT) = '6'
												then dbo.udf_GetDT('YYMMDD', AuthAccumEndDT)
												when datalength(AuthAccumEndDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', AuthAccumEndDT)
												else convert(datetime, AuthAccumEndDT)
												End
	,	FabCum = FabAccum
	, FabCUMStartDT = case		when datalength(FabAccumBeginDT) = '6'
												then dbo.udf_GetDT('YYMMDD', FabAccumBeginDT)
												when datalength(FabAccumBeginDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', FabAccumBeginDT)
												else convert(datetime, FabAccumBeginDT)
												End
		,FabCUMEndDT = case		when datalength(FabAccumEndDT) = '6'
												then dbo.udf_GetDT('YYMMDD', FabAccumEndDT)
												when datalength(FabAccumEndDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', FabAccumEndDT)
												else convert(datetime, FabAccumEndDT)
												End
		,	RawCum = RawAccum
		, RawCUMStartDT = case		when datalength(RawAccumBeginDT) = '6'
												then dbo.udf_GetDT('YYMMDD', RawAccumBeginDT)
												when datalength(RawAccumBeginDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', RawAccumBeginDT)
												else convert(datetime, RawAccumBeginDT)
												End
		,RawCUMEndDT = case		when datalength(RawAccumEndDT) = '6'
												then dbo.udf_GetDT('YYMMDD', RawAccumEndDT)
												when datalength(RawAccumEndDT) = '8'
												then dbo.udf_GetDT('CCYYMMDD', RawAccumEndDT)
												else convert(datetime, RawAccumEndDT)
												End


    from
        @PlanningAuthAccums


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
	set	@TableName = 'FxAztec.EDIFORD.StagingPlanningReleases'

	INSERT
		FxAztec.EDIFORD.StagingPlanningReleases
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
	,	UserDefined1
	,	UserDefined2
	,	UserDefined3
	,	UserDefined4
	,	UserDefined5
	,	''
	,	''
	,	QuantityDue
	,	QuantityType
	,	''
	,	CASE		WHEN DATALENGTH(DateDue) = '6'
												THEN dbo.udf_GetDT('YYMMDD', DateDue)
												WHEN DATALENGTH(DateDue) = '8'
												THEN dbo.udf_GetDT('CCYYMMDD', DateDue)
												ELSE CONVERT(DATETIME, DateDue)
												END
	,	''
	FROM
		@PlanningReleases



	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Insert>
END

/*	Set in process documents to processed...*/
/*		- 862s.*/
IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.Type = '862'
			AND  LEFT(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) BEGIN
	--- <Update rows="*">
	SET	@TableName = 'EDIFORD.ShipScheduleHeaders'

	UPDATE
		ed
	SET
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	FROM
		EDI.EDIDocuments ed
	WHERE
		ed.Type = '862'
		AND  LEFT(ed.EDIStandard,6) = '00FORD'
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Update>
END

/*		- 830s.*/
IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.Type = '830'
			AND  LEFT(ed.EDIStandard,6) = '00FORD'
			--and ed.TradingPartner in ( 'MPT MUNCIE' )
			AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) BEGIN
	--- <Update rows="*">
	SET	@TableName = 'EDI.EDIDocuments'

	UPDATE
		ed
	SET
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	FROM
		EDI.EDIDocuments ed
	WHERE
		ed.Type = '830'
		AND  LEFT(ed.EDIStandard,6) = '00FORD'
		--and ed.TradingPartner in ( 'MPT MUNCIE' )
		AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		RETURN
	END
	--- </Update>
END
--- </Body>

---	<Return>
SET	@Result = 0
RETURN
	@Result
--- </Return>

---	<Error>
queueError:

SET	@Result = 100
	RAISERROR ('Chrysler documents already in process.  Use EDIFORD.usp_ClearQueue to clear the queue if necessary.', 16, 1)
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
	@ProcReturn = EDIFORD.usp_Stage_1
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
	FxAztec.EDIFORD.StagingShipScheduleHeaders sfh

Select 'StagingSSchedules'
select
	*
from
	FxAztec.EDIFORD.StagingShipSchedules sfr

Select 'StagingSSAccums'
select
	*
from
	FxAztec.EDIFORD.StagingShipScheduleAccums sfs

Select 'StagingSSSupplemental'
select
	*
from
	FxAztec.EDIFORD.StagingShipScheduleSupplemental sfs
go

Select 'PlanningHeaders'
select
	*
from
	FxAztec.EDIFORD.StagingPlanningHeaders sfh

Select 'PlanningReleases'
select
	*
from
	FxAztec.EDIFORD.StagingPlanningReleases sfr

Select 'PlanningAccums'
select
	*
from
	FxAztec.EDIFORD.StagingPlanningAccums sfa
Select 'PlanningAuthAccums'

select
	*
from
	FxAztec.EDIFORD.StagingPlanningAuthAccums sfa

Select 'PlanningSupplemental'
select
	*
from
	FxAztec.EDIFORD.StagingPlanningSupplemental sfa



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
