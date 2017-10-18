SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_Toyota_Invoice].[udf_Root]
(	@ShipperID int
,	@Purpose char(2)
,	@PartialComplete int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set
		@xmlOutput =
			(	select
					EDI_XML.TRN_INFO('004010', '810', ih.TradingPartnerID, ih.iConnectID, ih.InvoiceNumber, 0)
				,	EDI_XML_V4010.SEG_BIG(ih.InvoiceDate, ih.InvoiceNumber)
				,	(	select
				 			EDI_XML.LOOP_INFO('IT1')
						,	EDI_XML_V4010.SEG_IT1(ih.KanbanCard, ih.Quantity, 'EA', ih.UnitPrice, 'QT', ih.CustomerPart, '1', 'N1')
						,	EDI_XML_V4010.SEG_REF('MK', left(ih.ManifestNumber, 8))
						,	EDI_XML_Toyota_Invoice.SEG_DTM('050', ih.InvoiceDate)
				 		for xml raw ('LOOP-IT1'), type
				 	)
				,	EDI_XML_V4010.SEG_TDS(round(ih.InvoiceAmount,2))
				,	EDI_XML_V4010.SEG_CTT(1, null)
				from
					EDI_XML_Toyota_Invoice.InvoiceHeaders ih
				where
					ih.ShipperID = @ShipperID
				for xml raw ('TRN-810'), type
			)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
