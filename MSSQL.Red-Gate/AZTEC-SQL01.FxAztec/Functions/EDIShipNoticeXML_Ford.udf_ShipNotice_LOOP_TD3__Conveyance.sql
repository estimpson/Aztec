SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_TD3__Conveyance]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	LOOP-HL*/
		--(	SELECT
		--	/*	LOOP-INFO*/
		--		(	SELECT
		--				name='TD3 Loop'
		--			FOR XML RAW ('LOOP-INFO'), TYPE
		--		)
			/*	LOOP-HL*/
				(	SELECT
					(	SELECT
								code='TD3'
							,	name='CARRIER DETAILS (EQUIPMENT)'
							FOR XML RAW ('SEG-INFO'), TYPE
						)
						
					/*	DE 0040*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0040'
							,	[DE!1!name]='EQUIPMENT DESCRIPTION CODE'
							,	[DE!1!type]='ID'
							,	[DE!1!desc]='Trailer (not otherwise specified)'
							,	[DE!1]='TL'
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0206*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0206'
							,	[DE!1!name]='EQUIPMENT INITIAL'
							,	[DE!1!type]='AN'
							,	[DE!1]=''
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0207*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0207'
							,	[DE!1!name]='EQUIPMENT NUMBER'
							,	[DE!1!type]='AN'
							--,	[DE!1!desc]=''
							,	[DE!1]= COALESCE(LEFT(s.truck_number,7), CONVERT(VARCHAR(15),s.id))
							FOR XML EXPLICIT, TYPE
			 			)
					FROM Shipper s 
					WHERE s.id =  @ShipperID
					FOR XML RAW ('SEG-TD3'), TYPE
				)
			
		--	FOR XML RAW ('LOOP-TD3'), TYPE
		--)
--- </Body>
-- Select [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_TD3__Conveyance] (1062979)
---	<Return>
	RETURN
		@outputXML
END







GO
