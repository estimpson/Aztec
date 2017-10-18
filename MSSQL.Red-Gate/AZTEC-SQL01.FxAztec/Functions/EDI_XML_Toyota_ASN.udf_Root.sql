SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [EDI_XML_Toyota_ASN].[udf_Root]
(	@ShipperID INT
,	@Purpose CHAR(2)
,	@PartialComplete INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	declare
		@xmlOutput xml

	declare
		@itemLoops int
	,	@totalQuantity int

	SELECT
		@itemLoops = COUNT(DISTINCT al.ManifestNumber) + COUNT(*)
	,	@totalQuantity = SUM(al.Quantity)
	FROM
		EDI_XML_Toyota_ASN.ASNLines al
	WHERE
		al.ShipperID = @ShipperID
	
	SET
		@xmlOutput =
			(	SELECT
					(	SELECT
							EDI_XML.TRN_INFO('004010', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete) 
						,	EDI_XML_V4010.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V4010.SEG_DTM('011', ah.ShipDateTime, ah.TimeZoneCode)
						,	(	SELECT
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V4010.SEG_HL(1, NULL, 'S', 1)
								,	EDI_XML_V4010.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V4010.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V4010.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V4010.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, NULL, NULL)
								,	EDI_XML_V4010.SEG_TD3('TL', NULL, ah.TruckNumber)
								,	EDI_XML_V4010.SEG_REF('BM', ah.BOLNumber)
								,	(	SELECT
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V4010.SEG_N1('SU', 92, ah.SupplierCode)
						 				FOR XML RAW ('LOOP-N1'), TYPE
						 			)
				 				FOR XML RAW ('LOOP-HL'), TYPE
				 			)
						,	EDI_XML_Toyota_ASN.LOOP_HL_OrderLines(@ShipperID)
						,	EDI_XML_V4010.SEG_CTT(1 + @ItemLoops, @TotalQuantity)
						FROM
							EDI_XML_Toyota_ASN.ASNHeaders ah
						WHERE
							ah.ShipperID = @ShipperID
						FOR XML RAW ('TRN-856'), TYPE
					)
				,	EDI_XML_Toyota_Invoice.udf_Root(@ShipperID, @Purpose, 0)
				FOR XML RAW ('TRN'), TYPE
			)
--- </Body>

---	<Return>
	RETURN
		@xmlOutput
END


GO
