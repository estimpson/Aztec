SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[usp_EDIInvoice_ToyotaCanada]  (@shipper INT)
AS
BEGIN
-- Test
-- Exec [dbo].[usp_EDIInvoice_ToyotaCanada] '71416'


/*
   
  
    FlatFile Layout for Overlay: TYT_856_D_v4010_TOYOTA SOI_121031     06-13-13 14:10

    Fixed Record/Fixed Field (FF)        Max Record Length: 080

    Input filename: DX-FX-FF.080         Output filename: DX-XF-FF.080


    Description                                            Type Start Length Element 

    Header Record '//'                                      //   001   002           

       RESERVED (MANDATORY)('STX12//')                      ID   003   007           

       X12 TRANSACTION ID (MANDATORY X12)                   ID   010   003           

       TRADING PARTNER (MANDATORY)                          AN   013   012           

       DOCUMENT NUMBER (MANDATORY)                          AN   025   030           

       FOR PARTIAL TRANSACTION USE A 'P' (OPTIONAL)         ID   055   001           

       EDIFACT(EXTENDED) TRANSACTION ID (MANDATORY EDIFACT) ID   056   010           

       DOCUMENT CLASS CODE (OPTIONAL)                       ID   066   006           

       OVERLAY CODE (OPTIONAL)                              ID   072   003           

       FILLER('      ')                                     AN   075   006           

       Record Length:                                                  080           

    Record '01'                                             01   001   002           

       PURPOSE                                              AN   003   002    1BSN01 - "00" - Original or "04" - Change - We will always send "00" from Fx

       SHIPMENT ID                                          AN   005   030    1BSN02 -shipper.id

       ASN DATE                                             DT   035   008    1BSN03 -system date 'CCYYMMDD'

       ASN TIME                                             TM   043   008    1BSN04 -system time "HHMM"

       FILLER('                              ')             AN   051   030           

       Record Length:                                                  080           

    Record '02' (10 x - End Record '02')                    02   001   002           

       DATE/TIME TYPE                                       AN   003   003    1DTM01 - "011" - Shipment Date; 

       DATE SHIPPED                                         DT   006   008    1DTM02 - shipper.date_shipped 'CCYYMMDD'

       TIME SHIPPED                                         TM   014   008    1DTM03 - shipper.date_shipped 'HHMM'

       TIME CODE                                            AN   022   002    1DTM04 - dbo.udfGetDSTIndication(date_shipped) returns either 'ED' or 'ET'

       ('                                               ... AN   024   057           

       Record Length:                                                  080           

    Record '03' (40 x - End Record '03')                    03   001   002           

       MEASUREMENT REF ID CODE                              AN   003   002    1MEA01 - "PD"

       MEASUREMENT TYPE                                     AN   005   003    1MEA02 - "G", "N" ( Use Gross 1st )

       MEASUREMENT VALUE                                    R    008   022    1MEA03 - int(shipper.gross_weight) , int(shipper.net_weight)

       ('                                               ... AN   030   051           

                                          1
    Description                                            Type Start Length Element 

       Record Length:                                                  080           

    Record '04' (20 x - End Record '04')                    04   001   002           

       PACKAGING CODE                                       AN   003   005    1TD101 - "CNT90" (Loose Boxes), "PLT90" (Pallets)

       LADING QUANTITY                                      N    008   008    1TD102 - shipper.staged_objs (parent_serial isnull or 0), count(distinct parent_serial)

       ('                                               ... AN   016   065           

       Record Length:                                                  080           

    Loop Start (12 x - End Record '07')                                              

       Record '05'                                          05   001   002           

          ROUTING SEQUENCE CODE                             AN   003   001    1TD501 - "B"

          ID CODE TYPE                                      AN   004   002    1TD502 - "2"

          ('                                            ... AN   006   075           

          Record Length:                                               080           

       Record '06'                                          06   001   002           

          ID CODE                                           AN   003   078    1TD503 - Shipper.carrier

          Record Length:                                               080           

       Record '07'                                          07   001   002           

          TRANSPORTATION METHOD/TYPE CODE                   AN   003   002    1TD504 - Shipper.trans_mode >> valid code (L – Contract Carrier E – Expedited Truck / suppliers expense CE – Customer Pickup / customer’s expense M – Motor (common carrier) SR – Supplier Truck)

          ('                                            ... AN   005   076           

          Record Length:                                               080           

    Record '08' (12 x - End Record '08')                    08   001   002           

       EQUIPMENT DESCRIPTION CODE                           AN   003   002    1TD301 - "TL"

       EQUIPMENT #                                          AN   005   010    1TD303 - shipper.truck_number

       ('                                               ... AN   015   066           

       Record Length:                                                  080           

    Record '09' (5 x - End Record '09')                     09   001   002           

       SPECIAL HANDLING CODE CH                             AN   003   003    1TD401 - Only used if hazardous material

       MATERIAL CODE TYPE                                   AN   006   001    1TD402 - Only used if hazardous material

       MATERIAL CLASS CODE                                  AN   007   004    1TD403 - Only used if hazardous material

       ('                                               ... AN   011   070           

       Record Length:                                                  080           

    Record '10' (999999 x - End Record '10')                10   001   002           

       REF ID                                               AN   003   030    1REF02 - "BM"

       ('                                                ') AN   033   048           

       Record Length:                                                  080           

                                          2
    Description                                            Type Start Length Element 

    Record '11'                                             11   001   002           

       ID CODE                                              AN   003   078    1N104  - coalesce(shipper.bill_of_lading_number, shipper.id)

       Record Length:                                                  080           

    Loop Start (200000 x - End Record '16')                                          

       Record '12'                                          12   001   002           

          PO #                                              AN   003   022    1PRF01 - (not defined in Fx) Format of PRF01 is MMMMMMMM-RRRRRRRR , where MMMMMMMM is the 8 position manifest, and RRRRRRRR is the 8 position receiving number. Manifest must be listed first and must be separated from the receiving number by a hyphen.

          ('                                            ... AN   025   056           

          Record Length:                                               080           

       Record '13' (999999 x - End Record '13')             13   001   002           

          REF ID                                            AN   003   030    2REF02 shipper.invoice_number Must be unique per PO (OPTIONAL)

          ('                                            ... AN   033   048           

          Record Length:                                               080           

       Record '14'                                          14   001   002           

          ID CODE                                           AN   003   078    2N104  edi_setups.supplier_code (OPTIONAL)

          Record Length:                                               080           

       Loop Start (200000 x - End Record '16')                                       

          Record '15'                                       15   001   002           

             ASSIGNED ID                                    AN   003   020    1LIN01 ---???? Optional

             PRODUCT/SERVICE ID TYPE                        AN   023   002    1LIN02 - "BP' Buyer Part 

             PRODUCT/SERVICE ID                             AN   025   030    1LIN03 - shipper_detail.customer_part

             PRODUCT/SERVICE ID TYPE                        AN   055   002    1LIN04 - "RC" - Kanban Number Qualifier

             FILLER('                        ')             AN   057   024           

             Record Length:                                            080           

          Record '16'                                       16   001   002           

             PRODUCT/SERVICE ID                             AN   003   030    1LIN05 - (not defined in Fx) Kanban Number 

             # OF UNITS SHIPPED                             R    033   012    1SN102 - (not defined in Fx) shipper_detail.qty_packed

             UOM                                            AN   045   002    1SN103 - "EA"

             FILLER('                                  ')   AN   047   034           

             Record Length:                                            080           





*/

