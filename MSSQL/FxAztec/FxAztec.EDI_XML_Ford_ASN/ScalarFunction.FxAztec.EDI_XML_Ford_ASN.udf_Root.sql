
/*
Create ScalarFunction.FxAztec.EDI_XML_Ford_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.udf_Root
end
go

create function EDI_XML_Ford_ASN.udf_Root
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
	select
		*
	from
		EDI_XML_Ford_ASN.ASNLines(@ShipperID)
	order by
		ASNLines.RowNumber

	declare
		@ItemLoops int

	set	@ItemLoops =
		(	select
				max(al.RowNumber)
			from
				@asnLines al
		)

	declare
		@asnReturnables table
	(	ReturnableCode varchar(20)
	,	ReturnableCount int
	,	RowNumber int
	)

	insert
		@asnReturnables
	select
		*
	from
		EDI_XML_FORD_ASN.ASNReturnables(@ShipperID) ar
	order by
		ar.RowNumber

	declare
		@ReturnableLoops int

	set	@ReturnableLoops =
		(	select
				max(ar.RowNumber)
			from
				@asnReturnables ar
		)

	declare
		@TotalQuantity int

	set	@TotalQuantity =
		(	select
				sum(al.QtyPacked)
			from
				@asnLines al
		) +
		coalesce
		(	(	select
					sum(ar.ReturnableCount)
				from
					@asnReturnables ar
			)
		,	0
		)

	set
		@xmlOutput =
			(	select
					(	select
							EDI_XML.TRN_INFO('002002FORD', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
						,	EDI_XML_V2002FORD.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V2002FORD.SEG_DTM('011', ah.ShipDateTime)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1, null, 'S')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V2002FORD.SEG_TD5('B', '02', ah.Carrier, ah.TransMode, ah.LocationQualifier, ah.PoolCode)
								,	EDI_XML_V2002FORD.SEG_TD3('TL', ah.BOLCarrier, ah.TruckNumber)
								,	case
										when ah.PRONumber > '' then EDI_XML_V2002FORD.SEG_REF('CN', ah.PRONumber)
									end
								,	EDI_XML_V2002FORD.SEG_REF('BM', ah.BOLNumber)
								,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('ST', 92, ah.ShipTo)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('SF', 92, ah.SupplierCode)
						 				for xml raw ('LOOP-N1'), type
						 			)
								,	(	select
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('SU', 92, ah.SupplierCode)
						 				for xml raw ('LOOP-N1'), type
						 			)
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1+al.RowNumber, 1, 'I')
								,	EDI_XML_V2002FORD.SEG_LIN('BP', al.CustomerPart)
								,	EDI_XML_V2002FORD.SEG_SN1(null, al.QtyPacked, 'EA', al.AccumQty)
								,	case when al.CustomerPO > '' then EDI_XML_V2002FORD.SEG_PRF(al.CustomerPO) end
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', al.GrossWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', al.NetWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
								,	(	select
											EDI_XML.LOOP_INFO('CLD')
										,	EDI_XML_V2002FORD.SEG_CLD(al.BoxCount, al.BoxQty, al.BoxType)
										,	EDI_XML_Ford_ASN.SEG_REF_ObjectSerials(@ShipperID, al.CustomerPart, al.BoxType, al.BoxQty)
										for xml raw ('LOOP-CLD'), type
						 			)
								from
									@asnLines al
								order by
									al.RowNumber
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	(	select
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1+@ItemLoops+ar.RowNumber, 1, 'I')
								,	EDI_XML_V2002FORD.SEG_LIN('RC', ar.ReturnableCode)
								,	EDI_XML_V2002FORD.SEG_SN1(null, ar.ReturnableCount, 'EA', null)
								from
									@asnReturnables ar
								order by
									ar.RowNumber
				 				for xml raw ('LOOP-HL'), type
				 			)
						,	EDI_XML_V2002FORD.SEG_CTT(1 + @ItemLoops + @ReturnableLoops, @TotalQuantity)
						from
							EDI_XML_Ford_ASN.ASNHeaders ah
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
	EDI_XML_Ford_ASN.udf_Root(75964, '00', 0)

select
	*
from
	EDI_XML_Ford_ASN.ASNHeaders ah
where
	ah.ShipperID = 75964

select
	*
from
	EDI_XML_Ford_ASN.ASNLines(75964) al
