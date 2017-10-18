SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE	procedure [dbo].[MazdaASN]  (@shipper int)
as
begin
--[dbo].[MazdaASN] 67110


set ANSI_Padding on
--ASN Header

declare
	@TradingPartner	char(12),
	@ShipperID char(30),
	@ShipperID2 char(6),
	@PartialComplete char(1),
	@PurposeCode char(2),
	@ASNDate char(6),
	@ASNTime char(4),
	@ShippedDate char(6),
	@ShippedTime char(4),
	@EstimatedArrivalDate char(6),
	@EstimatedArrivalTime char(4),
	@GrossWeightLbs char(12),
	@GrossWeightQualifier char(3),
	@NetWeightLbs char(10),
	@WeightUM char(2),
	@PackagingCode char(5),
	@PackCount char(8),
	@SCAC char(4),
	@TransMode char(2),
	@PPCode char(7),
	@EquipDesc char(2),
	@EquipInit char(4),
	@TrailerNumber char(7),
	@REFBMQual char(2),
	@REFPKQual char(2),
	@REFCNQual char(2),
	@REFBMValue char(30),
	@REFPKValue char(30),
	@REFCNValue char(30),
	@FOB char(2),
	@ProNumber char(16),
	@SealNumber char(8),
	@SupplierName char(78),
	@SupplierCode char(5),
	@ShipToName char(78),
	@ShipToID char(5),
	@TimeZone char(2),
	@AETCResponsibility char(1),
	@AETC char(8),
	@PoolCode char(7),
	@EquipInitial char(4)
	
	select
		@TradingPartner	= es.trading_partner_code ,
		@ShipperID =  s.id,
		@ShipperID2 =  right((replicate('0', 6) +convert(varchar(20), s.id)),6),
		@PartialComplete = '' ,
		@PurposeCode = '00',
		@ASNDate = convert(char, getdate(), 12) ,
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ShippedDate = convert(char, s.date_shipped, 12)  ,
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@EstimatedArrivalDate = convert(char, dateadd(dd,1,s.date_shipped), 12)  ,
		@EstimatedArrivalTime =  left(replace(convert(char, dateadd(dd,1,date_shipped), 108), ':', ''),4),
		--@TimeZone = [dbo].[udfGetDSTIndication](date_shipped),
		@GrossWeightLbs = convert(char,convert(int,s.gross_weight)),
		@GrossWeightQualifier = 'G',
		@NetWeightLbs = convert(char,convert(int,s.net_weight)),
		@WeightUM = 'LB',
		@PackagingCode = 'CTN25' ,
		@PackCount = s.staged_objs,
		@SCAC = s.ship_via,
		@TransMode = s.trans_mode ,
		@TrailerNumber = s.truck_number,
		@REFBMQual = 'BM' ,
		@REFPKQual = 'PK',
		@REFCNQual = 'CN',
		@REFBMValue = coalesce(bill_of_lading_number, id),
		@REFPKValue = id,
		@REFCNValue = pro_number,
		@FOB = case when freight_type =  'Collect' then 'CC' when freight_type in  ('Consignee Billing', 'Third Party Billing') then 'TP' when freight_type  in ('Prepaid-Billed', 'PREPAY AND ADD') then 'PA' when freight_type = 'Prepaid' then 'PP' else 'CC' end ,
		@SupplierName = 'Aztec Manufacturing' ,
		@SupplierCode =  es.supplier_code ,
		@ShipToName =  d.name,
		@ShipToID = COALESCE(nullif(es.parent_destination,''),es.destination),
		@AETCResponsibility = case when upper(left(aetc_number,2)) = 'CE' then 'A' when upper(left(aetc_number,2)) = 'SR' then 'S' when upper(left(aetc_number,2)) = 'CR' then 'Z' else '' end,
		@AETC =coalesce(s.aetc_number,''),
		@PoolCode = case when s.trans_mode in ('A', 'AC','AE','E','U') then '' else coalesce(pool_code,'') end,
		@EquipDesc = coalesce( es.equipment_description, 'TL' ),
		@EquipInitial = coalesce( bol.equipment_initial, s.ship_via ),
		@SealNumber = coalesce(s.seal_number,''),
		@Pronumber = coalesce(s.pro_number,'')
		
	from
		Shipper s
	join
		dbo.edi_setups es on s.destination = es.destination
	join
		dbo.destination d on es.destination = d.destination
	left join
		dbo.bill_of_lading bol on s.bill_of_lading_number = bol_number
	where
		s.id = @shipper
	

