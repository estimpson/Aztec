SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [EDIEDIFACT97A].[usp_Stage_1]
	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
AS
SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET	@Result = 999999

--- <Error Handling>
DECLARE
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn INTEGER,
	@ProcResult INTEGER,
	@Error INTEGER,
	@RowCount INTEGER

SET	@ProcName = USER_NAME(OBJECTPROPERTY(@@procid, 'OwnerId')) + '.' + OBJECT_NAME(@@procid)  -- e.g. EDI.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
SET	@TranDT = COALESCE(@TranDT, GETDATE())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Look for documents already in the queue.*/
IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.EDIStandard = '97A'
			AND ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
			AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	)
	OR EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
			AND ed.EDIStandard = '97A'
			AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) BEGIN
	GOTO queueError
END

/*	Move new and reprocessed Chrysler DELJITs and DELFORs to Staging. */
/*		Set new and requeued documents to in process.*/
--- <Update rows="*">
SET	@TableName = 'EDIEDIFACT97A.ShipScheduleHeaders'

IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.EDIStandard = '97A'
			AND ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
			AND ed.Status IN
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) BEGIN
	
	UPDATE
		ed
	SET
		Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	FROM
		EDI.EDIDocuments ed
	WHERE
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
		AND ed.EDIStandard = '97A'
		AND ed.Status IN
			(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
			,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
			)
		AND NOT EXISTS
		(	SELECT
				*
			FROM
				EDI.EDIDocuments ed1
			WHERE
				ed1.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
				AND ed1.EDIStandard = '97A'
				AND ed1.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
		)
	
	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount

	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		GOTO queueError
	END
END
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIEDIFACT97A.vwPlanningReleasesHeaders'

if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
			and ed.EDIStandard = '97A'
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
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
		and ed.EDIStandard = '97A'
		and ed.Status in
			(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
			,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
			)
		and not exists
		(	select
				*
			from
				EDI.EDIDocuments ed1
			where
				ed1.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
				and ed1.EDIStandard = '97A'
				and ed1.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
		)

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		goto queueError
	end
end
--- </Update>

