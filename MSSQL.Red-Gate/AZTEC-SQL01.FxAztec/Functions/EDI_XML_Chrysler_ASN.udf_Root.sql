SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE function [EDI_XML_Chrysler_ASN].[udf_Root]
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

	declare
		@itemLoops int
	,	@totalQuantity int

	select
		@itemLoops = 2 * count(*) + count(case when al.PalletCount > 0 then 1 end * case when al.PalletType like '%~%' then 2 else 1 end)
	,	@totalQuantity = sum(al.QtyPacked + al.BoxCount + al.PalletCount * case when al.PalletType like '%~%' then 2 else 1 end)
	from
		EDI_XML_Chrysler_ASN.ASNLines(@ShipperID) al
	
	set
		@xmlOutput =
			(	select
					(	select
							EDI_XML.TRN_INFO('002040', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
						,	EDI_XML_V2040.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V2040.SEG_DTM('011', ah.ShipDateTime, ah.TimeZoneCode)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2040.SEG_HL(1, null, 'S', 1)
								,	EDI_XML_V2040.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V2040.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V2040.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V2040.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, ah.LocationQualifier, ah.PoolCode)
								,	EDI_XML_V2040.SEG_TD3('TL', ah.EquipInitial, ah.TruckNumber)
								,	EDI_XML_V2040.SEG_REF('MB', ah.BOLNumber)
								,	EDI_XML_V2040.SEG_REF('BM', ah.BOLNumber)
								,   EDI_XML_V2040.SEG_REF('FR', ah.ProNumber)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2040.SEG_N1('SU', 92, ah.SupplierCode)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2040.SEG_N1('SF', 92, ah.SupplierCode)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2040.SEG_N1('BT', 92, ah.ShipTo)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2040.SEG_N1('ST', 92, ah.ShipTo)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2040.SEG_N1('MA', 92, ah.ShipTo)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	case
										when ah.AETC > '' then
											EDI_XML_V2040.SEG_ETD('ZZ', ah.AETCResponsibility, 'AE', ah.AETC)
									end
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines(@ShipperID)
						,	EDI_XML_V2040.SEG_CTT(1 + @ItemLoops, @TotalQuantity)
						from
							EDI_XML_Chrysler_ASN.ASNHeaders ah
						where
							ah.ShipperID = @ShipperID
						for xml raw ('TRN-856'), type
					)
				for xml raw ('TRN'), type
			)
--- </Body>

---	<Return>
	return
		@xmlOutput
end

GO
