SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [EDIToyota].[CurrentShipSchedules] ()
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
		ssActive.RawDocumentGUID
	,	ssActive.ReleaseNo
	,	ssActive.ShipToCode
	,	ssActive.ShipFromCode
	,	ssActive.ConsigneeCode
	,	ssActive.CustomerPart
	,	ssActive.CustomerPO
	,	ssActive.CustomerModelYear
	,	ssActive.NewDocument
	from
		(	select
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
			,	Occurrence = row_number() over (partition by ss.ReleaseDT, ss.ShipToCode, ss.CustomerPart, ss.UserDefined1 order by ss.RowCreateDT desc)
			from
				EDIToyota.ShipScheduleHeaders ssh
					join EDIToyota.ShipSchedules ss
						on ss.RawDocumentGUID = ssh.RawDocumentGUID
			where
				ssh.Status in
				(	0 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'New'))
				,	1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
				) and
				ssh.RowCreateDT > getdate() - 90
		) ssActive
	where
		ssActive.Occurrence = 1
--- </Body>

---	<Return>
	return
end
GO