set ANSI_Padding on
--ASN Header

declare
--Variables for Flat File


--//Line
		@TradingPartner	char(12),
		@DESADV char(10),
		@ShipperIDHeader char(30),
		@PartialComplete char(1) ,

--Header

		@1BSN01_Purpose char(2) = '00',									-- Purpose Code
		@1BSN02_ShipperID char(30),											--Shipper.id
		@1BSN03_SystemDate char(8),											--Getdate() 'CCYYMMDD'
		@1BSN04_SystemTime char(8),											--Getdate() 'HHMM'
		@1DTM01_DateShippedQualifier char(3) = '011',		--date shipped qualifier "011"
		@1DTM02_DateShipped char(8),										--shipper.date_shipped 'CCYYMMDD'
		@1DTM03_TimeShipped char(8),										--shipper.date_shipped 'HHMM'
		@1DTM04_TimeZone char(2),												-- dbo.udfGetDSTIndication(date_shipped) returns either 'ED' or 'ET'
		@1MEA01_PDQualifier char(2) = 'PD',															
		@1MEA02_GrossWeightQualifier char(3) = 'G',			--
		@1MEA03_Grossweight char(22),										--shipper.gross_weight
		@1MEA02_NetWeightQualifier char(3) = 'N',				--
		@1MEA03_Netweight char(22),											--shipper.net_weight
		@1TD101_PackCodeCNT90 char(5) = 'CNT90',				--Loose Container Indicator
		@1TD102_PackCountCNT90 char(8),									--count(1) of loose objects
		@1TD101_PackCodePLT90 char(5) = 'PLT90',				--Pallet Indicator
		@1TD102_PackCountPLT90 char(8)	,								--count(1) of distinct pallets
		@1TD501_RoutingSequence char(1) = 'B'	,					--Routing Sequence Code; appears to be B for all shipments
		@1TD502_IdCodeType char(2) = '2'	,							--'2'
		@1TD503_CarrierSCAC char(78)	,									--shipper.carrier
		@1TD504_ShipperTransMode char(2)	,							--shipper.trans_mode
		@1TD301_EquipmentDesc char(2) = 'TL',						--'TL'
		@1TD303_EquipmentNumber char(10),								--shipper.truck_number
		@1REF02_BillofLading char(30),									
		@1N104_SupplierCode char(78),
		@1PRF01_Manifest_ReceivingID char(22),					--manifest and receiver id
		@2REF02_ShipperInvoiceNo char(30) ,							--Invoice Number




		@1BGM010Purpose char(3),
		@1BGM020ShipperID char(55),
		@1BGM030Purpose char(1),
		@1DTM010QualifierASNDate char(3),	
		@1DTM010ASNDate char(12),
		@1DTM010QualifierDateShipped char(3),
		@1DTM010DateShipped char(12),
		@1DTM010QualifierArrivalDate char(3),
		@1DTM010ArrivalDate char(12),
		@3DTMDateTimeFormat char(3),
		@1MEA020QualifierGrossWeight Char(3),
		@1MEA020GrossWeight Char(18),
		@1MEA020GrossWeightUM Char(3),
		@1MEA020QualifierNetWeight Char(3),
		@1MEA020NetWeight Char(18),
		@1MEA020NetWeightUM Char(3),
		@1MEA020QualifierPackCount Char(3),
		@1MEA020PackCount Char(18),
		@1MEA020PackCountUM Char(3),
		@1RFF010REFTypeBMQualifier Char(3),
		@1RFF010REFTypeBM Char(35) ,
		@2RFF010ProNumber Char(35),
		@NADIDCodeType16 char(3) ,
		@NADIDCodeType92 char(3) ,
		@2NAD020MaterialIssuerQualifier char(3),
		@2NAD020MaterialIssuer char(35),
		@2NAD020ShipToIDQualifier char(3),
		@2NAD020ShipToID char(35),
		@1LOC020DockCode char(25),
		@2NAD020SupplierCodeQualifier char(3),
		@2NAD020SupplierCode char(35),
		@1TDT010TransStage char(2),
		@1TDT030TransMode char(3),
		@1TDT050SCAC char(17),
		@1TDT050RespAgency char(3),
		@1TDT070AETCReason char(3),
		@1TDT070AETCResponsibilty char(3),
		@1TDT070AETC char(17) ,
		@1EQD01EquipmentType char(3),
		@1EQD020EquipmentID char(17),
		@1SEL01SealNo char(10),





