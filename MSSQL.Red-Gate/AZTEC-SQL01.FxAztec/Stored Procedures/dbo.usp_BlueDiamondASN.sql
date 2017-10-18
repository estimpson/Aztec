SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE	procedure [dbo].[usp_BlueDiamondASN]  (@shipper int)
as
begin
--[dbo].[usp_BlueDiamondASN] 65854

--TLW Form NV4_856_D_v3050_NAVISTAR TRUCK SI_091228

set ANSI_Padding on
--ASN Header

declare
	@TradingPartner	char(12),
	@ShipperID char(30),
	@ShipperID2 char(16),
	@PartialComplete char(1),
	@PurposeCode char(2),
	@ASNDate char(6),
	@ASNTime char(8),
	@ShippedDate char(6),
	@ShippedTime char(8),
	@TimeZone char(2),
	@Century char(2),
	@CustomerPO char(22),
	@CustomerPODate char(6),
	@GrossWeightQualifier char(3),
	@GrossWeightLbs char(22),
	@NetWeightQualifier char(3),
	@NetWeightLbs char(22),
	@WeightUM char(2),
	@PackagingCode char(5),
	@PackCount char(8),
	@RoutingSequenceCode char(2),
	@SCAC char(20),
	@TransMode char(2),
	@RoutingSequence char(35),
	@LocationQualifier char(2),
	@PPCode char(30),
	@EquipDesc char(2),
	@EquipInit char(4),
	@TrailerNumber char(10),
	@REFBMQual char(2),
	@REFPKQual char(2),
	@REFCNQual char(2),
	@REFBMValue char(30),
	@REFPKValue char(30),
	@REFCNValue char(30),
	@FOB char(2),
	@ProNumber char(16),
	@SealNumber char(8),
	@SupplierName char(35),
	@SupplierCode char(20),
	@ShipToName char(35),
	@ShipToQual char(2),
	@SupplierQual char(2),
	@ShipToID char(20),	
	@AETCResponsibility char(1),
	@AETC char(8),
	@DockCode char(30),
	@PoolCode char(30),
	@EquipInitial char(4)
	
	select
		@TradingPartner	= coalesce(nullif(es.trading_partner_code,''),'BLUEDIAMOND') ,
		@ShipperID =  s.id,
		@ShipperID2 =  s.id,
		@PartialComplete = '' ,
		@PurposeCode = '00',
		@ASNDate = convert(char, getdate(), 12) ,
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ShippedDate = convert(char, s.date_shipped, 12)  ,
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@TimeZone = [dbo].[udfGetDSTIndication](date_shipped),
		@Century = left(datepart(YYYY, date_shipped),2),
		@CustomerPO = Coalesce(( Select max(customer_po) from shipper_detail where shipper = @Shipper and order_no = ( Select max(order_no) from shipper_detail where shipper = @shipper)),'PO'),
		@CustomerPODate = convert(char, coalesce(( Select max(order_date) from order_header where order_no = ( Select max(order_no) from shipper_detail where shipper = @shipper)),getdate()),12),
		@GrossWeightLbs = convert(char,convert(int,s.gross_weight)),
		@NetWeightLbs = convert(char,convert(int,s.net_weight)),
		@PackagingCode = 'CNT71' ,
		@PackCount = s.staged_objs,
		@RoutingSequenceCode = 'B',
		@SCAC = s.ship_via,
		@TransMode = coalesce(s.trans_mode,'M') ,
		@RoutingSequence = 'A',
		@TrailerNumber = coalesce(nullif(s.truck_number,''), s.id),
		@REFBMQual = 'BM' ,
		@REFPKQual = 'PK',
		@REFCNQual = Case when coalesce(pro_number,'') is not Null then 'CN' else '' end,
		@REFBMValue = coalesce(bill_of_lading_number, id),
		@REFPKValue = id,
		@REFCNValue = pro_number,
		@FOB = case when freight_type =  'Collect' then 'CC' when freight_type in  ('Consignee Billing', 'Third Party Billing') then 'TP' when freight_type  in ('Prepaid-Billed', 'PREPAY AND ADD') then 'PA' when freight_type = 'Prepaid' then 'PP' else 'CC' end ,
		@SupplierName = 'Aztec Manufacturing' ,
		@SupplierCode = coalesce(es.supplier_code, '115230526') ,
		@ShipToQual = 'ST',
		@SupplierQual ='SU',
		@ShipToName =  d.name,
		@ShipToID = COALESCE(nullif(es.parent_destination,''),'011', es.destination),
		@AETCResponsibility = case when upper(left(aetc_number,2)) = 'CE' then 'A' when upper(left(aetc_number,2)) = 'SR' then 'S' when upper(left(aetc_number,2)) = 'CR' then 'Z' else '' end,
		@AETC =coalesce(s.aetc_number,''),
		@LocationQualifier =case when s.trans_mode in ('A', 'AC','AE') then 'OR'  when isNull(nullif(pool_code,''),'-1') = '-1' then '' else 'PP' end,
		@PoolCode = case when s.trans_mode in ('A', 'AC','AE') then Left(s.pro_number,3)  when s.trans_mode in ('E', 'U') then '' else coalesce(pool_code,'') end,
		@EquipDesc = coalesce( es.equipment_description, 'TL' ),
		@EquipInitial = coalesce( bol.equipment_initial, s.ship_via ),
		@SealNumber = coalesce(s.seal_number,''),
		@Pronumber = coalesce(s.pro_number,''),
		@DockCode = coalesce(nullif(s.shipping_dock,''), 'DK'),
		@GrossWeightQualifier = 'G',
		@NetWeightQualifier = 'N',
		@WeightUM = 'LB'
		
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
				LineData char(78))

INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('//STX12//856'+  @TradingPartner + @ShipperID + @PartialComplete )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('01'+  @PurposeCode + @ShipperID + @ASNDate + @ASNTime + @ShippedDate + @ShippedTime + @TimeZone)
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('02'+ @CustomerPO + @CustomerPODate + @GrossWeightLbs + @NetWeightLbs  )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('03' + @PackagingCode + @PackCount )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('04' + @RoutingSequenceCode + @SCAC  + @TransMode + @RoutingSequence + space(35) + (case when nullif(@PoolCode,'') is null then space(2) else @LocationQualifier end )  )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('05' + @PoolCode )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' + @TrailerNumber  )		
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @REFBMQual + @REFBMValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @REFPKQual + @REFPKValue )
--INSERT	#ASNFlatFileHeader (LineData)
--	SELECT	('07' + @REFCNQual + @REFCNValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('08' + @FOB )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('09' + @SupplierQual + '92'+  @SupplierCode + @SupplierName )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('09' + @ShipToQual + '92'+ @ShipToID + @ShipToName )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('10' + @DockCode )



 --ASN Detail

declare	@ShipperDetail table (
	Part varchar(25),
	PackingSlip varchar(25),
	ShipperID int,
	CustomerPart varchar(35),
	CustomerPO varchar(35),
	SDQty int,
	SDAccum int,
	EngLevel varchar(25),
	primary key (Part, PackingSlip)
	)

insert @ShipperDetail
			( Part ,
			PackingSlip ,
			ShipperID,
			CustomerPart ,
			CustomerPO ,
			SDQty ,
			SDAccum ,
			EngLevel 
          
        )	
select
	sd.part_original,
	sd.shipper,
	sd.shipper,
	sd.Customer_Part,
	sd.Customer_PO,
	sd.alternative_qty,	
	sd.Accum_Shipped,
	coalesce(oh.engineering_level,'A')
	
from
	shipper s
join
	dbo.shipper_detail sd on s.id  = sd.shipper and sd.shipper =  @shipper
join
	order_header oh on sd.order_no = oh.order_no

	
	
	
declare	@ShipperSerials table (
	Part varchar(25),
	PackageType varchar(25),
	PackCount int,
	PackQty int,
	Serial int
	primary key (Part, Serial)
	)

insert @ShipperSerials          
        	
select
	at.part,
	'PLT71',
	count(distinct parent_serial),
	sum(quantity),
	at.parent_serial
	
from
	audit_trail at
where
	at.type ='S'  and at.shipper =  convert(varchar(10), @shipper)
and 
	at.part != 'PALLET' 
and
	nullif(at.parent_serial,0) is not null
and not exists 
	(select 1 from audit_trail at2 where at2.type = 'S'  and at2.shipper = convert(varchar(10), @shipper) and at2.parent_serial = at.parent_serial and at2.part!=at.part)
group by 
	at.part,
	at.parent_serial
	
union        
        	
select
	at.part,
	'CTN90',
	count(1),
	max(quantity),
	at.serial 
	
from
	audit_trail at
where
	at.type ='S'  and at.shipper =  convert(varchar(10), @shipper)
and 
	at.part != 'PALLET' 
and
	nullif(at.parent_serial,0) is null
group by
	at.part,
	at.serial
	
order by 1 asc, 2 desc, 3 asc, 4 asc

--Select		*	from		@shipperDetail order by packingslip
--Select		*	from		@shipperserials

--Delcare Variables for ASN Details		
declare	
	@CustomerPartBP char(2),
	@CustomerPartEC char(2),
	@CustomerPart char(40) ,
	@CustomerECL char(40),
	@Part varchar(25),
	@QtyPacked char(12),
	@UM char(2),
	@AccumShipped char(11),
	@CustomerPODetail char(22),
	@ContainerCount char(6),
	@PackageType char(5),
	@PackQty char(12),
	@SerialNumber char(30)
	
select @CustomerPartEC = 'EC'
select @CustomerPartBP = 'BP'
	
Create	table	#FlatFileLines (
				LineId	int identity(200,1),
				LineData char(78)
				 )

