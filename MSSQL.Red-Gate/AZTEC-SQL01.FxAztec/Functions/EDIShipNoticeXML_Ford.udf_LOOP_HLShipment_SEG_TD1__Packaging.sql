SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_TD1__Packaging]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-ATH*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='TD1'
					,	name='CARRIER DETAILS (QUANTITY AND WEIGHT)'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0737*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0103'
					,	[DE!1!name]='PACKAGING CODE'
					,	[DE!1!type]='AN'
					,	[DE!1]='CNT90'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0738*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0080'
					,	[DE!1!name]='LADING QUANTITY'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= s.staged_objs
					FOR XML EXPLICIT, TYPE
			 	)
			
				FROM
					shipper s
				WHERE
					s.id = @ShipperID
			FOR XML RAW ('SEG-TD1'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 --Select [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_TD1__Packaging] (1062979)




GO
