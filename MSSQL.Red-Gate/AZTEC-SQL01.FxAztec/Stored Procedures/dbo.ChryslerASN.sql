SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create	procedure [dbo].[ChryslerASN]  (@shipper int)
as
begin
--[dbo].[ChryslerASN] 65163
--select * from chryslerEDI.fn_ShipperInventory(1046748)

set ANSI_Padding on
--ASN Header

declare
	@TradingPartner	char(12),
	@ShipperID char(30),
	@ShipperID2 char(16),
	@PartialComplete char(1),
	@PurposeCode char(2),
	@ASNDate char(6),
	@ASNTime char(4),
	@ShippedDate char(6),
	@ShippedTime char(4),
	@GrossWeightLbs char(10),
	@NetWeightLbs char(10),
	@PackagingCode char(5),
	@PackCount char(4),
	@SCAC char(4),
	@TransMode char(2),
	@PPCode char(7),
	@EquipDesc char(2),
	@EquipInit char(4),
	@TrailerNumber char(10),
	@REFBMQual char(2),
	@REFPKQual char(2),
	@REFCNQual char(2),
	@REFBMValue char(16),
	@REFPKValue char(30),
	@REFCNValue char(30),
	@FOB char(2),
	@ProNumber char(16),
	@SealNumber char(8),
	@SupplierName char(78),
	@SupplierCode char(17),
	@ShipToName char(78),
	@ShipToID char(17),
	@TimeZone char(2),
	@AETCResponsibility char(1),
	@AETC char(8),
	@PoolCode char(7),
	@EquipInitial char(4)
	
	select
		@TradingPartner	= es.trading_partner_code ,
		@ShipperID =  s.id,
		@ShipperID2 =  s.id,
		@PartialComplete = '' ,
		@PurposeCode = '00',
		@ASNDate = convert(char, getdate(), 12) ,
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ShippedDate = convert(char, s.date_shipped, 12)  ,
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@TimeZone = [dbo].[udfGetDSTIndication](date_shipped),
		@GrossWeightLbs = convert(char,convert(int,s.gross_weight)),
		@NetWeightLbs = convert(char,convert(int,s.net_weight)),
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
		@SupplierName = 'TSM Corp' ,
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

INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('//STX12//856'+  @TradingPartner + @ShipperID+ @PartialComplete )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('01'+  @PurposeCode + @ShipperID2 + @ASNDate + @ASNTime + @ShippedDate + @ShippedTime+@TimeZone+@GrossWeightLbs+@NetWeightLbs )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('02' + @PackagingCode + @PackCount )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('03' + @SCAC  + @TransMode + @PoolCode + space(35)+ @EquipDesc + @EquipInitial + @TrailerNumber)
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('04' + @REFBMValue + @ProNumber  + @REFBMValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' + @SealNumber )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @SupplierCode + @SupplierCode + @ShipToID + @ShipToID + space(8) + @AETCResponsibility)
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('08' + @AETC )

 --ASN Detail

declare	@ShipperDetail table (
	Part varchar(25),
	PackingSlip varchar(25),
	ShipperID int,
	CustomerPart varchar(35),
	CustomerPO varchar(35),
	ContainerTypeIndicator varchar(35),
	ContainerTypeCount int,
	PalletPackageType varchar(35),
	PalletPackageTypeCount int,
	SDQty int,
	SDAccum int,
	EngLevel varchar(25),
	OHDockCode varchar(25),
	BOL varchar(10),
	ASNOverlayGroup varchar(10),
	Destination varchar(15),  
	Clause092C varchar(2),
	Clause092H varchar(2),
	Clause092 varchar(3),
	Clause092Charge numeric(10,2) primary key (Part, PackingSlip)
	)
insert @ShipperDetail
			( Part ,
			PackingSlip ,
			ShipperID,
			CustomerPart ,
			CustomerPO ,
			ContainerTypeIndicator ,
			ContainerTypeCount,
			PalletPackageType,
			PalletPackageTypeCount,
			SDQty ,
			SDAccum ,
			EngLevel ,
			OHDockCode ,
			BOL ,
			ASNOverlayGroup,
			Destination,
			Clause092C ,
			Clause092H ,
			Clause092 ,
			Clause092Charge
          
        )	
select
	fn_SI.Part,
	fn_SI.PackingSlip,
	shipper,
	bo.CustomerPart,
	bo.CustomerPO,
	fn_SI.PackageType,
	fn_SI.Boxes,
	fn_SI.PalletPackageType,
	fn_SI.Pallets,
	fn_SI.QtyPacked,
	bo.AccumShipped,
	coalesce(bo.ECL,''),
	coalesce(bo.DockCode,''),
	fn_SI.ShipperID,
	es.asn_overlay_group,
	bo.EDIShipToCode,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then 'C' else '' end,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then '06' else '' end,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then '092' else '' end,
	((case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then bo.Clause092UnitCost else 0.00 end)*fn_SI.QtyPacked)
	
from
	chryslerEDI.fn_ShipperInventory(@shipper) fn_SI
join
	dbo.shipper_detail sd on fn_SI.Part = sd.part_original and sd.shipper = @shipper
join
	chryslerEDI.BlanketOrders bo on sd.order_no = bo.BlanketOrderNo
join
	shipper s on sd.shipper = s.id
join
	edi_setups es on s.destination = es.destination

--Select		*	from		@shipperDetail order by packingslip
	
--Delcare Variables for ASN Details		
declare	
	@CustomerPartBP char(2),
	@CustomerPartRC char(2),
	@CustomerPart char(30) ,
	@CustomerECL char(3),
	@ContainerType char(30),
	@Part varchar(25),
	@QtyPacked char(12),
	@UM char(2),
	@AccumShipped char(11),
	@CustomerPO char(13),
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
	@PackageType char(30)
	
Create	table	#FlatFileLines (
				LineId	int identity(200,1),
				LineData char(80)
				 )

