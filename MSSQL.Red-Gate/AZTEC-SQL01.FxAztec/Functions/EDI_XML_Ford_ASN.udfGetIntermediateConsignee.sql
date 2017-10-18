SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [EDI_XML_Ford_ASN].[udfGetIntermediateConsignee] (
@ShipperID int
) RETURNS VARCHAR(25)
AS 
BEGIN 

DECLARE @ICCode VARCHAR(25)

SELECT @ICCode =
COALESCE(
		NULLIF(( SELECT MAX(c.ConsigneeCode) FROM
			Shipper s
				JOIN shipper_detail sd ON sd.shipper = s.id AND sd.shipper = @ShipperID
				JOIN EDIFord.BlanketOrders bo ON bo.BlanketOrderNo = sd.order_no
				join
				(Select * From EDIFord.CurrentShipSchedules()) c 
			on
				c.CustomerPart = bo.customerpart and
				c.ShipToCode = bo.EDIShipToCode and
				(	bo.CheckCustomerPOShipSchedule = 0
							or bo.CustomerPO = c.CustomerPO	)
					and	(	bo.CheckModelYearShipSchedule = 0
							or bo.ModelYear862 = c.CustomerModelYear	) 
			),'')
			,
			NULLIF(( SELECT MAX(c.ConsigneeCode) FROM
			Shipper s
				JOIN shipper_detail sd ON sd.shipper = s.id AND sd.shipper = @ShipperID
				JOIN EDIFord.BlanketOrders bo ON bo.BlanketOrderNo = sd.order_no
				join
				(Select * From EDIFord.CurrentPlanningReleases()) c 
			on
				c.CustomerPart = bo.customerpart and
				c.ShipToCode = bo.EDIShipToCode and
				(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = c.CustomerPO	)
					and	(	bo.CheckModelYearPlanning = 0
							or bo.ModelYear830 = c.CustomerModelYear	) 
			),'')
			,'')


RETURN @ICCode

END

GO
