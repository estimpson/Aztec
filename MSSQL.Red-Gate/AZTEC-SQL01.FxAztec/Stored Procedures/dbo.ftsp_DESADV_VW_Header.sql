SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [dbo].[ftsp_DESADV_VW_Header] (@shipper integer )
AS
BEGIN

 --DBO.ftsp_DESADV_VW_HEADER 20156
 

Create	table	#DESADVHeaderFlatFileLines (
				LineId	int identity,
				LineData varchar(75) )

Select	'' as partial_complete,
		CONVERT( char(76),shipper.ship_via) as bill_of_lading_scac_transfer,
		CONVERT( char(76), bill_of_lading.scac_pickup) AS SCACPickUp,
		CONVERT( char(76), carrier.name) AS CarrierName,
		CONVERT( char(76), case when shipper.freight_type = 'collect' then '1  ' else '2  ' end) AS FreightType,
		convert( char(76), case when shipper.trans_mode like 'A%' then '40 ' else '20 ' end) as TransMode,
		CONVERT( char(76), shipper.staged_pallets ) AS StagedPallets, 
		CONVERT( char(76), shipper.aetc_number ) AS AETCNumber,
		CONVERT( char(76), edi_setups.id_code_type) AS IDCodeType,
		CONVERT( char(76), edi_setups.parent_destination) AS ParentDestination, 
		CONVERT( char(76), edi_setups.material_issuer) AS MaterialIssuer,
		CONVERT( char(76), shipper.id) AS ShipperID, 
		CONVERT( char(76), shipper.date_shipped,112) AS DateShipped,
		CONVERT( char(76), DATEADD(dd,2,shipper.date_shipped), 112) AS ArrivalDate,
		CONVERT( char(76), GETDATE(),112) AS ASNDate,
		CONVERT( char(76), edi_setups.pool_code) AS Poolcode, 
		CONVERT( char(76), CONVERT(int, shipper.gross_weight * .45359237)) AS GrossWeight, 
		CONVERT( char(76), CONVERT(int, shipper.net_weight * .45359237)) AS NetWeight, 
		CONVERT( char(76), CONVERT(int, shipper.staged_objs)) AS StagedObjs, 
		CONVERT( char(76), shipper.ship_via ) AS SCAC,
		CONVERT( char(76), shipper.truck_number) AS TruckNumber, 
		CONVERT( char(76), shipper.pro_number) AS ProNumber, 
		CONVERT( char(76), shipper.seal_number) AS SealNumber, 
		CONVERT( char(76), shipper.destination) AS Destination, 
		CONVERT( char(76), shipper.plant) AS Plant,
		CONVERT( char(76), shipper.shipping_dock) AS ShippingDock,
		CONVERT( char(76), shipper.bill_of_lading_number) AS BOL, 
		CONVERT( char(76), shipper.date_shipped)AS TimeShipped, 
		CONVERT( char(76), bill_of_lading.equipment_initial) AS EquipInitial, 
		CONVERT( char(76), edi_setups.equipment_description) AS EquipDesription, 
		CONVERT( char(76), edi_setups.trading_partner_code) AS TradingPArtnerCode, 
		CONVERT( char(76), edi_setups.supplier_code) AS SupplierCode, 
		CONVERT( char(76), datepart(dy,getdate())) as DayofYr,
		CONVERT( char(76),(isNULL((Select	count(distinct Parent_serial) 
			from	audit_trail
			where	audit_trail.shipper = convert(char(10),@shipper) and
				audit_trail.type = 'S' and 
				isNULL(parent_serial,0) >0 ),0))) as pallets,
		CONVERT( char(76),(isNULL((Select	count(serial) 
			from	audit_trail,
				package_materials
			where	audit_trail.shipper = convert(char(10),@shipper) and
				audit_trail.type = 'S' and
				part <> 'PALLET' and 
				parent_serial is NULL and
				audit_trail.package_type = package_materials.code and
				package_materials.type = 'B' ),0))) as loose_ctns,
		CONVERT( char(76),(isNULL((Select	count(serial) 
			from	audit_trail,
				package_materials
			where	audit_trail.shipper =  convert(char(10),@shipper) and
				audit_trail.type = 'S' and 
				parent_serial is NULL and
				audit_trail.package_type = package_materials.code and
				package_materials.type = 'O' ),0))) as loose_bins,
				edi_setups.parent_destination as edi_shipto
		Into	#DESADVHeaderRaw
	from	shipper
	JOIN	edi_setups ON dbo.shipper.destination = dbo.edi_setups.destination 
	LEFT OUTER JOIN bill_of_lading  ON shipper.bill_of_lading_number = bill_of_lading.bol_number 
	left outer join carrier on shipper.bol_carrier = carrier.scac  
		 
	where	( ( shipper.id = @shipper ) )




								
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	SELECT	('//STX12//   '+ CONVERT(char(12),LEFT(TradingPArtnerCode,12))+LEFT(ShipperID,30)+ ' '+'DESADV    '+'DESADV') FROM #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	Select	('01'+ LEFT(ShipperID,8)) FROM #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	Select	('02'+ '137'+LEFT(ASNdate,35)+'102') FROM #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	Select	('02'+ '11 '+LEFT(DateShipped,35)+'102') FROM #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	Select	('02'+ '191'+LEFT(ArrivalDate,35)+'102') FROM #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('03'+ 'AAD' + 'KGM' +LEFT(GrossWeight,18)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('03'+ 'SQ ' + 'NMP' +LEFT(StagedObjs,18)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('03'+ 'AAL' + 'KGM' +LEFT(NetWeight,18)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('05' + LEFT(PoolCode,9) + '92 ') from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('07' + LEFT(Plant,35) + '92 ' + left(Destination,35)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('08' + LEFT(ShippingDock,25)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('09' + '   ' + LEFT(SupplierCode,9)) from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('10' + '12 ' + TransMode + '                         ' + '92 ' + left(CarrierName,35) + '146' + '5  ') from #DESADVHeaderRaw
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('11' + left(TruckNumber,35)) from #DESADVHeaderRaw 
	INSERT	#DESADVHeaderFlatFileLines (LineData)
	select	('12' + 'TE ' + left(TruckNumber,35) + '146') from #DESADVHeaderRaw
	
	

		
	Select	*
	From	#DESADVHeaderFlatFileLines
	order by 1 asc
		
		
		
	
end
GO
