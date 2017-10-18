use FxAztec
go

begin transaction
go

declare
	@shipper int = 76096

declare
	@TradingPartner	char(12),
	@ShipperIDHeader char(30) = @Shipper

select
	@TradingPartner	= coalesce(nullif(es.trading_partner_code,''), 'TMMI')

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

--Declare Variables for 810 Flat File

Declare @1BIG01InvoiceDate char(8),
		@1BIG02InvoiceNumber char(5),
		@1IT01KanbanCard char(4) = 'M390',
		@1IT102QtyInvoiced char(12), 
		@1IT104UnitPrice char(16),
		@1IT102QtyInvoicedNumeric numeric(20,6), 
		@1IT104UnitPriceNumeric numeric(20,6),
		@1IT105BasisOfUnitPrice char(2) = 'QT',
		@1IT106PartQualifier char(2) = 'PN',
		@1IT107CustomerPart char(12),
		@1IT108PackageDrawingQual char(2) = 'PK',
		@1IT109PackageDrawing char(12) = '1',
		@1IT110 char(2) = 'ZZ', 
		@1IT111 char(12) = 'N1',
		@1REF01MKQualifier Char(2) = 'MK',
		@1REF02Manifest Char(30),
		@1DTM02PickUpDate char(8),
		@1TDS01InvoiceAmount char(12),
		@PartNumber varchar(25)

select
		
		@1BIG01InvoiceDate= CONVERT(VARCHAR(25), s.date_shipped, 112)+LEFT(CONVERT(VARCHAR(25), s.date_shipped, 108),2) +SUBSTRING(CONVERT(VARCHAR(25), s.date_shipped, 108),4,2),
		
		@1BIG02InvoiceNumber = '01350'

		


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


declare	@InvoiceDetail table (
	ManifestNumber varchar(25),
	PartNumber varchar(25),
	CustomerPart varchar(50),
	QtyShipped int,
	Price numeric(20,6))
	
insert	@InvoiceDetail 
(	ManifestNumber,
	PartNumber,
	CustomerPart,
	QtyShipped,
	Price
	)
	
select
	
	md.ManifestNumber,
	sd.part_original,
	md.customerpart,
	md.Quantity,
	sd.alternate_price
from
	shipper_detail sd
join
	shipper s on s.id = @shipper
join
		EDIToyota.Pickups mp on mp.ShipperID = @shipper
join
		EDIToyota.ManifestDetails md on md.PickupID= mp.RowID
Where
	sd.shipper = @shipper and
	sd.order_no = md.OrderNo
	
declare
	InvoiceLine cursor local for
select
	ManifestNumber,
	PartNumber,
	Customerpart
	,	round(QtyShipped,0)
	,	round(Price,4)
	,	round(QtyShipped,0)
	,	round(Price,4)
From
	@InvoiceDetail InvoiceDetail


open
	InvoiceLine

while
	1 = 1 begin
	
	fetch
		InvoiceLine
	into
		@1REF02Manifest,
		@PartNumber,
		@1IT107CustomerPart
	,	@1IT102QtyInvoiced
	, @1IT104UnitPrice
	,	@1IT102QtyInvoicedNumeric
	, @1IT104UnitPriceNumeric
			
			
	if	@@FETCH_STATUS != 0 begin
		break
	end

	INSERT	#ASNFlatFile (LineData)
	SELECT	('//STX12//810'
						+  @TradingPartner 
						+  @ShipperIDHeader
						+  'P' )

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'01'
				+		@1BIG01InvoiceDate
				+		@1BIG02InvoiceNumber
						)


	Insert	#ASNFlatFile (LineData)
					Select  '02' 									
							+ @1IT01KanbanCard
							+ @1IT102QtyInvoiced
							+ @1IT104UnitPrice
							+ @1IT105BasisOfUnitPrice
							+ @1IT106PartQualifier
							+ @1IT107CustomerPart
							+ @1IT108PackageDrawingQual
							+ @1IT109PackageDrawing
							+ @1IT110
							+ @1IT111

	Insert	#ASNFlatFile (LineData)
					Select  '03' 									
							+ @1REF01MKQualifier
							+ @1REF02Manifest


	Insert	#ASNFlatFile (LineData)
					Select  '04' 									
							+ @1BIG01InvoiceDate



Select @1TDS01InvoiceAmount = substring(convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)),1,patindex('%.%', convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)))-1 ) +
		substring(convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)),patindex('%.%', convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)))+1, 2)


Insert	#ASNFlatFile (LineData)
					Select  '05' 									
							+ @1TDS01InvoiceAmount


	
	
								
end
close
	InvoiceLine	
 
deallocate
	InvoiceLine	




select 
	--LineData +convert(char(1), (lineID % 2 ))
	 LineData + case when left(linedata,2) in ('06', '11', '14') then '' else right(convert(char(2), (lineID )),2) end
From 
	#ASNFlatFile
order by 
	LineID


	      
set ANSI_Padding OFF	
go

rollback
go