Create	table	#ASNFlatFileHeader (
				LineId	int identity (1,1),
				LineData char(80))
print @ShipperID2
print @ASNDate
print @ASNTime
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('//STX12//856'+  @TradingPartner + @ShipperID+ @PartialComplete )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('01'+  @PurposeCode + @ShipperID2 + @ASNDate + @ASNTime + @EstimatedArrivalDate + @EstimatedArrivalTime +@ShippedDate + @ShippedTime )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('02' + @GrossWeightQualifier + @GrossWeightLbs + @WeightUM )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('03' +  @PackagingCode +  @PackCount  )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('04' + @SCAC  + @TransMode )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('05' +  @EquipDesc + @EquipInitial + @TrailerNumber )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' +  @REFPKQual + @ShipperID )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' +  @REFBMQual +  @REFBMValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @SupplierCode + @ShipToID +  @SupplierCode )


 --ASN Detail

declare	@ShipperDetail table (
	Part varchar(25),
	ShipperID int,
	CustomerPart varchar(35),
	DeliveryOrderNo varchar(50),
	OrderNo int,
	SDQty int,
	SDAccum int,
	DORAccum int
	 primary key (CustomerPart, DeliveryOrderNo)
	)
insert @ShipperDetail
			( Part ,
			ShipperID,
			CustomerPart ,
			DeliveryOrderNo ,
			SDQty, 
			SDAccum,
			OrderNo         
        )	
select
	coalesce(sd.Part_original, sd.part),
	s.id,
	sd.Customer_Part,
	coalesce(nullif(sd.release_no,''),sd.customer_po,''),
	--MazdaDO.DeliveryOrderNumber (This will be re-written if it is found that the customer needs to split DOR numbers),
	--Sum(MazdaDO.Quantity)(This will be re-written if it is found that the customer needs to split DOR numbers,
	sd.qty_packed,
	sd.accum_shipped,
	order_no
	
from shipper_detail sd
/*left join
		EDI.MazdaDeliveryOrderNumbers MazdaDO on MazdaDO.OrderNo = sd.order_no and sd.shipper = @shipper and MazdaDO.ShipperID = @shipper*/
join
	shipper s on sd.shipper = s.id and s.id = @shipper

	
	/*update sd1
	set		sd1.DORAccum = (select (max(SDAccum) - sum(SDQty)) + sd1.SDQty from @ShipperDetail sd2 where sd2.ShipperID = sd1.ShipperID and sd2.DeliveryOrderNo <= sd1.DeliveryOrderNo and sd1.orderNo = sd2.orderNo)
	from		@ShipperDetail  sd1
	*/
declare	@ShipperSerialAccum table (
	Id int identity(1,1),
	Part varchar(25),
	ShipperID int,
	SerialNumber int, 
	SerialQty int,
	SerialQtyAccum int,
	primary key (SerialNumber)
	)
insert @ShipperSerialAccum
			(	Part ,
				ShipperID,
				SerialNumber,
				SerialQty,
				SerialQtyAccum
        )	
select
	sd.Part_original,
	s.id,
	at.serial,
	at.quantity,
	0
	
from
	audit_trail at
join
	dbo.shipper_detail sd on at.shipper = convert(varchar(15), sd.shipper)and sd.part_original = at.part and sd.shipper = @shipper
join
	shipper s on sd.shipper = s.id
order by
	sd.part_original,
	at.quantity asc

update saccum
set		SerialQtyAccum = ( select sum(SerialQty) from @ShipperSerialAccum sAccum2 where sAccum2.id<= saccum.id and sAccum2.part = sAccum.part)
from		@ShipperSerialAccum saccum


	
--Delcare Variables for ASN Details		
declare	
	@CustomerPartBP char(2),
	@CustomerPartRC char(2),
	@CustomerPart char(30) ,
	@CustomerECL char(3),
	@ContainerType char(30),
	@Part varchar(25),
	@QtyPacked char(9),
	@UM char(2),
	@AccumShipped char(11),
	@CustomerPO char(13),
	@DeliveryOrderNo char(30),
	@BOL char(16),
	@PackSlip char(16),
	@Destination char(17), 
	@ASNOverlayGroup varchar(10),
	@DockCode	char(8),
	@ACIndicator char(1),
	@ACHandling char(2),
	@ACClause char(4),
	@ACCharge char(11),
	@ContainerCount char(12),
	@PackageType char(30),
	@REFDetailPKQualifier char(2),
	@REFDetailPK char(30),
	@REFDetailBMQualifier char(2),
	@REFDetailDOQualifier char(2),
	@REFDetailBM char(30),
	@SerialNumber char(30),
	@SerialQty char(9)
	
	select @UM ='PC'
	select	@REFDetailPKQualifier = @REFPKQual
	select	@REFDetailPK = @REFPKValue
	select	@REFDetailBMQualifier = @REFBMQual
	select	@REFDetailDOQualifier = 'DO'
	select	@REFDetailBM = @REFBMValue
	
Create	table	#FlatFileLines (
				LineId	int identity(200,1),
				LineData char(80)
				 )

