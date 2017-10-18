SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_TRN_INFO]
(	@ShipperID INT,
	@PartialComplete INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	TRN-INFO*/
		(	SELECT
				name='SHIP NOTICE/MANIFEST'
			,	trading_partner = es.trading_partner_code
			,	ICN = COALESCE(es.IConnectID,'381')
			,	standard='X'
			,	agency='X'
			,	version='002002'
			,	type='856'
			,	PartialComplete = CASE WHEN @PartialComplete = 1 THEN 'Complete' ELSE 'Partial' END
			,	doc_number= CONVERT(VARCHAR(25),s.id)+ '_' + CONVERT(CHAR(8), GETDATE(), 112) + CONVERT(CHAR(2), GETDATE(), 108) + SUBSTRING(CONVERT(CHAR(8), GETDATE(), 108), 4, 2) + SUBSTRING(CONVERT(CHAR(8), GETDATE(), 108), 7, 2)
			,	ASNID = @ShipperID
			FROM
				shipper s
			JOIN
				edi_setups es ON es.destination = s.destination
			WHERE
				s.id = @ShipperID

			FOR XML RAW ('TRN-INFO'), TYPE
			)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END






GO