/*	Prepare data for Staging Tables...*/
/*		- prepare Ship Schedules...*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.EDIStandard = '97A'
			and ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) 
begin

/*			- prepare Ship Schedules Headers.*/
	declare
		@ShipScheduleHeaders table
	(	RawDocumentGUID uniqueidentifier
	,	DocumentImportDT datetime
	,	TradingPartner varchar(50)
	,	DocType varchar(6)
	,	Version varchar(20)
	,	ReleaseNo varchar(50)
	,	DocNumber varchar(50)
	,	ControlNumber varchar(10)
	,	DocumentDT datetime
	)

	insert
		@ShipScheduleHeaders
	(	RawDocumentGUID
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
	,	DocumentImportDT = ed.RowCreateDT
	,	TradingPartner
	,	DocType = ed.Type
	,	Version
	,	ReleaseNo = ed.Data.value('(/TRN-DELJIT/SEG-BGM[1]/CE/DE[@code="1001"])[1]', 'varchar(50)')
	,	DocNumber
	,	ControlNumber
	,	DocumentDT =  case when datalength(ed.Data.value('(/TRN-DELJIT/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)')) = 8
								then
										dbo.udf_GetDT('CCYYMMDD',ed.Data.value('(/TRN-DELJIT/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)'))
								else
										dbo.udf_GetDT('CCYYMMDDHHMM',ed.Data.value('(/TRN-DELJIT/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)'))
								end
	from
		EDI.EDIDocuments ed
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
		and ed.EDIStandard = '97A'
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

/*			- prepare Ship Schedules Supplemental.*/

--Begin Transaction

declare
		@ShipScheduleSupplemental table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)	
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
		@ShipScheduleSupplementalTemp table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)	
	,	ReferenceType varchar(50)
	,	Reference varchar(50)
	)

	declare
		@tempShipScheduleSupplemental1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)		
	,	Data xml
	)

	declare
		@tempShipScheduleSupplemental2 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)		
	,	Data xml
	)

	declare
		@tempShipScheduleSupplemental3 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)		
	,	Data xml
	)

	insert
		@tempShipScheduleSupplemental1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode	
	,	Data
	)
	select
		RawDocumentGUID = ed.GUID
	,	ReleaseNo =		coalesce(	ed.Data.value('(/TRN-DELJIT/SEG-BGM/CE/DE[@code="1004"])[1]', 'varchar(50)'),'')
	,	ShipToCode =	coalesce(	EDIData.Releases.value('(../LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)')	,ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'))
	,	ConsigneeCode = coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="IC"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)
	,	ShipFromCode =  coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="SF"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)								
	,	SupplierCode =  coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="SU"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)		
	,	Data = EDIData.Releases.query('.')
	from
		EDI.EDIDocuments ed
		cross apply ed.Data.nodes('/TRN-DELJIT/LOOP-SEQ') as EDIData(Releases)
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
		and ed.EDIStandard = '97A'
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	
	insert
		@tempShipScheduleSupplemental2
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
	,	CustomerPart	=	coalesce(nullif((Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(Data.value('(for $a in LOOP-SEQ/LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PL" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	Data = EDIData.ps.query('.')
	
	from
		@tempShipScheduleSupplemental1 as ps
		cross apply ps.data.nodes('/LOOP-SEQ/LOOP-PAC/LOOP-PCI/SEG-PCI') as EDIData(ps)
	order by
		2
	,	3
	,	8
		

	insert
		@tempShipScheduleSupplemental3
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
	,	CustomerPart	=	coalesce(nullif((Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(Data.value('(for $a in LOOP-SEQ/LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	Data.value('(for $a in LOOP-SEQ/LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PL" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	Data = EDIData.ps.query('.')
	
	from
		@tempShipScheduleSupplemental1 as ps
		cross apply ps.data.nodes('/LOOP-SEQ/LOOP-LIN/LOOP-LOC/SEG-LOC') as EDIData(ps)
	order by
		2
	,	3
	,	8
		

	Insert
		@ShipScheduleSupplementalTemp
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
	,	ReferenceType
	,	Reference 
	)

	Select
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
	,	ReferenceType	=	Data.value('(/SEG-PCI/CE/DE[@code="7511"])[1]', 'varchar(50)')	
	,	ReferenceNo		=	Data.value('(/SEG-PCI/CE/DE[@code="7102"])[1]', 'varchar(50)')	
	From
		@tempShipScheduleSupplemental2 ps2

		UNION

	Select
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
	,	ReferenceType	=	Data.value('(/SEG-LOC/DE[@code="3227"])[1]', 'varchar(50)')	
	,	ReferenceNo		=	Data.value('(/SEG-LOC/CE/DE[@code="3225"])[1]', 'varchar(50)')	
	From
		@tempShipScheduleSupplemental3 ps3
	
	 
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
	,	UserDefined1 = max(case when ssst.ReferenceType = 'DK' then ssst.Reference end)
	,	UserDefined2 = max(case when ssst.ReferenceType = 'LF' then ssst.Reference end)
	,	UserDefined3 = max(case when ssst.ReferenceType = 'RL' then ssst.Reference end)
	,	UserDefined4 = max(case when ssst.ReferenceType = '11' then ssst.Reference end)--Qualifier Type of 11
	,	UserDefined5 = max(case when ssst.ReferenceType = '159' then ssst.Reference end)--Qualifier Type of 159
	,	UserDefined6 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined7 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined8 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined9 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined10 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined11 = max(case when ssst.ReferenceType = '11Z' then ssst.Reference end)
	,	UserDefined12 = max(case when ssst.ReferenceType = '12Z' then ssst.Reference end)
	,	UserDefined13 = max(case when ssst.ReferenceType = '13Z' then ssst.Reference end)
	,	UserDefined14 = max(case when ssst.ReferenceType = '14Z' then ssst.Reference end)
	,	UserDefined15 = max(case when ssst.ReferenceType = '15Z' then ssst.Reference end)
	,	UserDefined16 = max(case when ssst.ReferenceType = '16Z' then ssst.Reference end)
	,	UserDefined17 = max(case when ssst.ReferenceType = '17Z' then ssst.Reference end)
	,	UserDefined18 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined19 = max(case when ssst.ReferenceType = '16' then ssst.Reference end)
	,	UserDefined20 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	from
		@ShipScheduleSupplementalTemp ssst
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

--Select * From @tempShipScheduleSupplemental1
--Select * From @TempShipScheduleSupplemental2
--Select * From @TempShipScheduleSupplemental3
--Select * From @ShipScheduleSupplementalTemp
--Select * From @ShipScheduleSupplemental

--Rollback Transaction

/*			- prepare Ship Schedules Accums.*/

--Begin Transaction
declare
		@ShipScheduleQuantities table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)	
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
	,	UserDefined6 varchar(50)
	,	UserDefined7 varchar(50)
	,	UserDefined8 varchar(50)
	,	UserDefined9 varchar(50)
	,	UserDefined10 varchar(50)
	,	SEQQualifier varchar(50)
	,	QuantityQualifier varchar(50)
	,	Quantity varchar(50)
	,	QuantityType varchar(50)
	,	DateType varchar(50)
	,	DateDT varchar(50)
	,	DateDTFormat varchar(50)
	)

	declare
		@tempShipScheduleQuantities table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	, HeaderDeliveryDate varchar(15)
	,	SEQData xml	
	,	LINData xml
	,	Data xml
	)

	insert
		@tempShipScheduleQuantities
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode
	, HeaderDeliveryDate
	,	SEQData
	,	LINData
	,	Data
	)
	select
		RawDocumentGUID = ed.GUID
	,	ReleaseNo =		coalesce(	ed.Data.value('(/TRN-DELJIT/SEG-BGM[1]/CE/DE[@code="1004"])[1]', 'varchar(50)'),'')
	,	ShipToCode =	coalesce(	EDIData.Releases.value('(../SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)')	,ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'))
	,	ConsigneeCode = coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="IC"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)
	,	ShipFromCode =  coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="SF"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)								
	,	SupplierCode =  coalesce(	ed.Data.value('(/TRN-DELJIT/LOOP-NAD/SEG-NAD [DE[.="SU"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)
	, HeaderDeliveryDate = ed.Data.value('(/TRN-DELJIT/SEG-DTM/CE/DE[@code="2380"])[2]', 'varchar(15)')
	,	SEQData = EDIData.Releases.query('../../../LOOP-SEQ')		
	,	LINData = EDIData.Releases.query('../../LOOP-LIN')
	,	Data = EDIData.Releases.query('.')
	from
		EDI.EDIDocuments ed
		cross apply ed.Data.nodes('/TRN-DELJIT/LOOP-SEQ/LOOP-LIN/LOOP-QTY') as EDIData(Releases)
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
		and  ed.EDIStandard = '97A'
		and  ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	
	insert
		@ShipScheduleQuantities
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
	,	SEQQualifier 
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
	,	CustomerPart	=	coalesce(nullif((LinData.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (LinData.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((LinData.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(LinData.value('(for $a in LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	LINData.value('(for $a in LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1156"][1])[1]', 'varchar(50)')
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	UserDefined1	=	''
	,	UserDefined2	=	''
	,	UserDefined3	=	''
	,	UserDefined4	=	''
	,	UserDefined5	=	''
	,	UserDefined6	=	''
	,	UserDefined7	=	''
	,	UserDefined8	=	''
	,	UserDefined9	=	data.value('(/LOOP-QTY/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"])[1]', 'varchar(15)') --RFFTypeQualifier
	,	UserDefined10	=	data.value('(/LOOP-QTY/LOOP-RFF/SEG-RFF/CE/DE[@code="1154"])[1]', 'varchar(15)') --RFF
	,	SEQQualifier	=	SEQdata.value('(/LOOP-SEQ/SEG-SEQ/DE[@code="1229"])[1]', 'varchar(15)')
	,	QuantityQualifier =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6063"])[1]', 'varchar(15)')
	,	Quantity =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6060"])[1]', 'varchar(15)')
	,	QuantityType = coalesce(data.value('(/LOOP-QTY/SEG-SCC/DE[@code="4017"])[1]', 'varchar(15)'),'0')
	,	DateType = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'),data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'))
	,	DateDT = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'), data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'), TempQuantities.HeaderDeliveryDate )
	,	DateDTFormat = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)') , data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)'),'203')
	
	from
		@tempShipScheduleQuantities as TempQuantities

--Select * From	@tempShipScheduleQuantities
--Select * From	@ShipScheduleQuantities
		
--Rollback Transaction
End


/*		- prepare Release Plans...*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
			and ed.EDIStandard = '97A'
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin
/*			- prepare Release Plans Headers.*/
	declare
		@PlanningHeaders table
	(	RawDocumentGUID uniqueidentifier
	,	DocumentImportDT datetime
	,	TradingPartner varchar(50)
	,	DocType varchar(6)
	,	Version varchar(20)
	,	ReleaseNo varchar(50)
	,	DocNumber varchar(50)
	,	ControlNumber varchar(10)
	,	DocumentDT datetime
	)

	insert
		@PlanningHeaders
	(	RawDocumentGUID
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
	,	DocumentImportDT = ed.RowCreateDT
	,	TradingPartner
	,	DocType = ed.Type
	,	EDIStandard
	,	ReleaseNo =  coalesce(	ed.Data.value('(/TRN-DELFOR/SEG-BGM/DE[@code="1004"])[1]', 'varchar(50)'),'')
	,	DocNumber
	,	ControlNumber
	,	DocumentDT = case ed.Data.value('(/TRN-DELFOR/SEG-DTM[1]/CE/DE[@code="2379"])[1]', 'varchar(15)')
						when '102' Then dbo.udf_GetDT('CCYYMMDD', ed.Data.value('(/TRN-DELFOR/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)'))
						when '103' Then dbo.udf_GetDT('CCYYWW', ed.Data.value('(/TRN-DELFOR/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)'))
						when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', ed.Data.value('(/TRN-DELFOR/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'varchar(50)'))
						else ed.Data.value('(/TRN-DELFOR/SEG-DTM[1]/CE/DE[@code="2380"])[1]', 'datetime')
						end
	from
		EDI.EDIDocuments ed
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
	    and ed.EDIStandard = '97A'
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

/*			- prepare Release Plans Supplemental.*/

--Begin Transaction

declare
		@PlanningReleaseSupplemental table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)	
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
		@PlanningReleaseSupplementalTemp table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)	
	,	ReferenceType varchar(50)
	,	Reference varchar(50)
	)

	declare
		@tempPlanningReleaseSupplemental1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)		
	,	Data xml
	)

	declare
		@tempPlanningReleaseSupplemental2 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)		
	,	Data xml
	)

	insert
		@tempPlanningReleaseSupplemental1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode	
	,	Data
	)
	select
		RawDocumentGUID = ed.GUID
	,	ReleaseNo =		coalesce(	ed.Data.value('(/TRN-DELFOR/SEG-BGM/CE/DE[@code="1004"])[1]', 'varchar(50)'),'')
	,	ShipToCode =	coalesce(	EDIData.Releases.value('(../LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)')	,ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'))
	,	ConsigneeCode = coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="IC"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)
	,	ShipFromCode =  coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="SF"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)								
	,	SupplierCode =  coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="SU"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)		
	,	Data = EDIData.Releases.query('.')
	from
		EDI.EDIDocuments ed
		cross apply ed.Data.nodes('/TRN-DELFOR/LOOP-GIS/LOOP-LIN') as EDIData(Releases)
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
		and ed.EDIStandard = '97A'
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	
	insert
		@tempPlanningReleaseSupplemental2
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
	,	CustomerPart	=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(Data.value('(for $a in LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PL" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	Data = EDIData.ps.query('.')
	
	from
		@tempPlanningReleaseSupplemental1 as ps
		cross apply ps.data.nodes('/LOOP-LIN/SEG-LOC') as EDIData(ps)
	order by
		2
	,	3
	,	8
		

	Insert
		@PlanningReleaseSupplementalTemp
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
	,	ReferenceType
	,	Reference 
	)

	Select
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
	,	ReferenceType = data.value('(/SEG-LOC/DE[@code="3227"])[1]', 'varchar(15)')
	,	Reference = data.value('(/SEG-LOC/CE/DE[@code="3225"])[1]', 'varchar(15)')
	From
		@tempPlanningReleaseSupplemental2 ps2
	
	 
	insert
		@PlanningReleaseSupplemental
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
	,	UserDefined1 = max(case when ssst.ReferenceType = 'DK' then ssst.Reference end)
	,	UserDefined2 = max(case when ssst.ReferenceType = 'LF' then ssst.Reference end)
	,	UserDefined3 = max(case when ssst.ReferenceType = 'RL' then ssst.Reference end)
	,	UserDefined4 = max(case when ssst.ReferenceType = '11' then ssst.Reference end)--Qualifier Type of 11
	,	UserDefined5 = max(case when ssst.ReferenceType = '159' then ssst.Reference end)--Qualifier Type of 159
	,	UserDefined6 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined7 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined8 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined9 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined10 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined11 = max(case when ssst.ReferenceType = '11Z' then ssst.Reference end)
	,	UserDefined12 = max(case when ssst.ReferenceType = '12Z' then ssst.Reference end)
	,	UserDefined13 = max(case when ssst.ReferenceType = '13Z' then ssst.Reference end)
	,	UserDefined14 = max(case when ssst.ReferenceType = '14Z' then ssst.Reference end)
	,	UserDefined15 = max(case when ssst.ReferenceType = '15Z' then ssst.Reference end)
	,	UserDefined16 = max(case when ssst.ReferenceType = '16Z' then ssst.Reference end)
	,	UserDefined17 = max(case when ssst.ReferenceType = '17Z' then ssst.Reference end)
	,	UserDefined18 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	,	UserDefined19 = max(case when ssst.ReferenceType = '16' then ssst.Reference end)
	,	UserDefined20 = max(case when ssst.ReferenceType = '??' then ssst.Reference end)
	from
		@PlanningReleaseSupplementalTemp ssst
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

--Select * From @tempPlanningReleaseSupplemental1
--Select * From @TempPlanningReleaseSupplemental2
--Select * From @PlanningReleaseSupplementalTemp
--Select * From @PlanningReleaseSupplemental

--Rollback Transaction

/*			- prepare Planning Quantities.*/

--Begin Transaction

	declare
		@tempPlanningReleaseQuantities1 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	Data xml
	)

	declare
		@tempPlanningReleaseQuantities2 table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)		
	,	Data xml
	)

	declare
		@tempPlanningReleaseQuantities2a table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)
	,	CustomerPart varchar(50)
	,	CustomerPO varchar(50)
	,	CustomerPOLine varchar(50)
	,	CustomerModelYear varchar(50)
	,	CustomerECL varchar(50)		
	,	Data xml
	)

	
