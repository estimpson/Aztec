SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_REF__BillOflading]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-REF*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='REF'
					,	name='REFERENCE INFORMATION'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0128*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0128'
					,	[DE!1!name]='REFERENCE IDENTIFICATION QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Bill of Lading Number'
					,	[DE!1]='BM'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0127*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0127'
					,	[DE!1!name]='REFERENCE IDENTIFICATION'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= COALESCE(s.bill_of_lading_number, s.id)
					FOR XML EXPLICIT, TYPE
			 	)
			
				FROM
					shipper s
				WHERE
					s.id = @ShipperID
			FOR XML RAW ('SEG-REF'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 --Select [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_REF__BillOflading] (1062979)





GO
