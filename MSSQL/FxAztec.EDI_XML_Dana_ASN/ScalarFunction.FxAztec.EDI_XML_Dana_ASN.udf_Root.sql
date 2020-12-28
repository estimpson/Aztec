
/*
Create ScalarFunction.FxAztec.EDI_XML_Dana_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Dana_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Dana_ASN.udf_Root
end
go

create function EDI_XML_Dana_ASN.udf_Root
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
		@asnOrders table
	(	ShipperID int
	,	CustomerPart varchar(30)
	,	QtyPacked int
	,	UnitPacked varchar(15)
	,	AccumQty numeric(20,6)
	,	CustomerPO varchar(25)
	,	GrossWeight int
	,	NetWeight int
	,	RowNumber int
	)
	insert
		@asnOrders
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	RowNumber
	)
	select
		ao.ShipperID
	,	ao.CustomerPart
	,	ao.QtyPacked
	,	ao.UnitPacked
	,	ao.AccumQty
	,	ao.CustomerPO
	,	ao.GrossWeight
	,	ao.NetWeight
	,	ao.RowNumber
	from
		EDI_XML_Dana_ASN.ASNOrders ao
	where
		ao.ShipperID = @ShipperID

	declare
		@ItemLoops int =
			(	select
					max(ao.RowNumber)
				from
					@asnOrders ao
			)

	declare
		@TotalQuantity int =
			(	select
					sum(ao.QtyPacked)
				from
					@asnOrders ao
			)
	
	declare
		@asnLines table
	(	ShipperID int
	,	CustomerPart varchar(30)
	,	QtyPacked int
	,	UnitPacked char(2)
	,	AccumQty int
	,	CustomerPO varchar(25)
	,	GrossWeight int
	,	NetWeight int
	,	BoxType varchar(20)
	,	BoxQty int
	,	BoxCount int
	,	RowNumber int
	)

	insert
		@asnLines
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	BoxType
	,	BoxQty
	,	BoxCount
	,	RowNumber
	)
	select
		al.ShipperID
	,	al.CustomerPart
	,	al.QtyPacked
	,	al.UnitPacked
	,	al.AccumQty
	,	al.CustomerPO
	,	al.GrossWeight
	,	al.NetWeight
	,	al.BoxType
	,	al.BoxQty
	,	al.BoxCount
	,	al.RowNumber
	from
		EDI_XML_Dana_ASN.ASNLines al
	where
		al.ShipperID = @ShipperID
	order by
		al.RowNumber

	declare
		@asnObjects table
	(	ShipperID int
	,	CustomerPart varchar(30)
	,	QtyPacked int
	,	UnitPacked char(2)
	,	AccumQty int
	,	CustomerPO varchar(25)
	,	GrossWeight int
	,	NetWeight int
	,	BoxType varchar(20)
	,	BoxQty int
	,	Serial int
	,	RowNumber int
	)

	insert
		@asnObjects
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	BoxType
	,	BoxQty
	,	Serial
	,	RowNumber
	)
	select
		ao.ShipperID
	,	ao.CustomerPart
	,	ao.QtyPacked
	,	ao.UnitPacked
	,	ao.AccumQty
	,	ao.CustomerPO
	,	ao.GrossWeight
	,	ao.NetWeight
	,	ao.BoxType
	,	ao.BoxQty
	,	ao.Serial
	,	ao.RowNumber
	from
		EDI_XML_Dana_ASN.ASNObjects ao
	where
		ao.ShipperID = @ShipperID
	order by
		ao.RowNumber


	set
		@xmlOutput =
			(	select
					(	select
							EDI_XML.TRN_INFO('004010', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
						,	EDI_XML_V4010.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V4010.SEG_DTM('011', ah.ShipDateTime, 'ET')
						,	EDI_XML_V4010.SEG_DTM('017', ah.EstimatedDeliveryDateTime, 'ET')
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V4010.SEG_HL(1, null, 'S', null)
								,	EDI_XML_V4010.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V4010.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V4010.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V4010.SEG_TD5('B', '02', ah.Carrier, ah.TransMode, null, null)
								,	EDI_XML_V4010.SEG_TD3('TL', ah.BOLCarrier, ah.TruckNumber)
								--,	case
								--		when ah.PRONumber > '' then EDI_XML_V4010.SEG_REF('CN', ah.PRONumber)
								--	end
								,	EDI_XML_V4010.SEG_REF('PK', ah.ShipperID)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V4010.SEG_N1('ST', 92, ah.ShipTo)
										,	EDI_XML_V4010.SEG_N2(ah.ShipToName)
										,	EDI_XML_V4010.SEG_N3(ah.ShipToAddress)
										,	EDI_XML_V4010.SEG_N4(ah.ShipToCity, ah.ShipToState, ah.ShipToZipCode, 'US')
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V4010.SEG_N1('SF', 92, ah.SupplierCode)
										,	EDI_XML_V4010.SEG_N2(ah.SupplierName)
										,	EDI_XML_V4010.SEG_N3(ah.SupplierAddress)
										,	EDI_XML_V4010.SEG_N4(ah.SupplierCity, ah.SupplierState, ah.SupplierZipCode, 'US')
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V4010.SEG_N1('SU', 92, ah.SupplierCode)
										,	EDI_XML_V4010.SEG_N2(ah.SupplierName)
										,	EDI_XML_V4010.SEG_N3(ah.SupplierAddress)
										,	EDI_XML_V4010.SEG_N4(ah.SupplierCity, ah.SupplierState, ah.SupplierZipCode, 'US')
						 				for xml raw ('LOOP-N1'), type
						 			)
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V4010.SEG_HL(1+ao.RowNumber, 1, 'O', null)
								,	EDI_XML_V4010.SEG_PRF(ao.CustomerPO)
								from
									@asnOrders ao
								order by
									ao.RowNumber
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V4010.SEG_HL(1+@ItemLoops+ao.RowNumber, 1+ao.RowNumber, 'I', null)
								,	EDI_XML_V4010.SEG_LIN(1, 'BP', ao.CustomerPart, null, null)
								,	EDI_XML_V4010.SEG_SN1(null, ao.QtyPacked, 'EA', ao.AccumQty)
								,	(	select
											EDI_XML.LOOP_INFO('CLD')
										,	EDI_XML_V4010.SEG_CLD(al.BoxCount, al.BoxQty, al.BoxType)
										,	(	select
										 			EDI_XML_V4010.SEG_REF('LS', aobj.Serial)
										 		from
										 			@asnObjects aobj
												where
													aobj.CustomerPart = al.CustomerPart
													and aobj.BoxType = al.BoxType
													and aobj.BoxQty = al.BoxQty
												for xml path (''), type
										 	)
										from
											@asnLines al
										where
											al.CustomerPart = ao.CustomerPart
										for xml raw ('LOOP-CLD'), type
						 			)
								from
									@asnOrders ao
								order by
									ao.RowNumber
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	EDI_XML_V4010.SEG_CTT(1 + 2 * @ItemLoops, @TotalQuantity)
						from
							EDI_XML_Dana_ASN.ASNHeaders ah
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
go

select
	EDI_XML_Dana_ASN.udf_Root(89235, '00', 0)

select
	*
from
	EDI_XML_Dana_ASN.ASNHeaders ah
where
	ah.ShipperID = 89235

select
	*
from
	EDI_XML_Dana_ASN.ASNLines al
where
	al.ShipperId = 89235

select
	EDI_XML_Dana_ASN.udf_Root(89244, '00', 0)

select
	*
from
	EDI_XML_Dana_ASN.ASNHeaders ah
where
	ah.ShipperID = 89244

select
	*
from
	EDI_XML_Dana_ASN.ASNOrders al
where
	al.ShipperId = 89244

select
	*
from
	EDI_XML_Dana_ASN.ASNLines al
where
	al.ShipperId = 89244

select
	EDI_XML_Dana_ASN.udf_Root(81136, '00', 0)

select
	*
from
	EDI_XML_Dana_ASN.ASNHeaders ah
where
	ah.ShipperID = 81136

select
	*
from
	EDI_XML_Dana_ASN.ASNOrders al
where
	al.ShipperId = 81136