--Detail

		@2CPS01CPSCounter char(12),
		@2CPS03CPSIndicator char(3),
		@1PAC01PackageCount char(10),
		@1PAC01PackageType char(17),
		@1PCI01MarkingInstructions char(3),
		@3RFF010ProNumber char(35),
		@1LIN01LineItem char(20) = '001',
		@1LIN02CustomerPartBP char(2) = 'BP',
		@1LIN03CustomerPart char(30),
		@1LIN04KanbanRC char(2) = 'RC',
		@1LIN05Kanban char(30),
		@1SN102QtyShipped char(12),
		@1SN103QtyShippedUM char(2) ='EA',
		@1PIAModelYear char(35),
		@2QTY010QtyTypeShipped char(3) ,
		@2QTY010QtyShipped char(14),
		@2QTY010QtyShippedUM char(3) ,
		@2QTY010AccumTypeShipped char(3) ,
		@2QTY010AccumShipped char(14),
		@2QTY010AccumShippedUM char(3),
		@1RFF010CustomerPOType char(3),
		@1RFF010CustomerPO char(25),
		@2REF02InvoiceNumber char(30),
		@1PRF01ManifestReceiverNo char(22),


	--Variables for Processing Data

	@PackTypeType int,
	@InternalPart varchar(25),
	@PackageType varchar(25),
	@PalletPackageType varchar(25),
	@CPS03Indicator int

	
	Select @1PIAModelYear = SUBSTRING(CONVERT(VARCHAR(25), GETDATE(), 112),3,2)
	Select @DESADV =  'DESADV'
	Select @ShipperIDHeader = @Shipper
	Select @PartialComplete = ''
	Select @1BGM010Purpose = '351'
	Select @1BGM030Purpose  = '9'
	Select @1DTM010QualifierASNDate = '137'
	Select @1DTM010QualifierDateShipped = '11'
	Select @1DTM010QualifierArrivalDate = '132'
	Select @3DTMDateTimeFormat  = '203'
	Select @1MEA020QualifierGrossWeight = 'G'
	Select @1MEA020GrossWeightUM  = 'LBR'
	Select @1MEA020QualifierNetWeight = 'N'
	Select @1MEA020NetWeightUM = 'LBR'
	Select @1MEA020QualifierPackCount = 'SQ'
	Select @1MEA020PackCountUM = 'C62'
	Select @1RFF010REFTypeBMQualifier = 'MB'
	Select @NADIDCodeType16 = '16'
	Select @NADIDCodeType92 = '92'
	Select @2NAD020MaterialIssuerQualifier = 'MI'
	Select @2NAD020ShipToIDQualifier = 'ST'
	Select @2NAD020SupplierCodeQualifier = 'SU'
	Select @1TDT010TransStage = '12'
	Select @1TDT050RespAgency = '182'
	Select @1EQD01EquipmentType = 'TE'

	Select @1PCI01MarkingInstructions = '16'
	Select @2QTY010QtyTypeShipped = '12'
	Select @2QTY010QtyShippedUM = 'C62'
	Select @2QTY010AccumTypeShipped = '3'
	Select @2QTY010AccumShippedUM = 'C62'
	Select @1RFF010CustomerPOType = 'ON'