declare
		@PlanningReleaseQuantities table
	(	RawDocumentGUID uniqueidentifier
	,	ReleaseNo varchar(50)
	,	ShipToCode varchar(15)
	,	ConsigneeCode varchar(15)
	,	ShipFromCode varchar(15)
	,	SupplierCode varchar(15)	
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
	,	UserDefined6 varchar(50)
	,	UserDefined7 varchar(50)
	,	UserDefined8 varchar(50)
	,	UserDefined9 varchar(50)
	,	UserDefined10 varchar(50)
	,	QuantityQualifier varchar(50)
	,	Quantity varchar(50)
	,	QuantityType varchar(50)
	,	DateType varchar(50)
	,	DateDT varchar(50)
	,	DateDTFormat varchar(50)
	)


	insert
		@tempPlanningReleaseQuantities1
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode	
	,	Data
	)
	select
		RawDocumentGUID = ed.GUID
	,	ReleaseNo =		coalesce(	ed.Data.value('(/TRN-DELFOR/SEG-BGM/CE/DE[@code="1004"])[1]', 'varchar(50)'),'')
	,	ShipToCode =	coalesce(	EDIData.Releases.value('(../LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)')	,ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="ST"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'))
	,	ConsigneeCode = coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="IC"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)
	,	ShipFromCode =  coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="SF"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)								
	,	SupplierCode =  coalesce(	ed.Data.value('(/TRN-DELFOR/LOOP-NAD/SEG-NAD [DE[.="SU"][@code="3035"]]/CE/DE[@code="3039"])[1]', 'varchar(15)'),''	)		
	,	Data = EDIData.Releases.query('.')
	from
		EDI.EDIDocuments ed
		cross apply ed.Data.nodes('/TRN-DELFOR/LOOP-GIS/LOOP-LIN') as EDIData(Releases)
	where
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
		and ed.EDIStandard = '97A'
		and ed.Status = 100 -- (select dbo.udf_statusvalue('edi.edidocuments', 'inprocess'))
	

	insert
		@tempPlanningReleaseQuantities2
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode	
	,	CustomerPart
	,	CustomerPO
	,	CustomerPOline
	,	CustomerECL
	,	CustomerModelYear
	,	Data
	)
	select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo =		ed.ReleaseNo
	,	ShipToCode =	ed.ShipToCode
	,	ConsigneeCode = ed.ConsigneeCode
	,	ShipFromCode = ed.ShipFromCode								
	,	SupplierCode = ed.SupplierCode
	,	CustomerPart	=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(Data.value('(for $a in LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PL" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')
	,	CustomerECL =''
	,	CustomerModelYear = ''
	,	Data = EDIData.Releases.query('.')
	from
		@tempPlanningReleaseQuantities1 ed
		cross apply ed.data.nodes('/LOOP-LIN/LOOP-QTY') as EDIData(Releases)


		insert
		@tempPlanningReleaseQuantities2a
	(	RawDocumentGUID
	,	ReleaseNo
	,	ShipToCode
	,	ConsigneeCode
	,	ShipFromCode
	,	SupplierCode	
	,	CustomerPart
	,	CustomerPO
	,	CustomerPOline
	,	CustomerECL
	,	CustomerModelYear
	,	Data
	)
	select
		RawDocumentGUID = ed.RawDocumentGUID
	,	ReleaseNo =		ed.ReleaseNo
	,	ShipToCode =	ed.ShipToCode
	,	ConsigneeCode = ed.ConsigneeCode
	,	ShipFromCode = ed.ShipFromCode								
	,	SupplierCode = ed.SupplierCode
	,	CustomerPart	=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="BP" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''), (Data.value('(for $a in LOOP-LIN/SEG-LIN/CE/DE[@code="7143"] where $a="IN" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')) )
	,	CustomerPO		=	coalesce(nullif((Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PO" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')),''),(Data.value('(for $a in LOOP-LIN/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"] where $a="ON" return $a/../DE[. >> $a][@code="1154"][1])[1]', 'varchar(50)')) )
	,	CustomerPOLine	=	Data.value('(for $a in LOOP-LIN/SEG-PIA/CE/DE[@code="7143"] where $a="PL" return $a/../DE[. << $a][@code="7140"][1])[1]', 'varchar(50)')
	,	CustomerECL =''
	,	CustomerModelYear = ''
	,	Data = EDIData.Releases.query('.')
	from
		@tempPlanningReleaseQuantities1 ed
		cross apply ed.data.nodes('/LOOP-LIN/LOOP-SCC/LOOP-QTY') as EDIData(Releases)


	insert
		@PlanningReleaseQuantities
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
	,	CustomerPO		
	,	CustomerPOLine	
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	UserDefined1	=	''
	,	UserDefined2	=	''
	,	UserDefined3	=	''
	,	UserDefined4	=	''
	,	UserDefined5	=	''
	,	UserDefined6	=	''
	,	UserDefined7	=	''
	,	UserDefined8	=	'LOOP-QTY'
	,	UserDefined9	=	data.value('(/LOOP-QTY/LOOP-RFF/SEG-RFF/CE/DE[@code="1153"])[1]', 'varchar(15)') --RFFTypeQualifier
	,	UserDefined10	=	data.value('(/LOOP-QTY/LOOP-RFF/SEG-RFF/CE/DE[@code="1154"])[1]', 'varchar(15)') --RFF
	,	QuantityQualifier =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6063"])[1]', 'varchar(15)')
	,	Quantity =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6060"])[1]', 'varchar(15)')
	,	QuantityType = coalesce(data.value('(/LOOP-QTY/SEG-SCC/DE[@code="4017"])[1]', 'varchar(15)'),'0')
	,	DateType = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'),data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'))
	,	DateDT = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'), data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'))
	,	DateDTFormat = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)'), data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)'))  
	
	from
		@tempPlanningReleaseQuantities2 as TempQuantities
	UNION 

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
	,	CustomerModelYear = ''
	,	CustomerECL		=	''
	,	UserDefined1	=	''
	,	UserDefined2	=	''
	,	UserDefined3	=	''
	,	UserDefined4	=	''
	,	UserDefined5	=	''
	,	UserDefined6	=	''
	,	UserDefined7	=	''
	,	UserDefined8	=	'LOOP-SCC'
	,	UserDefined9	=	data.value('(/LOOP-SCC/SEG-SCC/CE/DE[@code="2013"])[1]', 'varchar(15)') --RFFTypeQualifier
	,	UserDefined10	=	data.value('(/LOOP-SCC/SEG-SCC/CE/DE[@code="2015"])[1]', 'varchar(15)') --RFF
	,	QuantityQualifier =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6063"])[1]', 'varchar(15)')
	,	Quantity =	data.value('(/LOOP-QTY/SEG-QTY/CE/DE[@code="6060"])[1]', 'varchar(15)')
	,	QuantityType = coalesce(data.value('(/SEG-SCC/DE[@code="4017"])[1]', 'varchar(15)'),'0')
	,	DateType = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'),data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2005"])[1]', 'varchar(15)'))
	,	DateDT = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'), data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2380"])[1]', 'varchar(15)'))
	,	DateDTFormat = coalesce(data.value('(/LOOP-QTY/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)'), data.value('(/LOOP-QTY/LOOP-RFF/SEG-DTM/CE/DE[@code="2379"])[1]', 'varchar(15)'))  
	
	from
		@tempPlanningReleaseQuantities2a as TempQuantities

	

