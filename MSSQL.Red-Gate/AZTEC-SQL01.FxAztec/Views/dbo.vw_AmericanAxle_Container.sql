SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vw_AmericanAxle_Container]
AS
SELECT     COALESCE (CONVERT(VARCHAR(25), dbo.object.serial), '') AS ObjectSerial, COALESCE ('UN' + dbo.edi_setups.supplier_code + CONVERT(VARCHAR(25), 
                      dbo.object.serial), '') AS LicensePlate, COALESCE (CONVERT(VARCHAR(25), CONVERT(INT, dbo.object.quantity)), '') AS ObjectQty, COALESCE (dbo.object.lot, '') AS Lot, 
                      COALESCE (dbo.order_header.customer_part, 'RELABEL AT SHIPPING') AS OHCustomerPart, COALESCE (dbo.order_header.customer_po, '') AS OHCustomerPO, 
                      COALESCE (dbo.order_header.dock_code, '') AS DockCode, COALESCE (dbo.order_header.line_feed_code, '') AS LineFeedCode, 
                      COALESCE (dbo.order_header.zone_code, '') AS AAGroupNo, COALESCE (dbo.order_header.line11, '') AS Line11, COALESCE (dbo.order_header.line12, '') AS Line12, 
                      COALESCE (dbo.order_header.line13, '') AS Line13, COALESCE (dbo.order_header.line14, '') AS Line14, COALESCE (dbo.order_header.line15, '') AS Line15, 
                      COALESCE (dbo.order_header.line16, '') AS Line16, COALESCE (dbo.order_header.line17, '') AS Line17, COALESCE (dbo.object.custom3, '') AS AAKanban, 
                      COALESCE (dbo.object.custom5, '') AS AAOrderNo, COALESCE (dbo.edi_setups.supplier_code, '') AS SupplierCode, COALESCE (dbo.edi_setups.parent_destination, 
                      dbo.edi_setups.destination, '') AS AAShipToID, COALESCE (dbo.parameters.company_name, '') AS CompanyName, COALESCE (dbo.parameters.address_1, '') 
                      AS CompanyAddress1, COALESCE (dbo.parameters.address_2, '') AS CompanyAddress2, COALESCE (dbo.parameters.address_3, '') AS CompanyAddress3, 
                      COALESCE (dbo.destination.address_1, '') AS ShipToAddress1, COALESCE (dbo.destination.address_2, '') AS ShipToAddress2, COALESCE (dbo.destination.address_3, 
                      '') AS ShipToAddress3, COALESCE (dbo.destination.address_4, '') AS ShipToAddress4, COALESCE (SUBSTRING(dbo.part.name, 1, 15), '') AS PartDesc1, 
                      COALESCE (SUBSTRING(dbo.part.name, 16, 15), '') AS PartDesc2, COALESCE (SUBSTRING(dbo.part.name, 32, 15), '') AS PartDesc3, 
                      COALESCE (dbo.order_header.engineering_level, '') AS AAECL, SUBSTRING(UPPER(CONVERT(VARCHAR(25), GETDATE(), 113)), 1, 2) 
                      + SUBSTRING(UPPER(CONVERT(VARCHAR(25), GETDATE(), 113)), 4, 3) + SUBSTRING(UPPER(CONVERT(VARCHAR(25), GETDATE(), 113)), 8, 4) AS AADate
FROM         dbo.object INNER JOIN
                      dbo.shipper ON ISNULL(CONVERT(varchar(25), dbo.object.shipper), dbo.object.origin) = CONVERT(VARCHAR(25), dbo.shipper.id) INNER JOIN
                      dbo.shipper_detail ON dbo.shipper.id = dbo.shipper_detail.shipper AND dbo.object.part = dbo.shipper_detail.part_original INNER JOIN
                      dbo.order_header ON dbo.shipper_detail.order_no = dbo.order_header.order_no INNER JOIN
                      dbo.edi_setups ON dbo.shipper.destination = dbo.edi_setups.destination INNER JOIN
                      dbo.destination ON dbo.shipper.destination = dbo.destination.destination INNER JOIN
                      dbo.part ON dbo.object.part = dbo.part.part CROSS JOIN
                      dbo.parameters
GO