Declare
	@PurposeCode char(2) = '00',	
	@ASNDate char(8),
	@ASNTime char(8),
	@ASNDateTime char(35),
	@ShippedDateQualifier char(3) = '011',
	@ShippedDate char(8),
	@ShippedTime char(8),
	@ShipDateTimeZone char(2),
	@ShippedDateTime char(35),
	@ArrivalDateQualifier char(3) = '017',
	@ArrivalDate char(8),
	@ArrivalTime char(8),
	@ArrivalDateTimeZone char(2),
	@ArrivalDateTime char(35),
	@GrossWeightQualifier char(3),
	@GrossWeightLbs char(22),
	@NetWeightQualifier char(3),
	@NetWeightLbs char(22),
	@TareWeightQualifier char(3),
	@TareWeightLbs char(22),
	@TD101_PackagingCode char(5),
	@TD102_PackCount char(8),
	@TD501_RoutingSequence char(2) = 'B',
	@TD502_IDCodeType char(2) = '2',
	@TD503_SCAC char(78),
	@TD504_TransMode char(2),
	@TD507_LocType char(2) = 'OR',
	@TD508_Location char(30) = 'DTW',
	@EQD_01_TrailerNumberQual char(3) = 'TL',	
	@EQD_02_01_TrailerNumber char(17),
	@REFBMQual char(3),
	@REFPKQual char(3),
	@REFCNQual char(3),
	@REFBMValue char(78),
	@REFPKValue char(78),
	@REFCNValue char(78),
	@FOB01_MethodOfPayment char(2),
	@FOB02_LocType char(2) = 'CA',
	@FOB03_LocDescription char(78) = 'US',
	@FOB04_TransTermsType char(2) = '01',
	@FOB05_TransTermsCode char(3),
	@FOB06_LocationType char(2) = 'AC',
	@FOB07_LocationDesription char(78) = '',
	@N102_SupplierName char(60) = '',
	@N104_SupplierCode char(78),
	@N102_ShipToName char(60),
	@N104_ShipToID char(78),
	@REF02_DockCode char(78),
	@N104_RemitToCode char(78),
	@N102_RemitToName char(60),
	@TD301_EquipmentDesc  char(2) = 'TL' ,
	@TD302_EquipmentIntial char(4),
	@TD3031_EquipmentNumber char(15),
	@TD305_GrossWeight char(12),
	@TD305_GrossWeightUM char(2) ='LB',
	@TDT03_1_TransMode char(5),
	@TD309_SealNumber char(15),
	@TD310_EquipmentType char(4),
	@N104_ContainerCode char(78),
	@N102_ContainerLocation char(60),
	@RoutingCode char(35),
	@BuyerID char(35),
	@BuyerName char(35),
	@SellerID char(35),
	@SellerName char(75),
	@SoldToID char(35),
	@ConsolidationCenterID char(35),
	@SoldToName char(35),
	@ConsolidationCenterName char(35),
	@LOC02_DockCode char(25),
	@MEAGrossWghtQualfier char(3) = 'G',
	@MEANetWghtQualfier char(3) = 'N',
	@MEATareWghtQualfier char(3) = 'T',
	@MEALadingQtyQualfier char(3) = 'SQ',
	@MEAGrossWghtUMKG char(3) = 'KG',
	@MEANetWghtUMKG char(3) = 'KG',
	@MEALadingQtyUM char(3) = 'C62',
	@MEAGrossWghtKG char(18),
	@MEANetWghtKG  char(18), 
	@MEALadingQty char(18),
	@MEAGrossWghtLBS char(22),
	@MEANetWghtLBS  char(22),
	@MEATareWghtLBS  char(22), 
	@MEAGrossWghtUMLB char(2) = 'LB',
	@MEANetWghtUMLB char(2) = 'LB',
	@MEATareWghtUMLB char(2) = 'LB',
	@REFProNumber char(35),
	@NADBuyerAdd1 char(35) = ' ' ,
	@NADSupplierAdd1 char(35) = '',
	@NADShipToAdd1 char(35) = '',
	@NADShipToID char(35)

	
	select
		@TradingPartner	= coalesce(nullif(es.trading_partner_code,''), 'TMMI'),
		@1BSN02_ShipperID  =  s.id,
		@1BSN03_SystemDate = CONVERT(VARCHAR(25), GETDATE(), 112)+LEFT(CONVERT(VARCHAR(25), GETDATE(), 108),2) +SUBSTRING(CONVERT(VARCHAR(25), GETDATE(), 108),4,2),
		@1BSN04_SystemTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@1DTM02_DateShipped= CONVERT(VARCHAR(25), s.date_shipped, 112)+LEFT(CONVERT(VARCHAR(25), s.date_shipped, 108),2) +SUBSTRING(CONVERT(VARCHAR(25), s.date_shipped, 108),4,2),
		@1DTM03_TimeShipped = left(replace(convert(char, s.date_shipped, 108), ':', ''),4),
		@1DTM04_TimeZone = dbo.udfGetDSTIndication(date_shipped),
		@1MEA03_Grossweight = convert(int, s.gross_weight),
		@1MEA03_Netweight = convert(int, s.net_weight),
		@1TD102_PackCountCNT90 = convert(int , s.staged_objs),
		@1TD503_CarrierSCAC = Coalesce(s.ship_via,''),
		@1TD504_ShipperTransMode = coalesce(s.trans_mode, 'LT'),
		@1TD303_EquipmentNumber = Coalesce(s.truck_number, convert(varchar(15),s.id)),
		@1REF02_BillofLading = coalesce(s.bill_of_lading_number, s.id),
		@1N104_SupplierCode = coalesce(es.supplier_code,''),
		@1RFF010REFTypeBM = coalesce(s.bill_of_lading_number, s.id),
		@2RFF010ProNumber = coalesce(s.pro_number, convert(varchar(15),s.id)),
		@2NAD020MaterialIssuer = coalesce(es.material_issuer,'17501'),
		@2NAD020ShipToID =  coalesce(substring(s.destination,2,10), NULLIF(es.parent_destination,'') ,s.destination ,''),
		@1LOC020DockCode = coalesce(s.shipping_dock,''),
		@2NAD020SupplierCode = coalesce(es.supplier_code,''),
		@1TDT030TransMode = coalesce(s.trans_mode, 'LT'),
		@1TDT050SCAC = Coalesce(s.ship_via,''),
		@1EQD020EquipmentID = Coalesce(s.truck_number, convert(varchar(15),s.id)),
		@1TDT070AETCReason = '',-- coalesce(substring(s.aetc_number,1,1),''),
		@1TDT070AETCResponsibilty = '', --coalesce(substring(s.aetc_number,2,1),'') ,
		@1TDT070AETC = '',-- coalesce(substring(s.aetc_number,3,25),''),
		@1SEL01SealNo = coalesce(s.seal_number,'') ,
		
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ASNDateTime = rtrim(@ASNDate)+rtrim(@ASNTime),
		@ShippedDate = convert(char, s.date_shipped, 112)  ,
		@ShipDateTimeZone = [dbo].[udfGetDSTIndication](s.date_shipped),
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@ShippedDateTime = rtrim(@ShippedDate)+rtrim(@ShippedTime),
		@ArrivalDate = convert(char, dateadd(dd,1, s.date_shipped), 112)  ,
		@ArrivalTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@ArrivalDateTimeZone = [dbo].[udfGetDSTIndication](s.date_shipped),
		@ArrivalDateTime = rtrim(@ArrivalDate)+rtrim(@ArrivalTime),
		@MEAGrossWghtLBS = convert(char,convert(int,s.gross_weight)),
		@MEANetWghtLBS = convert(char,convert(int,s.net_weight)),
		@MEATareWghtLBS = convert(char,convert(int,s.gross_weight-s.net_weight)),
		@MEAGrossWghtKG = convert(char,convert(int,s.gross_weight/2.2)),
		@MEANetWghtKG = convert(char,convert(int,s.net_weight/2.2)),
		@TD101_PackagingCode = 'CNT71' ,
		@TD102_PackCount = s.staged_objs,
		@TD503_SCAC = s.ship_via,
		@TD504_TransMode = coalesce(s.trans_mode,'M'),
		@TD302_EquipmentIntial = left(coalesce(nullif(s.truck_number,''), convert(varchar(15),s.id)),3),
		@REFBMQual = 'BM' ,
		@REFPKQual = 'PK',
		@REFCNQual = 'CN',
		@REFBMValue = coalesce(bill_of_lading_number, id),
		@REFPKValue = id,
		@REFCNValue = coalesce(pro_number,''),
		@FOB01_MethodOfPayment = case when freight_type =  'Collect' then 'CC' when freight_type in  ('Consignee Billing', 'Third Party Billing') then 'TP' when freight_type  in ('Prepaid-Billed', 'PREPAY AND ADD') then 'PA' when freight_type = 'Prepaid' then 'PP' else '' end ,
		@RoutingCode = 'NA',
		@ConsolidationCenterID  = case when trans_mode like '%A%' then '' else coalesce(pool_code, '') end,
		@ConsolidationCenterName = coalesce((select max(name) from destination where destination = pool_code),''),
		@SoldToID = d.destination,
		@SoldToName =  d.name,
		@N104_ShipToID = coalesce(es.parent_destination, es.destination) ,
		@REF02_DockCode = coalesce(s.shipping_dock,''),
		@N102_ShipToName =  d.name,
		@SellerID =  coalesce(es.supplier_code,'Empire'),
		@SellerName = 'Empire',
		@N104_SupplierCode =  coalesce(nullif(es.supplier_code,''),'Empire'),	
		@N102_SupplierName = 'Empire',
		@BuyerID = c.customer,
		@BuyerName = 'Yazaki',
		@FOB05_TransTermsCode = case 
						when s.freight_type like '%[*]%' 
						then substring(s.freight_type, patindex('%[*]%',s.freight_type)+1, 3)
						else s.freight_type
						end,
		@TD305_GrossWeight = convert(char,convert(int,s.gross_weight)),
		@TD305_GrossWeightUM = 'LB',
		@TD309_SealNumber = coalesce(s.seal_number,''),
		@TD310_EquipmentType = 'LTRL'


	from
		Shipper s
	join
		dbo.edi_setups es on s.destination = es.destination
	join
		dbo.destination d on es.destination = d.destination
	join
		dbo.customer c on c.customer = s.customer
	
	where
		s.id = @shipper


