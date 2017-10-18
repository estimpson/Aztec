SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDI_XML_Ford_ASN].[udf_Root]
(	@ShipperID INT
,	@Purpose CHAR(2)
,	@PartialComplete INT
)
RETURNS XML
AS
BEGIN
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
	COALESCE(	(	select
				max(ar.RowNumber)
			from
				@asnReturnables ar
		),0)

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

	SET
		@xmlOutput =
			(	SELECT
					(	SELECT
							EDI_XML.TRN_INFO('002002FORD', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
						,	EDI_XML_V2002FORD.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML_V2002FORD.SEG_DTM('011', ah.ShipDateTime)
						,	(	SELECT
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1, NULL, 'S')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_TD1(ah.PackageType, ah.BOLQuantity)
								,	EDI_XML_V2002FORD.SEG_TD5('B', '02', ah.Carrier, ah.TransMode, ah.LocationQualifier, ah.PoolCode)
								,	EDI_XML_V2002FORD.SEG_TD3('TL', ah.BOLCarrier, ah.TruckNumber)
								,	CASE
										WHEN ah.PRONumber > '' THEN EDI_XML_V2002FORD.SEG_REF('CN', ah.PRONumber)
									END
								,	EDI_XML_V2002FORD.SEG_REF('BM', ah.BOLNumber)
								,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
								,	(	SELECT
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('ST', 92, ah.ShipTo)
						 				FOR XML RAW ('LOOP-N1'), TYPE
						 			)
								,	(	SELECT
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('SF', 92, ah.SupplierCode)
						 				FOR XML RAW ('LOOP-N1'), TYPE
						 			)
								,	(	SELECT
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('SU', 92, ah.SupplierCode)
						 				FOR XML RAW ('LOOP-N1'), TYPE
						 			)
								,	(	SELECT
						 					EDI_XML.LOOP_INFO('N1')
										,	EDI_XML_V2002FORD.SEG_N1('IC', 92, ah.ICCode)
						 				FOR XML RAW ('LOOP-N1'), TYPE
						 			)
				 				FOR XML RAW ('LOOP-HL'), TYPE
				 			)
						,	(	SELECT
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1+al.RowNumber, 1, 'I')
								,	EDI_XML_V2002FORD.SEG_LIN('BP', al.CustomerPart)
								,	EDI_XML_V2002FORD.SEG_SN1(NULL, al.QtyPacked, 'EA', al.AccumQty)
								,	CASE WHEN al.CustomerPO > '' THEN EDI_XML_V2002FORD.SEG_PRF(al.CustomerPO) END
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', al.GrossWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', al.NetWeight, 'LB')
								,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
								--,	(	SELECT
								--			EDI_XML.LOOP_INFO('CLD')
								--		,	EDI_XML_V2002FORD.SEG_CLD(al.BoxCount, al.BoxQty, al.BoxType)
								--		,	EDI_XML_Ford_ASN.SEG_REF_ObjectSerials(@ShipperID, al.CustomerPart, al.BoxType, al.BoxQty)
								--		FOR XML RAW ('LOOP-CLD'), TYPE
						 	--		)
								FROM
									@asnLines al
								ORDER BY
									al.RowNumber
				 				FOR XML RAW ('LOOP-HL'), TYPE
				 			)
						,	(	SELECT
				 					EDI_XML.LOOP_INFO('HL')
								,	EDI_XML_V2002FORD.SEG_HL(1+@ItemLoops+ar.RowNumber, 1, 'I')
								,	EDI_XML_V2002FORD.SEG_LIN('RC', ar.ReturnableCode)
								,	EDI_XML_V2002FORD.SEG_SN1(NULL, ar.ReturnableCount, 'EA', NULL)
								FROM
									@asnReturnables ar
								ORDER BY
									ar.RowNumber
				 				FOR XML RAW ('LOOP-HL'), TYPE
				 			)
						,	EDI_XML_V2002FORD.SEG_CTT(1 + @ItemLoops + @ReturnableLoops, @TotalQuantity)
						FROM
							EDI_XML_Ford_ASN.ASNHeaders ah
						WHERE
							ah.ShipperID = @ShipperID
						FOR XML RAW ('TRN-856'), TYPE
					)
				FOR XML RAW ('TRN'), TYPE
			)
--- </Body>

---	<Return>
	RETURN
		@xmlOutput
END



GO
