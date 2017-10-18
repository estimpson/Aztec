SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create function [EDIToyota].[CurrentRemittanceAdvice] ()
returns @CurrentRemittanceAdvice table
(	RawDocumentGUID uniqueidentifier
,	CustomerPart varchar(50)
,	ManifestNumber varchar(50)

)
as
begin
--- <Body>
	insert
		@CurrentRemittanceAdvice
	select distinct
		RawDocumentGUID = ph.RawDocumentGUID
	,	CustomerPart = pr.CustomerPart
	,	ManifestNumber = pr.Userdefined1
	from
		(	select
				CustomerPart = pri.CustomerPart
			, ManifestNumber = pri.userdefined1	
			,	CheckLast = max
				(	 convert(char(20), phi.DocumentDT, 120)
					+ convert(char(20), phi.DocumentImportDT, 120)
					+ convert(char(10), phi.DocNumber)
					+ convert(char(10), phi.ControlNumber)
					
				)
			from
				EDIToyota.RemittanceHeaders phi
				join EDIToyota.RemittanceDetails pri
					on pri.RawDocumentGUID = phi.RawDocumentGUID
			where
				phi.Status in
				(	0 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'New'))
				,	1 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'Active'))
				)
			group by
				pri.CustomerPart,
				pri.userdefined1
		) cl
		join EDIToyota.RemittanceHeaders ph
			join EDIToyota.RemittanceDetails pr
				on pr.RawDocumentGUID = ph.RawDocumentGUID
			on pr.CustomerPart = cl.CustomerPart
			and pr.userdefined1= cl.ManifestNumber
			and	(	  convert(char(20), ph.DocumentDT, 120)
					+ convert(char(20), ph.DocumentImportDT, 120)
					+ convert(char(10), ph.DocNumber)
					+ convert(char(10), ph.ControlNumber)
					
				) = cl.CheckLast
--- </Body>

---	<Return>
	return
end

GO