Create	table	#ASNFlatFile (
				LineId	int identity,
				LineData char(78) )

INSERT	#ASNFlatFile (LineData)
	SELECT	('//STX12//856'
						+  @TradingPartner 
						+  @ShipperIDHeader
						--+ 'P')
						+  @PartialComplete )


INSERT	#ASNFlatFile (LineData)
	SELECT	(	'01'
				+		@1BSN01_Purpose
				+		@1BSN02_ShipperID
				+		@1BSN03_SystemDate
				+		@1BSN04_SystemTime
						)


INSERT	#ASNFlatFile (LineData)
	SELECT	(	'02'
				+		@1DTM01_DateShippedQualifier
				+		@1DTM02_DateShipped
				+		@1DTM03_TimeShipped
				+		@1DTM04_TimeZone
						)


INSERT	#ASNFlatFile (LineData)
	SELECT	(	'03'
				+		@1MEA01_PDQualifier
				+		@1MEA02_GrossWeightQualifier
				+		@1MEA03_Grossweight
						)

INSERT	#ASNFlatFile (LineData)
		SELECT	(	'03'
				+		@1MEA01_PDQualifier
				+		@1MEA02_NetWeightQualifier
				+		@1MEA03_Netweight
						)


INSERT	#ASNFlatFile (LineData)
	SELECT	(	'04'
				+ @1TD101_PackCodeCNT90
				+ @1TD102_PackCountCNT90		
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'05'
				+		@1TD501_RoutingSequence
				+		@1TD502_IdCodeType	
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'06'
				+		@1TD503_CarrierSCAC
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'07'
				+		@1TD504_ShipperTransMode
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'08'
				+		@1TD301_EquipmentDesc
				+		@1TD303_EquipmentNumber
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'10'
				+		@1REF02_BillofLading
						)

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'11'
				+		@1N104_SupplierCode
						)


 --ASN Detail

declare	@ShipperDetail table (
	ID int identity(1,1),
	InvoiceNumber int, 
	KanbanNumber varchar(30),
	CustomerPart char(30),
	ManifestReceiverNo char(22),
	QtyShipped int, primary key (ID))
	
insert	@ShipperDetail 
(	InvoiceNumber,
	KanbanNumber,
	CustomerPart,
	ManifestReceiverNo,
	QtyShipped
	)
	
select
	coalesce(s.invoice_number,@Shipper),
	'M390',
	md.CustomerPart,
	md.ManifestNumber,
	md.Quantity
from
	shipper s
join
		editoyota.Pickups mp on mp.ShipperID = s.id
join
		editoyota.ManifestDetails md on md.PickUpID = mp.RowID
Where
	s.id = @shipper
AND
		md.Quantity > 0
	
	
/*declare	@AuditTrailSerial table (
Part varchar(25),
ObjectPackageType varchar(35),
PalletPackageType varchar(35),
SerialQuantity int,
ParentSerial int,
Serial int, 
id int identity primary key (id))
	
insert	@AuditTrailSerial 
(		Part,
		ObjectPackageType,
		PalletPackageType,	
		SerialQuantity,
		ParentSerial,
		Serial 
)
	
select
	at.part,
	coalesce( pm.name, at.package_type,'0000CART'),
	Coalesce((Select max(package_type) 
		from audit_trail at2
		left join package_materials pm2 on pm2.code =  at2.package_Type
		where		at2.serial = at.parent_serial and
						at2.shipper = convert(varchar(15),@shipper)  and
						at2.type = 'S'and
						at2.part = 'PALLET'
		),'0000PALT'),
	quantity,
	isNull(at.parent_serial,0),
	serial
from
	dbo.audit_trail at
left join
	dbo.package_materials pm on pm.code = at.package_type
Where
	at.shipper = convert(varchar(15),@shipper) and
	at.type = 'S' and
	part != 'Pallet'
order by		isNull(at.parent_serial,0), 
						part, 
						serial

--declare	@AuditTrailPartPackGroupRangeID table (
--Part varchar(25),
--PackageType varchar(35),
--PartPackQty int,
--Serial int,
--RangeID int, primary key (Serial))


--insert	@AuditTrailPartPackGroupRangeID
--(	Part,
--	PackageType,
--	PartPackQty,
--	Serial,
--	RangeID
--)

--Select 
--	atl.part,
--	atl.PackageType,
--	SerialQuantity,
--	Serial,
--	Serial-id
	
--From
--	@AuditTrailSerial atL
--join
--	@AuditTrailPartPackGroup atG on
--	atG.part = atl.part and
--	atg.packageType = atl.PackageType and
--	atg.partPackQty = atl.SerialQuantity



--declare	@AuditTrailPartPackGroupSerialRange table (
--Part varchar(25),
--PackageType varchar(35),
--PartPackQty int,
--SerialRange varchar(50), primary key (SerialRange))


--insert	@AuditTrailPartPackGroupSerialRange
--(	Part,
--	PackageType,
--	PartPackQty,
--	SerialRange
--)

--Select 
--	part,
--	PackageType,
--	PartPackQty,
--	Case when min(serial) = max(serial) 
--		then convert(varchar(15), max(serial)) 
--		else convert(varchar(15), min(serial)) + ':' + convert(varchar(15), max(serial)) end
--From
--	@AuditTrailPartPackGroupRangeID atR

--group by
--	part,
--	PackageType,
--	PartPackQty,
--	RangeID


/*	Select * From @ShipperDetail
	Select * From @AuditTrailLooseSerial
	Select * From @AuditTrailPartPackGroupRangeID
	Select * From @AuditTrailPartPackGroup
	Select * From @AuditTrailPartPackGroupSerialRange
*/


