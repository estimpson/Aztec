
/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_ASN.udf_Root
end
go

create function EDI_XML_Toyota_ASN.udf_Root
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
		@itemLoops = count(distinct al.ManifestNumber) + count(*)
	,	@totalQuantity = sum(al.Quantity)
	from
		EDI_XML_Toyota_ASN.ASNLines al
	where
		al.ShipperID = @ShipperID
	
	set
		@xmlOutput =
			(	select
					(	select
							EDI_XML.TRN_INFO('004010', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
						,	EDI_XML_V4010.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V4010.SEG_DTM('011', ah.ShipDateTime, ah.TimeZoneCode)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V4010.SEG_HL(1, null, 'S', 1)
								,	EDI_XML_V4010.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V4010.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V4010.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V4010.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, null, null)
								,	EDI_XML_V4010.SEG_TD3('TL', null, ah.TruckNumber)
								,	EDI_XML_V4010.SEG_REF('BM', ah.BOLNumber)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V4010.SEG_N1('SU', 92, ah.SupplierCode)
						 				for xml raw ('LOOP-N1'), type
						 			)
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	EDI_XML_Toyota_ASN.LOOP_HL_OrderLines(@ShipperID)
						,	EDI_XML_V4010.SEG_CTT(1 + @ItemLoops, @TotalQuantity)
						from
							EDI_XML_Toyota_ASN.ASNHeaders ah
						where
							ah.ShipperID = @ShipperID
						for xml raw ('TRN-856'), type
					)
				,	EDI_XML_Toyota_Invoice.udf_Root(@ShipperID, @Purpose, 0)
				for xml raw ('TRN'), type
			)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Toyota_ASN.udf_Root(76096, '00', 1)

select
	EDI_XML_Toyota_ASN.udf_Root(76023, '00', 1)
