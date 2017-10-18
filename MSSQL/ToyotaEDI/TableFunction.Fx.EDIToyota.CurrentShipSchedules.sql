
/*
Create function TableFunction.Fx.EDIToyota.CurrentShipSchedules.sql
*/

--use Fx
--go

if	objectproperty(object_id('EDIToyota.CurrentShipSchedules'), 'IsTableFunction') = 1 begin
	drop function EDIToyota.CurrentShipSchedules
end
go

create function EDIToyota.CurrentShipSchedules ()
returns @CurrentSS table
(	RawDocumentGUID uniqueidentifier
,	ReleaseNo varchar(50)
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ConsigneeCode varchar(15)
,	CustomerPart varchar(50)
,	CustomerPO varchar(50)
,	CustomerModelYear varchar(50)
,	NewDocument int
)
as
begin
--- <Body>
	insert
		@CurrentSS
	select distinct
		RawDocumentGUID = ssh.RawDocumentGUID
	,	ReleaseNo =  coalesce(ss.ReleaseNo,'')
	,	ShipToCode = ss.ShipToCode
	,	ShipFromCode = coalesce(ss.ShipFromCode,'')
	,	ConsigneeCode = coalesce(ss.ConsigneeCode,'')
	,	CustomerPart = ss.CustomerPart
	,	CustomerPO = coalesce(ss.CustomerPO,'')
	,	CustomerModelYear = coalesce(ss.CustomerModelYear,'')
	,	NewDocument =
			case
				when ssh.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'New'))
					then 1
				else 0
			end
	from
		EDIToyota.ShipScheduleHeaders ssh
			join EDIToyota.ShipSchedules ss
				on ss.RawDocumentGUID = ssh.RawDocumentGUID
	where
		ssh.Status in
		(	0 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'New'))
		,	1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
		)
--- </Body>

---	<Return>
	return
end
go