--Delcare Variables for ASN Details		
/*
declare	
	@LineItemID char(6),
	@REF02_PalletSerial char(2),
	@PAL01_PalletPackType char(78),
	@PAL02_PalletTiers char(4),
	@PAL03_PalletBlocks char(4),
	@PAL05_PalletTareWeight char(10),
	@PAL06_PalletTareWeightUM char(2),
	@PAL07_Length char(10),
	@PAL08_Width char(10),
	@PAL09_Height char(10),
	@PAL10_DimUM char(2),
	@PAL11_PalletGrossWeight char(10),
	@PAL12_PalletGrossWeightUM char(2),
	@LIN02_BPIDtype char(2) = 'BP',
	@LIN02_CustomerPart char(48) ,
	@LIN02_VPIDtype char(2) = 'VP',
	@LIN02_VendorPart char(48) ,
	@LIN02_PDIDtype char(2) = 'PD',
	@LIN02_PartDescription char(48) ,
	@LIN02_POIDtype char(2) = 'PD',
	@LIN02_CustomerPO char(48) ,
	@LIN02_CHIDtype char(2) = 'CH',
	@LIN02_CountryOfOrigin char(48) = 'HN' ,
	@SN102_QuantityShipped char(12),
	@SN103_QuantityShippedUM char(2) = 'PC',
	@SN104_AccumQuantityShipped char(17),
	@REF01_PKIDType char(3),
	@REF02_PackingSlipID char(78),
	@REF03_PackingSlipDescription char(78),
	@REF01_IVIDType char(3) = 'IV',
	@REF02_InvoiceIDID char(78),
	@CLD01_LoadCount char(6),
	@CLD02_PackQuantity char(12),
	@CLD03_PackCode char(5),
	@CLD04_PackGrossWeight char(10),
	@CLD05_PackGrossWeightUM char(2) = 'LB',
	@REF02_ObjectSerial char(78) ,
	@REF04_ObjectLot char(78) ,
	@DTM02_ObjectLot char(78) ,
	@Part varchar(50),
	@SupplierPart char(35),
	@SupplierPartQual char(3),
	@CountryOfOrigin char(3),
	@PartQty char(12),
	@PartAccum char(12),
	@PartUM char(3),
	@CustomerPO char(35),
	@CustomerECL char(35),
	@CustomerECLQual char(3),
	@PackageType char(17),
	@DunnagePackType char(17),
	@DunnageCount char(10),
	@DunnageIdentifier char(3),
	@PartPackQty char(17),
	@PartPackCount char(10),
	@PCIQualifier char(3),
	@Serial char(20),
	@DockCode char(25),
	@PCI_S char(3),
	@PCI_M char(3),
	@SupplierSerial char(35),
	@CPS03 Char(3),
	@UM char(3)
	 
--Populate Static Variables
select	@CountryOfOrigin = 'CA'
select	@PartUM = 'EA'	
select	@PCI_S = 'S'
select	@PCI_M = 'M'
Select	@DunnageIdentifier = '37'
Select	@DunnagePackType = 'YazakiDunnage'
Select	@UM = 'C62'
Select  @PCIQualifier = '17'
Select 	@CPS03 = 1
Select	@SupplierPartQual = 'SA'
Select	@CustomerECLQual = 'DR'
Select	@REF02_InvoiceIDID = @shipper
Select	@REF02_PackingSlipID = @shipper
 */
 
 
 */		
 Declare
		Manifest cursor local for

Select
		Distinct
		InvoiceNumber = InvoiceNumber,
		ManifestNo = ManifestReceiverNo
From
		@ShipperDetail SD

open
	Manifest

while
	1 = 1 begin
	
	fetch
		Manifest
	into
		@2REF02InvoiceNumber,
		@1PRF01ManifestReceiverNo

		if	@@FETCH_STATUS != 0 begin
		break
	end

		Insert	#ASNFlatFile (LineData)
					Select  '12' 									
							+ @1PRF01ManifestReceiverNo

	Insert	#ASNFlatFile (LineData)
					Select  '13' 									
							+ @2REF02InvoiceNumber

	Insert	#ASNFlatFile (LineData)
					Select  '14' 									
							+ @1N104_SupplierCode


declare
	PartsPerManifest cursor local for
select
	CustomerPart = customerpart,
	KanbanNumber = KanbanNumber,
	QtyShipped = convert(int, QtyShipped)
From
	@ShipperDetail SD
	where
		SD.ManifestReceiverNo = @1PRF01ManifestReceiverNo

open
	PartsPerManifest

while
	1 = 1 begin
	
	fetch
		PartsPerManifest
	into
		@1LIN03CustomerPart,
		@1LIN05Kanban,
		@1SN102QtyShipped
			
	if	@@FETCH_STATUS != 0 begin
		break
	end



	Insert	#ASNFlatFile (LineData)
					Select  '15' 									
							+ @1LIN01LineItem
							+ @1LIN02CustomerPartBP
							+ @1LIN03CustomerPart
							+ @1LIN04KanbanRC

		Insert	#ASNFlatFile (LineData)
					Select  '16' 									
							+ @1LIN05Kanban
							+ @1SN102QtyShipped
							+ @1SN103QtyShippedUM
	
	
