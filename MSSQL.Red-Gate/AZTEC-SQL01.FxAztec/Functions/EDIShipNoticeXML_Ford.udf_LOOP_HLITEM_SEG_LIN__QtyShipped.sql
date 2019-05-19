SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped]
(		@ShipperID INT
	,	@CustomerPart VARCHAR(50)
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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__SN1]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0350'
					,	[DE!1!name]='ASSIGNED IDENTIFICATION'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= ''
					FOR XML EXPLICIT, TYPE
				)

		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0382'
					,	[DE!1!name]='NUMBER OF UNITS SHIPPED'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]=''
					,	[DE!1]= CONVERT(INT,(SUM(sd.qty_packed)))
					FOR XML EXPLICIT, TYPE
				)
		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0355'
					,	[DE!1!name]='UNIT OR BASIS FOR MEASUREMENT CODE'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Each'
					,	[DE!1]= 'EA'
					FOR XML EXPLICIT, TYPE
				)
			 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0646'
					,	[DE!1!name]='QUANTITY SHIPPED TO DATE'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]=''
					,	[DE!1]= CONVERT(INT,(max(sd.accum_shipped)))
					FOR XML EXPLICIT, TYPE
				)
			
				FROM
					shipper_detail sd
				Cross Apply 
					( Select sum(sd2.qty_packed) as PriorShipmentQty
						from shipper_detail sd2 
						join shipper s on s.id =  sd2.shipper
						Join edi_setups es on es.destination = s.destination and isNULL(es.prev_cum_in_asn,'N') = 'Y'
						where sd2.order_no =  sd.Order_no and 
								sd2.date_shipped < sd.date_shipped and
								sd2.date_shipped >= [FT].[fn_TruncDate]('d', getdate()) and
								s.date_shipped is not NULL and
								s.status in ('C', 'Z') )  PriorShipmentsToday
				WHERE
					sd.shipper = @ShipperID
				AND
					sd.customer_part = @CustomerPart
				GROUP BY
					sd.customer_part
			FOR XML RAW ('SEG-SN1'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 





GO
