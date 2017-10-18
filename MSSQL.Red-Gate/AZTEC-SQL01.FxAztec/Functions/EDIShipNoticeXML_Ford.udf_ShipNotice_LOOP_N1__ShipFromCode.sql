SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_N1__ShipFromCode]
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
		(	SELECT
			/*	LOOP-INFO*/
				(	SELECT
						name='N1 Loop'
					FOR XML RAW ('LOOP-INFO'), TYPE
				)
			/*	LOOP-HL*/
			,	(	SELECT
					(	SELECT
								code='N1'
							,	name='PARTY IDENTIFICATION'
							FOR XML RAW ('SEG-INFO'), TYPE
						)
						
					/*	DE 0098*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0098'
							,	[DE!1!name]='ENTITY IDENTIFIER CODE'
							,	[DE!1!type]='ID'
							,	[DE!1!desc]='Ship From'
							,	[DE!1]= 'SF'
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0093*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0093'
							,	[DE!1!name]='NAME'
							,	[DE!1!type]='AN'
							--,	[DE!1]= COALESCE(p.company_name, 'TSM Corporation')
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0066*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0066'
							,	[DE!1!name]='IDENTIFICATION CODE QUALIFIER'
							,	[DE!1!type]='ID'
							,	[DE!1!desc]='Assigned by Buyer or Buyers Agent'
							,	[DE!1]= '92'
							FOR XML EXPLICIT, TYPE
			 			)
						/*	DE 0067*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0067'
							,	[DE!1!name]='IDENTIFICATION CODE'
							,	[DE!1!type]='AN'
							,	[DE!1]= COALESCE(es.supplier_code, 'TSMCOR')
							FOR XML EXPLICIT, TYPE
			 			)
					FROM Shipper s 
					JOIN edi_setups es ON es.destination = s.destination
					CROSS JOIN dbo.parameters p
					WHERE s.id =  @ShipperID
					FOR XML RAW ('SEG-N1'), TYPE
				)
			
			FOR XML RAW ('LOOP-N1'), TYPE
		)
--- </Body>
-- Select [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_N1__SupplierCode] (1062979)
---	<Return>
	RETURN
		@outputXML
END







GO