/*
		Insert	#ASNFlatFile (LineData)
		Select '27'
				+		@LIN02_BPIDtype
				+		@LIN02_CustomerPart
				+		@LIN02_VPIDtype

		Insert	#ASNFlatFile (LineData)
		Select '28'
				+		@LIN02_VendorPart
				+		@LIN02_PDIDtype

		Insert	#ASNFlatFile (LineData)
		Select '29'
				+		@LIN02_PartDescription
				+		@LIN02_POIDtype

		Insert	#ASNFlatFile (LineData)
		Select '30'
				+		@LIN02_CustomerPO

		Insert	#ASNFlatFile (LineData)
		Select '34'
				+		space(48)
				+		@LIN02_CHIDtype

		Insert	#ASNFlatFile (LineData)
		Select '35'
				+		@LIN02_CountryOfOrigin

		Insert	#ASNFlatFile (LineData)
		Select '36'
				+		space(48)
				+		@SN102_QuantityShipped
				+		@SN103_QuantityShippedUM

		Insert	#ASNFlatFile (LineData)
		Select '37'
				+		@SN104_AccumQuantityShipped

		Insert	#ASNFlatFile (LineData)
		Select '39'
				+		@REF01_IVIDType

		Insert	#ASNFlatFile (LineData)
		Select '40'
				+		@REF02_InvoiceIDID

		Insert	#ASNFlatFile (LineData)
		Select '39'
				+		@REF01_PKIDType

		Insert	#ASNFlatFile (LineData)
		Select '40'
				+		@REF02_PackingSlipID
*/
/*
		declare PartPack cursor local for
			select
				1,
				count(serial),
				ObjectPackageType				
			From
				@AuditTrailSerial
			where
				part = @InternalPart
				group by
				ObjectPackageType
				union
			 Select
			  2,
				count(Distinct ParentSerial),
				PalletPackageType				
			From
				@AuditTrailSerial
			where
				part = @InternalPart and
				ParentSerial > 0
				group by
				PalletPackageType
				order by 1,2
												
			open
				PartPack

			while
				1 = 1 begin
							
				fetch
					PartPack
				into
					@PackTypeType,
					@1PAC01PackageCount,
					@1PAC01PackageType
					
								
																								
				if	@@FETCH_STATUS != 0 begin
					break
				end
									Insert	#ASNFlatFile (LineData)
										Select  '10' 									
										+ @1PAC01PackageCount
										+ @1PAC01PackageType
							
					end		
					close
						PartPack
					deallocate
						PartPack
						
					

			Insert	#ASNFlatFile (LineData)
										Select  '14' 									
										+ @2LIN030CustomerPart
										+ @1PIAModelYear

			Insert	#ASNFlatFile (LineData)
										Select  '16' 									
										+ @2QTY010QtyTypeShipped
										+ @2QTY010QtyShipped
										+	@2QTY010QtyShippedUM

		Insert			#ASNFlatFile (LineData)
										Select  '16' 									
										+ @2QTY010AccumTypeShipped
										+ @2QTY010AccumShipped
										+	@2QTY010AccumShippedUM

			Insert			#ASNFlatFile (LineData)
										Select  '17' 									
										+ space(3)
										+ @1RFF010CustomerPO
	*/									
end
close
	PartsPerManifest
 
deallocate
	PartsPerManifest

end
close
	Manifest
 
deallocate
	Manifest

/* 
  
    FlatFile Layout for Overlay: TMC_810_D_v3040_TOYOTA CANADA_100608     03-03-14 11

    Fixed Record/Fixed Field (FF)        Max Record Length: 080

    Input filename: DX-FX-FF.080         Output filename: DX-XF-FF.080


    Description                                            Type Start Length Element 

    Header Record '//'                                      //   001   002           

       RESERVED (MANDATORY)('STX12//')                      ID   003   007           

       X12 TRANSACTION ID (MANDATORY X12)                   ID   010   003           

       TRADING PARTNER (MANDATORY)                          AN   013   012           

       DOCUMENT NUMBER (MANDATORY)                          AN   025   030           

       FOR PARTIAL TRANSACTION USE A 'P' (OPTIONAL)         ID   055   001           

       EDIFACT(EXTENDED) TRANSACTION ID (MANDATORY EDIFACT) ID   056   010           

       DOCUMENT CLASS CODE (OPTIONAL)                       ID   066   006           

       OVERLAY CODE (OPTIONAL)                              ID   072   003           

       FILLER('      ')                                     AN   075   006           

       Record Length:                                                  080           

    Record '01'                                             01   001   002           

       INVOICE DATE                                         DT   003   006    1BIG01 

       INVOICE #                                            AN   009   016    1BIG02 

       PO DATE                                              DT   025   006    1BIG03 

       PO #                                                 AN   031   015    1BIG04 

       CURRENCY CODE                                        AN   046   003    1CUR02 

       FILLER('                                ')           AN   049   032           

       Record Length:                                                  080           

    Loop Start (200000 x - End Record '03')                                          

       Record '02'                                          02   001   002           

          TMMC KANBAN #                                     AN   003   004    1IT101 

          QUANTITY INVOICED                                 R    007   012    1IT102 

          UNIT OF MEASURE                                   AN   019   002    1IT103 

          UNIT PRICE                                        R    021   016    1IT104 

          TMMC PART #                                       AN   037   012    1IT107 

          FILLER('                                ')        AN   049   032           

          Record Length:                                               080           

       Record '03' (10 x - End Record '03')                 03   001   002           

          TAX TYPE CODE                                     AN   003   002    1TXI01 

                                          1
    Description                                            Type Start Length Element 

          TAX AMOUNT                                        R    005   017    1TXI02 

          ('                                            ... AN   022   059           

          Record Length:                                               080           

    Record '04'                                             04   001   002           

       TOTAL INVOICE AMOUNT                                 N    003   012    1TDS01 

       ('                                               ... AN   015   066           

       Record Length:                                                  080           

*/

set ANSI_Padding on


--Declare Variables for 810 Flat File

Declare			@1BIG01InvoiceDate char(6),
				@1BIG02InvoiceNumber char(16),
				@1BIG04PONumber char(15),
				@1CUR02CurrencyCode char(3) = 'USD',
				@1IT101KanbanNumber char(4), 
				@1IT102QtyInvoiced char(12), 
				@1IT103QtyInvoicedUM char(2) = 'PC' , 
				@1IT104UnitPrice char(16),
				@1IT102QtyInvoicedNumeric numeric(20,6), 
				@1IT104UnitPriceNumeric numeric(20,6),
				@1IT106PartQualifier char(2) = 'BP',
				@1IT107CustomerPart char(12),
				@1TXI01TaxCode char(2),
				@1TXI02TaxAmount char(17),
				@1TDS01InvoiceAmount char(12),
				@PartNumber varchar(25)