declare
	PartPOLine cursor local for
select
			Part ,
	        CustomerPart ,
	        coalesce(CustomerPO,'PO') ,
	        SDQty ,
	        'EA',
	        SDAccum ,
	        coalesce(nullif(EngLevel,''),'ECN')
From
	@ShipperDetail SD
	order by
		CustomerPart

open
	PartPOLine
while
	1 = 1 begin
	
	fetch
		PartPOLine
	into
		@Part ,
		@CustomerPart ,
		@CustomerPODetail,
		@QtyPacked,
		@UM,
		@AccumShipped,
		@CustomerECL 
			
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	--print @ASNOverlayGroup
	
	INSERT	#FlatFileLines (LineData)
		SELECT	('11'+ @CustomerPartBP +  @CustomerPart + @CustomerPartEC  )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('12' +  @CustomerECL )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('16' + space(40) + @QtyPacked + @UM + @CustomerPODetail   )

		INSERT	#FlatFileLines (LineData)
		SELECT	('17' +  @CustomerPODate )
		
		/*		
				declare PackType cursor local for
				select	Part ,
							PackageType ,
							sum(PackCount) ,
							PackQty
				From
					@ShipperSerials
				where					
					part = @Part 
				group by
					part,
					PackageType,
					PackQty
							
					open	PackType

					while	1 = 1 
					begin
					fetch	PackType	into
					@Part,
					@PackageType,
					@ContainerCount,
					@PackQty					
					
					if	@@FETCH_STATUS != 0 begin
					break
					end
									
					INSERT	#FlatFileLines (LineData)
					SELECT	('14'+ @ContainerCount +   @PackQty +  @PackageType )
					
					
					
									declare PackSerial cursor local for
									select	
										Serial
									From
										@ShipperSerials
									where					
										part = @Part and
										PackageType = @PackageType and
										PackQty = @PackQty
									
									open	PackSerial
									while	1 = 1 
									begin
									fetch	PackSerial	into
									@SerialNumber
					
									if	@@FETCH_STATUS != 0 begin
									break
									end
									
									INSERT	#FlatFileLines (LineData)
									SELECT	('15'+  @SerialNumber   )
					
									end
									close PackSerial
									deallocate PackSerial
										
						
					end
					close PackType
					deallocate PackType
				
		
	*/					
end
close	PartPOLine 
deallocate	PartPOLine
	


create	table
	#ASNResultSet (FFdata  char(77), LineID int identity(1,1))

insert #ASNResultSet
        ( FFdata )

select
	Convert(char(77), LineData)
from	
	#ASNFlatFileHeader
union 
select
	Convert(char(77), LineData)
from	
	#FlatFileLines
	
select	FFdata + convert(char(3), LineID)
from		#ASNResultSet
order by LineID asc

      
set ANSI_Padding OFF	
End
         



GO
