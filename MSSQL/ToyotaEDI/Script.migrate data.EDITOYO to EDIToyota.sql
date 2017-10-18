begin
truncate table EDIToyota.ShipSchedules

set identity_insert EDIToyota.ShipSchedules on

insert
	EDIToyota.ShipSchedules
(	Status
,	Type
,	RawDocumentGUID
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
,	UserDefined1
,	UserDefined2
,	UserDefined3
,	UserDefined4
,	UserDefined5
,	ScheduleType
,	ReleaseQty
,	ReleaseDT
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.ShipSchedules ss

set identity_insert EDIToyota.ShipSchedules off
end

select
	*
from
	EDIToyota.ShipSchedules ss

begin
truncate table EDIToyota.ShipScheduleHeaders

set identity_insert EDIToyota.ShipScheduleHeaders on

insert
	EDIToyota.ShipScheduleHeaders
(	Status
,	Type
,	RawDocumentGUID
,	DocumentImportDT
,	TradingPartner
,	DocType
,	Version
,	Release
,	DocNumber
,	ControlNumber
,	DocumentDT
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.ShipScheduleHeaders ssh

set identity_insert EDIToyota.ShipScheduleHeaders off
end

select
	*
from
	EDIToyota.ShipScheduleHeaders ssh

begin
truncate table EDIToyota.PlanningReleases

set identity_insert EDIToyota.PlanningReleases on

insert
	EDIToyota.PlanningReleases
(	Status
,	Type
,	RawDocumentGUID
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
,	UserDefined1
,	UserDefined2
,	UserDefined3
,	UserDefined4
,	UserDefined5
,	ScheduleType
,	ReleaseQty
,	ReleaseDT
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.PlanningReleases ssh

set identity_insert EDIToyota.PlanningReleases off
end

select
	*
from
	EDIToyota.PlanningReleases pr

begin
truncate table EDIToyota.PlanningHeaders

set identity_insert EDIToyota.PlanningHeaders on

insert
	EDIToyota.PlanningHeaders
(	Status
,	Type
,	RawDocumentGUID
,	DocumentImportDT
,	TradingPartner
,	DocType
,	Version
,	Release
,	DocNumber
,	ControlNumber
,	DocumentDT
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.PlanningHeaders ssh

set identity_insert EDIToyota.PlanningHeaders off
end

select
	*
from
	EDIToyota.PlanningHeaders ph

begin
truncate table EDIToyota.ShipScheduleAccums

set identity_insert EDIToyota.ShipScheduleAccums on

insert
	EDIToyota.ShipScheduleAccums
(	Status
,	Type
,	RawDocumentGUID
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
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.ShipScheduleAccums ssa

set identity_insert EDIToyota.ShipScheduleAccums off
end

select
	*
from
	EDIToyota.ShipScheduleAccums

begin
truncate table EDIToyota.ShipScheduleAuthAccums

set identity_insert EDIToyota.ShipScheduleAuthAccums on

insert
	EDIToyota.ShipScheduleAuthAccums
(	Status
,	Type
,	RawDocumentGUID
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
,	UserDefined1
,	UserDefined2
,	UserDefined3
,	UserDefined4
,	UserDefined5
,	RAWCUMStartDT
,	RAWCUMEndDT
,	RAWCUM
,	FabCUMStartDT
,	FabCUMEndDT
,	FabCUM
,	PriorCUMStartDT
,	PriorCUMEndDT
,	PriorCUM
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.ShipScheduleAuthAccums ssaa

set identity_insert EDIToyota.ShipScheduleAuthAccums off
end

select
	*
from
	EDIToyota.ShipScheduleAuthAccums ssaa

begin
truncate table EDIToyota.PlanningAccums

set identity_insert EDIToyota.PlanningAccums on

insert
	EDIToyota.PlanningAccums
(	Status
,	Type
,	RawDocumentGUID
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
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
)
select
	*
from
	fxAztec.EDITOYO.PlanningAccums pa

set identity_insert EDIToyota.PlanningAccums off
end

select
	*
from
	EDIToyota.PlanningAccums pa

begin
truncate table EDIToyota.PlanningAuthAccums

set identity_insert EDIToyota.PlanningAuthAccums on

insert
	EDIToyota.PlanningAuthAccums
(	Status
,   Type
,   RawDocumentGUID
,   ReleaseNo
,   ShipToCode
,   ConsigneeCode
,   ShipFromCode
,   SupplierCode
,   CustomerPart
,   CustomerPO
,   CustomerPOLine
,   CustomerModelYear
,   CustomerECL
,   ReferenceNo
,   UserDefined1
,   UserDefined2
,   UserDefined3
,   UserDefined4
,   UserDefined5
,   PriorCUMStartDT
,   PriorCUMEndDT
,   PriorCUM
,   FABCUMStartDT
,   FABCUMEndDT
,   FABCUM
,   RAWCUMStartDT
,   RAWCUMEndDT
,   RAWCUM
,   RowID
,   RowCreateDT
,   RowCreateUser
,   RowModifiedDT
,   RowModifiedUser)
select
	*
from
	fxAztec.EDITOYO.PlanningAuthAccums paa

set identity_insert EDIToyota.PlanningAuthAccums off
end

select
	*
from
	EDIToyota.PlanningAuthAccums paa