declare
	PartPOLine cursor local for
select
			'BP',
			'RC',
			Part ,
			ShipperID ,
	        CustomerPart ,
	        DeliveryOrderNo ,
	        SDQty ,
	        SDAccum
	        
From
	@ShipperDetail SD
	order by
		ShipperID,
		CustomerPart,
		DeliveryOrderNo

open
	PartPOLine
while
	1 = 1 begin
	
	fetch
		PartPOLine
	into
		@CustomerPartBP ,
		@CustomerPartRC,
		@Part ,
		@PackSlip,
		@CustomerPart ,
		@DeliveryOrderNo,
		@QtyPacked,
		@AccumShipped
			
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('08'+  @CustomerPart +  @QtyPacked + @UM + @AccumShipped   )
		
	--	INSERT	#FlatFileLines (LineData)
	--	SELECT	('09'+ @REFDetailPKQualifier +  @REFDetailPK   )
		
	--	INSERT	#FlatFileLines (LineData)
	--	SELECT	('09'+ @REFDetailBMQualifier +  @REFDetailBM   )
		
	INSERT	#FlatFileLines (LineData)
	SELECT	('09'+ @REFDetailDOQualifier +  @DeliveryOrderNo  )
		
		
		--Create Serial Loop
		
		declare
	PartSerials cursor local for
select
			SerialNumber,
			'CTN90',
			SerialQty
	        
from @ShipperSerialAccum
where	ShipperID = @shipper and
			Part =  @Part
	

open
	PartSerials
while
	1 = 1 begin
	
	fetch
		PartSerials
	into
		@SerialNumber ,
		@ContainerType,
		@SerialQty
					
	if	@@FETCH_STATUS != 0 begin
		break
	end
		
			INSERT	#FlatFileLines (LineData)
			SELECT	('10'+ '1     ' +  @SerialQty + 'CTN90'  + @SerialNumber )
		
	end	
	
	close
	PartSerials	
 
deallocate
	PartSerials
		--End Serial Loop
	
		
			
end
close
	PartPOLine	
 
deallocate
	PartPOLine
	


create	table
	#ASNResultSet (FFdata  char(80), LineID int)

insert #ASNResultSet
        ( FFdata, LineID )

select
	Convert(char(80), LineData), LineID
from	
	#ASNFlatFileHeader
insert
	#ASNResultSet (FFdata, LineID)
select
	Convert(char(77), LineData) + Convert(char(3), LineID),LineID
from	
	#FlatFileLines
	
select	FFdata
from		#ASNResultSet
order by LineID ASC


	      
set ANSI_Padding OFF	
End
         




GO
