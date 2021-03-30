SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_MAGNA].[Get856]
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
		@dictionaryVersion varchar(25) = '003060'

	declare
		@hlXML table
	(	HLID int
	,	ParentHLID int
	,	HL_XML xml
	,	CustomerPart varchar(30)
	,	PalletSerial int
	)

	insert
		@hlXML
	(	HLID
	,	ParentHLID
	,	HL_XML
	,	CustomerPart
	)
	select
		HLID = ap.HLID
	,	ParentHLID = ap.ParentHLID
	,	HL_XML =
		(	select
				EDI_XML.LOOP_INFO('HL')
			,	EDI_XML.SEG_HL(@dictionaryVersion, ap.HLID, ap.ParentHLID, 'O')
			,	EDI_XML.SEG_LIN(@dictionaryVersion, null, 'BP', ap.CustomerPart)
			,	EDI_XML.SEG_SN1(@dictionaryVersion, null, ap.QtyPacked, 'EA', ap.AccumShipped)
			,	EDI_XML.SEG_PRF(@dictionaryVersion, ap.CustomerPO)
			for xml raw ('LOOP-HL'), type
		)
	,	ap.CustomerPart
	from
	(	select distinct
			ap.ShipperID
		,	ap.CustomerPart
		,	ap.QtyPacked
		,	ap.Unit
		,	ap.AccumShipped
		,	ap.CustomerPO
		,	HLID = dense_rank() over (order by ap.CustomerPart) +
			rank() over (order by ap.CustomerPart)
		,	ParentHLID = 1
		from
			EDI_XML_MAGNA.ASNPallets ap
		where
			ap.ShipperID = @ShipperID
	) ap
	order by
		ap.CustomerPart

	insert
		@hlXML
	(	HLID
	,	ParentHLID
	,	HL_XML
	,	PalletSerial
	)
	select
		HLID = ap.HLID
	,	ParentHLID = ap.ParentHLID
	,	HL_XML =
		(	select
				EDI_XML.LOOP_INFO('HL')
			,	EDI_XML.SEG_HL(@dictionaryVersion, ap.HLID, ap.ParentHLID, 'I')
			,	case when ap.PalletSerial > 0 then EDI_XML.SEG_REF(@dictionaryVersion, 'LS', ap.PalletSerial, null, null) end
			,	(	select
			 			EDI_XML.LOOP_INFO('CLD')
					,	EDI_XML.SEG_CLD(@dictionaryVersion, ap.BoxCount, ap.BoxQty, 'CTN90')
					,	(	select
					 			(select EDI_XML.SEG_REF(@dictionaryVersion, 'LS', ab.Serial, null, null))
					 		from
					 			EDI_XML_MAGNA.ASNBoxes ab
							where
								ab.ShipperID = @ShipperID
								and ab.CustomerPart = ap.CustomerPart
								and coalesce(ab.PalletSerial, 0) = coalesce(ap.PalletSerial, 0)
								and ab.BoxQty = ap.BoxQty
							for xml path (''), type
					 	)
				 		for xml raw ('LOOP-CLD'), type
			 	)
			for xml raw ('LOOP-HL'), type
		)
	,	ap.PalletSerial
	from
	(	select
			ap.ShipperID
		,	ap.CustomerPart
		,	ap.QtyPacked
		,	ap.Unit
		,	ap.AccumShipped
		,	ap.CustomerPO
		,	ap.PalletSerial
		,	ap.BoxCount
		,	ap.BoxQty
		,	HLID =
				dense_rank() over (order by ap.CustomerPart) +
				rank() over (order by ap.CustomerPart) +
				dense_rank() over (partition by ap.CustomerPart order by ap.BoxQty, ap.PalletSerial)
		,	ParentHLID =
				dense_rank() over (order by ap.CustomerPart) +
				rank() over (order by ap.CustomerPart)
		from
			EDI_XML_MAGNA.ASNPallets ap
		where
			ap.ShipperID = @ShipperID
	) ap
	order by
		ap.CustomerPart
	,	ap.BoxQty
	,	ap.PalletSerial

	set
		@xmlOutput =
			(	select
					(	select
							EDI_XML.TRN_INFO(@dictionaryVersion, '856', ah.TradingPartnerID, ah.iConnectID, @ShipperID, @PartialComplete)
						,	EDI_XML.SEG_BSN(@dictionaryVersion, @Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
						,	EDI_XML.SEG_DTM(@dictionaryVersion, '011', ah.ShipDateTime)
						,	(	select
						 			EDI_XML.LOOP_INFO('HL')
								,	EDI_XML.SEG_HL(@dictionaryVersion, 1, null, 'S')
								,	EDI_XML.SEG_MEA(@dictionaryVersion, 'PD', 'G', ah.GrossWeight, 'LB')
								,	EDI_XML.SEG_MEA(@dictionaryVersion, 'PD', 'N', ah.NetWeight, 'LB')
								,	EDI_XML.SEG_TD1(@dictionaryVersion, 'CNT90', ah.BOLQuantity)
								,	EDI_XML.SEG_TD5(@dictionaryVersion, 'B', '2', ah.Carrier, ah.TransMode)
								,	(	select
								 			EDI_XML.LOOP_INFO('TD3')
										,	EDI_XML.SEG_TD3(@dictionaryVersion, ah.EquipmentType, null, ah.TruckNumber)
								 		for xml raw ('LOOP-TD3'), type
								 	)
								,	EDI_XML.SEG_REF(@dictionaryVersion, 'BM', ah.ShipperID, null, null)
								,	EDI_XML.SEG_REF(@dictionaryVersion, 'PK', ah.ShipperID, null, null)
								,	(	select
								 			EDI_XML.LOOP_INFO('N1')
										,	EDI_XML.SEG_N1(@dictionaryVersion, 'MI', ah.ShipToName, '92', ah.ShipTo)
								 		for xml raw ('LOOP-N1'), type
								 	)
								,	(	select
								 			EDI_XML.LOOP_INFO('N1')
										,	EDI_XML.SEG_N1(@dictionaryVersion, 'SU', ah.CompanyName, '92', ah.SupplierCode)
								 		for xml raw ('LOOP-N1'), type
								 	)
								,	(	select
								 			EDI_XML.LOOP_INFO('N1')
										,	EDI_XML.SEG_N1(@dictionaryVersion, 'ST', ah.ShipToName, '92', ah.ShipTo)
								 		for xml raw ('LOOP-N1'), type
								 	)
						 		for xml raw ('LOOP-HL'), type
						 	)
						,	(	select
						 	 		(select hl.HL_XML)
						 	 	from
						 	 		@hlXML hl
								order by
									hl.HLID
								for xml path (''), type
						 	)
						,	EDI_XML.SEG_CTT(@dictionaryVersion, ht.LineItems, ht.HashTotal)
						from
							EDI_XML_MAGNA.ASNHeaders ah
							cross apply
								(	select
										LineItems =
											(	select
													max(HLID)
												from
													@hlXML hx
											)
									,	HashTotal = sum(al.QtyPacked)
									from
										EDI_XML_MAGNA.ASNLines al
									where
										al.ShipperID = ah.ShipperID
								) ht
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
