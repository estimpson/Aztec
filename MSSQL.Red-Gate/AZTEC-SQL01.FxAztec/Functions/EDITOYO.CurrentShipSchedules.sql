SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE function [EDITOYO].[CurrentShipSchedules]
()
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
				when ssh.Status = 0 --(select dbo.udf_StatusValue('EDITOYO.ShipScheduleHeaders', 'Status', 'New'))
					then 1
				else 0
			end
	from
		(	select
				ReleaseNo = coalesce(max(ss.ReleaseNo),'')
			,	ShipToCode = ss.ShipToCode
			,	ShipFromCode = coalesce(ss.ShipFromCode,'')
			,	ConsigneeCode = coalesce(ss.ConsigneeCode,'')
			,	CustomerPart = ss.CustomerPart
			,	CustomerPO = coalesce(ss.CustomerPO,'')
			,	CustomerModelYear = coalesce(ss.CustomerModelYear,'')
			,	CheckLast = max
				(	 convert(char(20), ssh.DocumentDT, 120)
					+ convert(char(20), ssh.DocumentImportDT, 120)
					+ convert(char(10), ssh.DocNumber)
					+ convert(char(10), ssh.ControlNumber)
					
				)
			from
				EDITOYO.ShipScheduleHeaders ssh
				join EDITOYO.ShipSchedules ss
					on ss.RawDocumentGUID = ssh.RawDocumentGUID
			where
				ssh.Status in
				(	0 --(select dbo.udf_StatusValue('EDITOYO.ShipScheduleHeaders', 'Status', 'New'))
				,	1 --(select dbo.udf_StatusValue('EDITOYO.ShipScheduleHeaders', 'Status', 'Active'))
				)
			group by
				ss.ShipToCode
			,	coalesce(ss.ShipFromCode,'')
			,	coalesce(ss.ConsigneeCode,'')
			,	ss.CustomerPart
			,	coalesce(ss.CustomerPO,'')
			,	coalesce(ss.CustomerModelYear,'')
		) cl
		join EDITOYO.ShipScheduleHeaders ssh
			join EDITOYO.ShipSchedules ss
				on ss.RawDocumentGUID = ssh.RawDocumentGUID
			on ss.ShipToCode = cl.ShipToCode
			and coalesce(ss.releaseNo,'') = cl.ReleaseNo
			and coalesce(ss.ShipFromCode, '') = cl.ShipFromCode
			and coalesce(ss.ConsigneeCode, '') = cl.ConsigneeCode
			and ss.CustomerPart = cl.CustomerPart
			and coalesce(ss.CustomerPO, '') = cl.CustomerPO
			and coalesce(ss.CustomerModelYear,'') = cl.CustomerModelYear
			and	(	convert(char(20), ssh.DocumentDT, 120)
					+ convert(char(20), ssh.DocumentImportDT, 120)
					+ convert(char(10), ssh.DocNumber)
					+ convert(char(10), ssh.ControlNumber)
					
				) = cl.CheckLast
--- </Body>

---	<Return>
	return
end













GO