declare
	PartPOLine cursor local for
select
			'BP',
			'RC',
			ASNOverlayGroup,
			Part ,
	        PackingSlip ,
	        CustomerPart ,
	        CustomerPO ,
	        ContainerTypeIndicator ,
	        SDQty ,
	        'EA',
	        SDAccum ,
	        EngLevel ,
	        OHDockCode ,
	        BOL ,
	        Destination ,
	        Clause092C ,
	        Clause092H ,
	        Clause092 ,
	        case when isnumeric(Clause092Charge) = 1 then convert(varchar,Clause092Charge) else '' end
From
	@ShipperDetail SD
	order by
		PackingSlip,
		CustomerPart

open
	PartPOLine
while
	1 = 1 begin
	
	fetch
		PartPOLine
	into
		@CustomerPartBP ,
		@CustomerPartRC,
		@ASNOverlayGroup,
		@Part ,
		@PackSlip,
		@CustomerPart ,
		@CustomerPO,
		@ContainerType,
		@QtyPacked,
		@UM,
		@AccumShipped,
		@CustomerECL ,
		@DockCode,		
		@BOL,
		@Destination, 		
		@ACIndicator,
		@ACHandling ,
		@ACClause,
		@ACCharge 
			
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	print @ASNOverlayGroup
	
	INSERT	#FlatFileLines (LineData)
		SELECT	('09'+  @CustomerPartBP + @CustomerPart + @CustomerECL + @ContainerType + @QtyPacked  )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('10'+  @UM + @AccumShipped + @CustomerPO + @BOL + @PackSlip   )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('12'+  @Destination + @Destination + @DockCode    )
		
		if @ASNOverlayGroup = 'CHT'
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('13'+ space(78)     )
		
		Else
		INSERT	#FlatFileLines (LineData)
		SELECT	('13'+  @ACIndicator + @ACHandling + @ACClause + case when @ACCharge = '0.00' then space(11) else @ACCharge end     )
	
			
				declare Pack cursor local for
				select
				ContainerTypeIndicator,
				sum(ContainerTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip = rtrim(@PackSlip)
				group by
					ContainerTypeIndicator
				union all
				Select
				PalletPackageType,
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType not like '%~%' and 
					PalletPackageType not like '%PALLET%'
				group by
					PalletPackageType
				union all
				Select
				substring(PalletPackageType,1, patindex('%[~]%', PalletPackageType)-1),
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType  like '%~%'
				group by
					substring(PalletPackageType,1, patindex('%[~]%', PalletPackageType)-1)
				union all
				Select
				substring(PalletPackageType, patindex('%[~]%', PalletPackageType)+1, 25),
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType  like '%~%'	
				group by
					substring(PalletPackageType, patindex('%[~]%', PalletPackageType)+1, 25)			
									
					open	Pack

					while	1 = 1 
					begin
					fetch	pack	into
					@PackageType,
					@ContainerCount					
					
					if	@@FETCH_STATUS != 0 begin
					break
					end
					
				
					if rtrim(@CustomerPart) = (select max(customerpart) from @ShipperDetail where PackingSlip = rtrim(@PackSlip))
					Begin
					INSERT	#FlatFileLines (LineData)
					SELECT	('09'+  @CustomerPartRC + @PackageType + space(3) + space(30) + @ContainerCount  )
					
					INSERT	#FlatFileLines (LineData)
					SELECT	('10'+  @UM + @ContainerCount   )
					end
	
					end
				close pack
				deallocate pack
				
		
						
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