--Select * From	@tempPlanningReleaseQuantities1
--Select * From	@tempPlanningReleaseQuantities2
--Select * From	@tempPlanningReleaseQuantities2a
--Select * From	@PlanningReleaseQuantities

		
--Rollback Transaction

end



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
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipScheduleHeaders'

	insert
		FxAztec.EDIEDIFACT97A.StagingShipScheduleHeaders
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

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Supplemental.*/
if	exists
	(	select
			*
		from
			@ShipScheduleSupplemental fs
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipScheduleSupplemental'
	
	insert 
		FxAztec.EDIEDIFACT97A.StagingShipScheduleSupplemental
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

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Accums.*/
/*			- write Accums.*/
if	exists
	(	select
			*
		from
			@ShipScheduleQuantities fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipScheduleAccums'

	insert  FxAztec.EDIEDIFACT97A.StagingShipScheduleAccums
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
    ,	ReferenceNo = max(case when QuantityQualifier = '48' then coalesce(UserDefined10,'') end)
    ,   LastQtyReceived = max(case when QuantityQualifier = '48' then coalesce(nullif(Quantity,''),0) end)
    ,   LastQtyDT = max(
									case 
									when datalength(DateDT) = 8 and QuantityQualifier = '48' 
									then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101')) 
									when datalength(DateDT) = 12 and QuantityQualifier = '48' 
									then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
									when QuantityQualifier = '48' 
									then case DateDTFormat 
									when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
									when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
									when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
									else convert (DateTime, DateDT)
									end 
									end)
    ,   LastAccumQty = max(case when QuantityQualifier in ('70' ) then coalesce(nullif(Quantity,''),0) when QuantityQualifier = '3' and QuantityType = '0' then coalesce(nullif(Quantity,''),0) else 0  end)
    ,   LastAccumDT = max(
					case 
					when datalength(DateDT) = 8 and  QuantityQualifier in ('70') 
					then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101')) 
					when datalength(DateDT) = 12 and  QuantityQualifier in ('70') 
				  then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001')) 
					when QuantityQualifier in ('70') 
					then case coalesce(DateDTFormat ,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
					when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					when '' Then Null
					else convert (DateTime, DateDT)
					end 
					when QuantityQualifier = '3' and QuantityType = '0' and datalength(DateDT) = 8
					then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101')) 
					when QuantityQualifier = '3' and QuantityType = '0' and datalength(DateDT) = 12
					then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					when QuantityQualifier = '3' and QuantityType = '0' 
					then case coalesce(DateDTFormat,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
					when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					when '' Then Null
					else convert (DateTime, DateDT)
					end
					end)
    from
        @ShipScheduleQuantities
	where
		QuantityQualifier in ('70', '48', '3')
		and	coalesce(DateDT,'') not like '00%' 
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
	

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

if	exists
	(	select
			*
		from
			@ShipScheduleQuantities fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipScheduleAuthAccums'

	insert
		FxAztec.EDIEDIFACT97A.StagingShipScheduleAuthAccums
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
    ,   PriorCUMStartDT = max(case when QuantityQualifier = '79' then case coalesce(DateDTFormat,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', DateDT)
					when '103' Then dbo.udf_GetDT('CCYYWW', DateDT)
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					when '' Then Null
					else convert (DateTime, DateDT)
					end end)
    ,   PriorCUMEndDT = max(case when QuantityQualifier = '79' then case coalesce(DateDTFormat ,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', DateDT)
					when '103' Then dbo.udf_GetDT('CCYYWW', DateDT)
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					when '' Then Null
					else convert (DateTime, DateDT)
					end end)
    ,   PriorCUM = max(case when QuantityQualifier = '79' then coalesce(nullif(Quantity,''),0) end)
    from
        @ShipScheduleQuantities
	where
		coalesce(QuantityQualifier,'') in ('79') and
		coalesce(DateDT,'') not like '00%'
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
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end




/*			- write Releases.*/
if	exists
	(	select
			*
		from
			@ShipScheduleQuantities fr	
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipSchedules'

	insert
		FxAztec.EDIEDIFACT97A.StagingShipSchedules
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
	,	ReleaseQty = convert(numeric(20,6),nullif(Quantity,''))
	,	ReleaseDT = case DateDTFormat 
					when '102' Then dbo.udf_GetDT('CCYYMMDD', DateDT)
					when '103' Then dbo.udf_GetDT('CCYYWW', DateDT)
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					else convert (DateTime, DateDT)
					end
	from
		@ShipScheduleQuantities
	where
		QuantityQualifier in ('1')

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*		- write Release Plans...*/
/*			- write Headers.*/
if	exists
	(	select
			*
		from
			@PlanningHeaders fh
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingPlanningHeaders'

	insert
		FxAztec.EDIEDIFACT97A.StagingPlanningHeaders
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

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Supplemental.*/
if	exists
	(	select
			*
		from
			@PlanningReleaseSupplemental ps
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingShipScheduleSupplemental'
	
	insert 
		FxAztec.EDIEDIFACT97A.StagingPlanningSupplemental
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
       @PlanningReleaseSupplemental

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Accums.*/
if	exists
	(	select
			*
		from
			@PlanningReleaseQuantities fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingPlanningAccums'

	insert
		FxAztec.EDIEDIFACT97A.StagingPlanningAccums
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
    ,	ReferenceNo = max(case when QuantityQualifier = '48' then coalesce(UserDefined10,'') end)
    ,   LastQtyReceived = max(case when QuantityQualifier = '48' then coalesce(nullif(Quantity,''),0) end)
    ,   LastQtyDT = max(case when QuantityQualifier = '48' then case DateDTFormat 
					when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
					when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					else convert (DateTime,  coalesce(nullif(DateDT, '00000000'), '209901010001'))
					end end)
    ,   LastAccumQty = max(case when rtrim(QuantityQualifier) in ( '70' ) then coalesce(nullif(Quantity,''),0) when QuantityQualifier = '3' and QuantityType = '0' AND ShipToCode != '059697201' then coalesce(nullif(Quantity,''),0) else -1  end)
    ,   LastAccumDT = max(case when QuantityQualifier in ('70') then case COALESCE(DateDTFormat,'') 
					when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
					when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					when '' then NULL
					else convert (DateTime,  coalesce(nullif(DateDT, '00000000'), '209901010001'))
					end 
					when QuantityQualifier = '3' and QuantityType = '0' then case COALESCE(DateDTFormat,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', coalesce(nullif(DateDT, '00000000'), '20990101'))
					when '103' Then dbo.udf_GetDT('CCYYWW', coalesce(nullif(DateDT, '00000000'), '209901'))
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', coalesce(nullif(DateDT, '00000000'), '209901010001'))
					when '' THEN NULL
					else convert (DateTime,  coalesce(nullif(DateDT, '00000000'), '209901010001'))
					end
					end)
    from
        @PlanningReleaseQuantities
	where
		QuantityQualifier in ( '48', '3', '70') and
		coalesce(UserDefined8,'') = 'LOOP-QTY' and
		coalesce(DateDT,'') not like '00%'
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



	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Planning Auth Accums.*/
if	exists
	(	select
			1
		from
			@PlanningReleaseQuantities fa
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingPlanningAuthAccums'

	insert
		FxAztec.EDIEDIFACT97A.StagingPlanningAuthAccums
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
    ,   PriorCUMStartDT = max(case when QuantityQualifier = '79' then case coalesce(DateDTFormat,'') 
					when '102' Then dbo.udf_GetDT('CCYYMMDD', DateDT)
					when '103' Then dbo.udf_GetDT('CCYYWW', DateDT)
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					when '' Then Null
					else convert (DateTime, DateDT)
					end end)
    ,   PriorCUMEndDT = max(case when QuantityQualifier = '79' then case coalesce(DateDTFormat,'')
					when '102' Then dbo.udf_GetDT('CCYYMMDD', DateDT)
					when '103' Then dbo.udf_GetDT('CCYYWW', DateDT)
					when '203' Then dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					when '' Then Null
					else convert (DateTime, DateDT)
					end end)
    ,   PriorCUM = max(case when QuantityQualifier = '79' then coalesce(nullif(Quantity,''),0) end)
    from
        @PlanningReleaseQuantities
	where
		coalesce(QuantityQualifier,'XX') in ('79') and
		coalesce(UserDefined8,'') in ( 'LOOP-SCC', 'LOOP-QTY')
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
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		return
	end
	--- </Insert>
end

/*			- write Releases.*/
if	exists
	(	select
			*
		from
			@PlanningReleaseQuantities fr
	) begin
	--- <Insert rows="*">
	set	@TableName = 'FxAztec.EDIEDIFACT97A.StagingPlanningReleases'

	insert
		FxAztec.EDIEDIFACT97A.StagingPlanningReleases
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
	,	QuantityQualifier
	,	QuantityQualifier
	,	NULLIF(Quantity,'')
	,	QuantityType
	,	DateType
	,	CASE DateDTFormat 
					WHEN '102' THEN dbo.udf_GetDT('CCYYMMDD', DateDT)
					WHEN '103' THEN dbo.udf_GetDT('CCYYWW', DateDT)
					WHEN '203' THEN dbo.udf_GetDT('CCYYMMDDHHMM', DateDT)
					ELSE CONVERT (DATETIME, DateDT)
					END
	,	DateDTFormat
	FROM
		@PlanningReleaseQuantities
	WHERE
		QuantityQualifier IN( '1','135')
		

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
/*		- DELJITs.*/
IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.EDIStandard = '97A'
			AND ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
			AND ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) BEGIN
	--- <Update rows="*">
	SET	@TableName = 'EDIEDIFACT97A.ShipScheduleHeaders'
	
	UPDATE
		ed
	SET
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	FROM
		EDI.EDIDocuments ed
	WHERE
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELJIT'
		AND ed.EDIStandard = '97A'
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

/*		- DELFORs.*/
IF	EXISTS
	(	SELECT
			*
		FROM
			EDI.EDIDocuments ed
		WHERE
			ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
			AND ed.EDIStandard = '97A'
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
		ed.HeaderData.value('/TRN-INFO[1]/@type', 'varchar(50)') = 'DELFOR'
		AND ed.EDIStandard = '97A'
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
	RAISERROR ('97A documents already in process.  Use EDIEDIFACT97A.usp_ClearQueue to clear the queue if necessary.', 16, 1)
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
	@ProcReturn = EDIEDIFACT97A.usp_Stage_1
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
	FxAztec.EDIEDIFACT97A.StagingShipScheduleHeaders sfh

Select 'StagingSSchedules'
select
	*
from
	FxAztec.EDIEDIFACT97A.StagingShipSchedules sfr

Select 'StagingSSAccums'
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingShipScheduleAccums sfs

Select 'StagingSSAuthAccums'
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingShipScheduleAuthAccums sfs

Select 'StagingSSSupplemental'
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingShipScheduleSupplemental sfs
go

Select 'PlanningHeaders'
select
	*
from
	FxAztec.EDIEDIFACT97A.StagingPlanningHeaders sfh

Select 'PlanningReleases'
select
	*
from
	FxAztec.EDIEDIFACT97A.StagingPlanningReleases sfr

Select 'PlanningAccums'	
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingPlanningAccums sfa

Select 'PlanningAuthAccums'	
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingPlanningAuthAccums sfa
Select 'PlanningSupplemental'	
select 
	*
from
	FxAztec.EDIEDIFACT97A.StagingPlanningSupplemental sfa


rollback
--commit
go

set statistics io off
set statistics time off
go

}

Results {
}
*/












































GO