SELECT	[InvoiceSuffix] = ROW_NUMBER() OVER(ORDER BY tmd.ManifestNumber ASC),
		[BIG01InvoiceDate] = CONVERT(VARCHAR(25), s.date_shipped, 12) ,
		--[BIG02InvoiceNumber] = coalesce(nullif(es.supplier_code,''),'7497A') + coalesce(nullif(d.address_6,''), '12345'),
		[BIG02InvoiceNumber] = CONVERT(VARCHAR(25), s.invoice_number), --address 6 needs to be a 5 digit Toyota Plant Code

		 --A valid purchase number for Aztec is 7497A5AC4078D01.  
		 --The first four digits represents your vendor number.   
		 --The plant code is “A”.  
		 --The dock code is “5A”.  
		 --ManifestNumber
		 --This information belongs in the BIG04 segment of your EDI transmission as noted in specifications below.

		[BIG04PONumber] = COALESCE('7497',NULLIF(es.supplier_code,''),'7497') + COALESCE('A',NULLIF(d.address_6,''), 'A') + COALESCE('5A',NULLIF(s.shipping_dock,''), '5A') + tmd.ManifestNumber,
		[TradingPartner] = es.trading_partner_code,
		[KanbanNumber] = COALESCE(p.drawing_number, 'M700'),
		[PartNumber] = sd.part_original,
		[CustomerPart] = sd.customer_part,
		[QtyShipped] = tmd.Quantity,
		[Price] = ROUND(sd.alternate_price,4),
		[TaxCode] = COALESCE((CASE COALESCE(sd.taxable,'N') WHEN 'Y' THEN 'ST' ELSE 'ST' END),'ST'),
		[TaxAmount] = COALESCE((CASE COALESCE(sd.taxable,'N') WHEN 'Y' THEN sd.alternate_price*sd.qty_packed*(d.salestax_rate/100) ELSE 0 END),0),
		--[InvoiceTotal] = ROUND((tmd.Quantity*sd.alternate_price+COALESCE((case coalesce(sd.taxable,'N') when 'Y' then sd.alternate_price*sd.qty_packed*(d.salestax_rate/100) else 0 end),0)),2)
		[InvoiceTotal] = SUBSTRING(CONVERT(VARCHAR(MAX),ROUND(tmd.Quantity*sd.alternate_price ,2)),1,PATINDEX('%.%', CONVERT(VARCHAR(MAX),ROUND(tmd.Quantity*sd.alternate_price ,2)))-1 ) +
		SUBSTRING(CONVERT(VARCHAR(MAX),ROUND(tmd.Quantity*sd.alternate_price ,2)),PATINDEX('%.%', CONVERT(VARCHAR(MAX),ROUND(tmd.Quantity*sd.alternate_price ,2)))+1, 2)

	INTO #ToyotaCanadaManifests

	FROM
		Shipper s
		JOIN
		shipper_detail sd ON sd.shipper =  s.id
	JOIN
		part p ON p.part = part_original
	JOIN
		dbo.edi_setups es ON s.destination = es.destination
	JOIN
		dbo.destination d ON es.destination = d.destination
	JOIN
		dbo.customer c ON c.customer = s.customer
	JOIN
		EDIToyota.Pickups pu ON pu.ShipperID = s.id
	JOIN
		EDIToyota.ManifestDetails tmd ON tmd.PickupID = pu.RowID
	WHERE
		s.id = @shipper
	AND
		tmd.Quantity > 0

	ORDER BY 2




DECLARE
	InvoiceLine CURSOR LOCAL FOR
SELECT
	 BIG01InvoiceDate ,
	 BIG02InvoiceNumber+'-'+ CONVERT(VARCHAR(25),InvoiceSuffix) ,
	 BIG04PONumber ,
	 TradingPartner ,
	 KanbanNumber ,
	 PartNumber ,
	 CustomerPart ,
	 QtyShipped ,
	 Price ,
	 TaxCode ,
	 TaxAmount,
	 InvoiceTotal      
FROM
	#ToyotaCanadaManifests InvoiceDetail


--SELECT * FROM #ToyotaCanadaManifests


OPEN
	InvoiceLine

WHILE
	1 = 1 BEGIN
	
	FETCH
		InvoiceLine
	INTO
		@1BIG01InvoiceDate
	,	@1BIG02InvoiceNumber
	,	@1BIG04PONumber
	,	@TradingPartner
	,	@1IT101KanbanNumber
	,	@PartNumber
	,	@1IT107CustomerPart
	,	@1IT102QtyInvoiced
	,	@1IT104UnitPrice
	,	@1TXI01TaxCode
	,	@1TXI02TaxAmount
	,	@1TDS01InvoiceAmount
			
			
	IF	@@FETCH_STATUS != 0 BEGIN
		BREAK
	END
    
INSERT	#ASNFlatFile (LineData)
	SELECT	('//STX12//810'
						+  @TradingPartner 
						+  @ShipperIDHeader
						+  'P' )
PRINT @1BIG01InvoiceDate

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'01'
				+		@1BIG01InvoiceDate
				+		@1BIG02InvoiceNumber
				+		SPACE(6)
				+		@1BIG04PONumber
				+		@1CUR02CurrencyCode
						)



INSERT	#ASNFlatFile (LineData)
					SELECT  '02' 									
							+ @1IT101KanbanNumber
							+ @1IT102QtyInvoiced
							+ @1IT103QtyInvoicedUM
							+ @1IT104UnitPrice
							+ @1IT107CustomerPart

--Insert	#ASNFlatFile (LineData)
--					Select  '03' 									
--							+ @1TXI01TaxCode
--							+ @1TXI02TaxAmount

INSERT	#ASNFlatFile (LineData)
					SELECT  '04' 									
							+ @1TDS01InvoiceAmount
								
END
CLOSE
	InvoiceLine	
 
DEALLOCATE
	InvoiceLine	

	

SELECT 
LineData +CONVERT(CHAR(1), (lineID % 2 ))
	
FROM 
	#ASNFlatFile
ORDER BY 
	LineID


	      
SET ANSI_PADDING OFF	
END
         


























GO
