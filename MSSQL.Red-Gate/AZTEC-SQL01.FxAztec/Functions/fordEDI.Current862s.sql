SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [fordEDI].[Current862s]
()
returns @Current862s table
(	RawDocumentGUID uniqueidentifier
,	NewDocument int
)
as
begin
--- <Body>
	declare
		@Ford862LastDocumentDTs table
	(	ShipToCode varchar (15)
	,	ShipFromCode varchar (15)
	,	DocumentDT datetime
	)

	insert
		@Ford862LastDocumentDTs
	select
		fr.ShipToCode
	,	fr.ShipFromCode
	,	max(fh.DocumentDT)
	from
		EDI.Ford_862_Headers fh
		join EDI.Ford_862_Releases fr
			on fr.RawDocumentGUID = fh.RawDocumentGUID
	where
		fh.Status in
		(	0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
		,	1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
		)
	group by
		fr.ShipToCode
	,	fr.ShipFromCode
	
	declare
		@Ford862LastReleases table
	(	ShipToCode varchar (15)
	,	ShipFromCode varchar (15)
	,	Release varchar(30)
	)

	insert
		@Ford862LastReleases
	select
		fr.ShipToCode
	,	fr.ShipFromCode
	,	max(fh.Release)
	from
		EDI.Ford_862_Headers fh
		join EDI.Ford_862_Releases fr
			on fr.RawDocumentGUID = fh.RawDocumentGUID
	where
		fh.Status in
		(	0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
		,	1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
		)
	group by
		fr.ShipToCode
	,	fr.ShipFromCode
	
	declare
		@Ford862LastDocumentImportDTs table
	(	ShipToCode varchar (15)
	,	ShipFromCode varchar (15)
	,	CustomerPart varchar(35)
	,	DocumentDT datetime
	,	DocNumber varchar(50)
	,	ControlNumber varchar(10)
	,	DocumentImportDT datetime
	)

	insert
		@Ford862LastDocumentImportDTs
	select
		fr.ShipToCode
	,	fr.ShipFromCode
	,	fr.CustomerPart
	,	fh.DocumentDT
	,	fh.DocNumber
	,	fh.ControlNumber
	,	max(fh.DocumentImportDT)
	from
		EDI.Ford_862_Headers fh
		join EDI.Ford_862_Releases fr
			on fr.RawDocumentGUID = fh.RawDocumentGUID
	where
		fh.Status in
		(	0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
		,	1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
		)
	group by
		fr.ShipToCode
	,	fr.ShipFromCode
	,	fr.CustomerPart
	,	fh.DocumentDT
	,	fh.DocNumber
	,	fh.ControlNumber
	
	insert
		@Current862s
	select distinct
		fh.RawDocumentGUID
	,	case
			when fh.status = 0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
				then 1
			else 0
		end
	from
		EDI.Ford_862_Headers fh
		join EDI.Ford_862_Releases fr
			on fr.RawDocumentGUID = fh.RawDocumentGUID
		join @Ford862LastDocumentDTs flddt
			on fr.ShipToCode = flddt.ShipToCode
			and fr.ShipFromCode = flddt.ShipFromCode
			and fh.DocumentDT = flddt.DocumentDT
		join @Ford862LastReleases flr
			on fr.ShipToCode = flr.ShipToCode
			and fr.ShipFromCode = flr.ShipFromCode
			and fh.Release = flr.Release
		join @Ford862LastDocumentImportDTs fldidt
			on fr.ShipToCode = fldidt.ShipToCode
			and fr.ShipFromCode = fldidt.ShipFromCode
			and fr.CustomerPart = fldidt.CustomerPart
			and fh.DocumentDT = fldidt.DocumentDT
			and fh.DocNumber = fldidt.DocNumber
			and fh.ControlNumber = fldidt.ControlNumber
			and fh.DocumentImportDT = fldidt.DocumentImportDT
	where
		fh.Status in
		(	0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
		,	1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
		)
	
--- </Body>

---	<Return>
	return
end
GO
