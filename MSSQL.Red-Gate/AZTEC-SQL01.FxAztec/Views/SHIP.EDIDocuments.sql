SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SHIP].[EDIDocuments]
as
select
	ShipperNumber = 'L' + convert(varchar(49), s.id)
,	ShipDT = s.date_shipped
,	LegacyShipperID = s.id
,	ShipperType = coalesce(s.type, 'N')
,	DocumentType = 1 --Should come from a more generic XML_DataRootFunction table.
,	OverlayGroup = esASN.asn_overlay_group
,	LegacyGenerator = case when esASN.auto_create_asn = 'Y' then 1 else 0 end
,	xsnadrf.FunctionName
,	xsnaeh.ExceptionHandler
,	cegl.FileStreamID
,	cegl.RowID
,	cegl.FileGenerationDT
,	cegl.FileSendDT
,	cegl.FileAcknowledgementDT
,	FileStatus = cegl.Status
from
	dbo.shipper s
	join dbo.edi_setups esASN
		on esASN.destination = s.destination
		and
		(	esASN.asn_overlay_group > ''
			or coalesce(esASN.auto_create_asn, 'N') != 'N'
		)
	left join EDI.XMLShipNotice_ASNDataRootFunction xsnadrf
		on xsnadrf.ASNOverlayGroup = esASN.asn_overlay_group
	outer apply
		(	select top 1
				xsnaeh.ExceptionHandler
			from
				EDI.XMLShipNotice_ASNExceptionHandler xsnaeh
			where
				xsnaeh.ASNOverlayGroup = esASN.asn_overlay_group
				and coalesce(xsnaeh.BillTo, s.customer) = s.customer
				and coalesce(xsnaeh.ShipTo, s.destination) = s.destination
			order by
				case when xsnaeh.ShipTo = s.destination then 0 else 1 end
			,	case when xsnaeh.BillTo = s.customer then 0 else 1 end
		) xsnaeh
	outer apply
		(	select top 1
				cegl.FileStreamID
			,	cegl.Status
			,	cegl.FileGenerationDT
			,	cegl.FileSendDT
			,	cegl.FileAcknowledgementDT
			,	cegl.RowID
			from
				dbo.CustomerEDI_GenerationLog cegl
			where
				cegl.ShipperID = s.id
				and cegl.Type = 1 --Should be DocumentType
			order by
				cegl.FileGenerationDT desc
		) cegl
where
	s.status in ('C', 'Z')
	and coalesce(s.type, 'N') = 'N'
GO
