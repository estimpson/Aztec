SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_GetLabel_TSM_AmericanAxle]
	@BoxSerial int
,	@LabelData varchar(8000) out
,	@Result integer out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Body>
/*	Retrieve label data. */
declare
	@ObjectSerial varchar(25)
,	@LicensePlate varchar(50)
,	@ObjectQty varchar(25)
,	@Lot varchar(20)
,	@OHCustomerPart varchar(35)
,	@OHCustomerPO varchar(20)
,	@DockCode varchar(10)
,	@LineFeedCode varchar(30)
,	@AAGroupNo varchar(30)
,	@Line11 varchar(35)
,	@Line12 varchar(35)
,	@Line13 varchar(35)
,	@Line14 varchar(35)
,	@Line15 varchar(35)
,	@Line16 varchar(35)
,	@Line17 varchar(35)
,	@AAKanban varchar(50)
,	@AAOrderNo varchar(50)
,	@SupplierCode varchar(20)
,	@AAShipToID varchar(20)
,	@CompanyName varchar(50)
,	@CompanyAddress1 varchar(30)
,	@CompanyAddress2 varchar(30)
,	@CompanyAddress3 varchar(30)
,	@ShipToAddress1 varchar(50)
,	@ShipToAddress2 varchar(50)
,	@ShipToAddress3 varchar(50)
,	@ShipToAddress4 varchar(40)
,	@PartDesc1 varchar(15)
,	@PartDesc2 varchar(15)
,	@PartDesc3 varchar(15)
,	@AAECL varchar(25)
,	@AADate varchar(9)
,	@HeatNumber varchar(25)
,	@GrossWeight varchar(25)
,	@TareWeight varchar(25)
,	@2DBarCodeLen int
,	@2DBarCodeLenStr char(4)
,	@2DBarCode varchar(15)


/* TEST 
set @ObjectSerial = '123456'
set	@LicensePlate = 'LP1234567890'
set	@ObjectQty = '999'
set	@Lot = 'LOT123'
set	@OHCustomerPart = 'CP8989891'
set	@OHCustomerPO = 'PO12345'
set	@DockCode = 'DOCK99'
set	@LineFeedCode = 'LFC10'
set	@AAGroupNo = 'G889'
set	@Line11 = ''
set	@Line12 = ''
set	@Line13 = ''
set	@Line14 = ''
set	@Line15 = ''
set	@Line16 = ''
set	@Line17 = ''
set	@AAKanban = 'KANBAN100'
set	@AAOrderNo = '55555'
set	@SupplierCode = 'SC271'
set	@AAShipToID = '988774'
set	@CompanyName = 'TSM Corp'
set	@CompanyAddress1 = 'Address 1'
set	@CompanyAddress2 = 'Address 2'
set	@CompanyAddress3 = 'Address 3'
set	@ShipToAddress1 = 'ShipTo Address 1'
set	@ShipToAddress2 = 'ShipTo Address 2'
set	@ShipToAddress3 = 'ShipTo Address 3'
set	@ShipToAddress4 = 'ShipTo Address 4'
set	@PartDesc1 = 'Description 1'
set	@PartDesc2 = 'Description 2'
set	@PartDesc3 = 'Description 3'
set	@AAECL = 'ECL7'
set	@AADate = '13JAN2011'
set	@HeatNumber = ''
set	@GrossWeight = ''
set	@TareWeight = ''
*/
		

select
	@ObjectSerial = ObjectSerial
,	@LicensePlate = LicensePlate
,	@ObjectQty = ObjectQty
,	@Lot = Lot
,	@OHCustomerPart = OHCustomerPart
,	@OHCustomerPO = OHCustomerPO
,	@DockCode = DockCode
,	@LineFeedCode = LineFeedCode
,	@AAGroupNo = AAGroupNo
,	@Line11 = Line11
,	@Line12 = Line12
,	@Line13 = Line13
,	@Line14 = Line14
,	@Line15 = Line15
,	@Line16 = Line16
,	@Line17 = Line17
,	@AAKanban = AAKanban
,	@AAOrderNo = AAOrderNo
,	@SupplierCode = SupplierCode
,	@AAShipToID = AAShipToID
,	@CompanyName = CompanyName
,	@CompanyAddress1 = CompanyAddress1
,	@CompanyAddress2 = CompanyAddress2
,	@CompanyAddress3 = CompanyAddress3
,	@ShipToAddress1 = ShipToAddress1
,	@ShipToAddress2 = ShipToAddress2
,	@ShipToAddress3 = ShipToAddress3
,	@ShipToAddress4 = ShipToAddress4
,	@PartDesc1 = PartDesc1
,	@PartDesc2 = PartDesc2
,	@PartDesc3 = PartDesc3
,	@AAECL = AAECL
,	@AADate = AADate
,	@HeatNumber = ''
,	@GrossWeight = ''
,	@TareWeight = ''
from
    dbo.vw_AmericanAxle_Container
where
    ObjectSerial = @BoxSerial


-- Add lengths of all 2D fields that will actually be on the label plus qualifiers
set @2DBarCodeLen = len(@LicensePlate) + 
		len(@Lot) + 
		len(@ObjectQty) + 
		len(@AAOrderNo) +
		len(@OHCustomerPart) + 
		len(@AAKanban) +
		len(@AAECL) +
		len(@HeatNumber) +
		len(@DockCode) +
		len(@AAGroupNo) +
		len(@AADate) +  
		len(@GrossWeight) + 
		len(@TareWeight) + 
		28
				
if @2DBarCodeLen = 2
	begin
		set @2DBarCodeLenStr = '00' + convert(char(2), @2DBarCodeLen)
	end
else if @2DBarCodeLen = 3
	begin
		set @2DBarCodeLenStr = '0' + convert(char(3), @2DBarCodeLen)
	end
else
	begin
		set @2DBarCodeLenStr = convert(char(4), @2DBarCodeLen)
	end
		
-- Create a new 2D Barcode format		
set @2DBarCode = 'BK030410200' + @2DBarCodeLenStr



/*	Retreive label code. */
declare
	@labelCode varchar(8000)

select
	@labelCode = LabelCode
from
	dbo.LabelDefinitions ld
where
	LabelName = 'w_tsm_generate_label_from_prn'
	and
		PrinterType = 'SATO'


/*	Replace label code with label data for this box. */
set	@labelCode = replace(@labelCode, '[OBJECTSERIAL]', @ObjectSerial)
set	@labelCode = replace(@labelCode, '[LICENSEPLATE]', @LicensePlate)
set	@labelCode = replace(@labelCode, '[OBJECTQTY]', @ObjectQty)
set	@labelCode = replace(@labelCode, '[LOT]', @Lot)
set	@labelCode = replace(@labelCode, '[OHCUSTOMERPART]', @OHCustomerPart)
set	@labelCode = replace(@labelCode, '[OHCUSTOMERPO]', @OHCustomerPO)
set	@labelCode = replace(@labelCode, '[DOCKCODE]', @DockCode)
set	@labelCode = replace(@labelCode, '[LINEFEEDCODE]', @LineFeedCode)
set	@labelCode = replace(@labelCode, '[AAGROUPNO]', @AAGroupNo)
set	@labelCode = replace(@labelCode, '[LINE11]', @Line11)
set	@labelCode = replace(@labelCode, '[LINE12]', @Line12)
set	@labelCode = replace(@labelCode, '[LINE13]', @Line13)
set	@labelCode = replace(@labelCode, '[LINE14]', @Line14)
set	@labelCode = replace(@labelCode, '[LINE15]', @Line15)
set	@labelCode = replace(@labelCode, '[LINE16]', @Line16)
set	@labelCode = replace(@labelCode, '[LINE17]', @Line17)
set	@labelCode = replace(@labelCode, '[AAKANBAN]', @AAKanban)
set	@labelCode = replace(@labelCode, '[AAORDERNO]', @AAOrderNo)
set	@labelCode = replace(@labelCode, '[SUPPLIERCODE]', @SupplierCode)
set	@labelCode = replace(@labelCode, '[AASHIPTOID]', @AAShipToID)
set	@labelCode = replace(@labelCode, '[COMPANYNAME]', @CompanyName)
set	@labelCode = replace(@labelCode, '[COMPANYADDRESS1]', @CompanyAddress1)
set	@labelCode = replace(@labelCode, '[COMPANYADDRESS2]', @CompanyAddress2)
set	@labelCode = replace(@labelCode, '[COMPANYADDRESS3]', @CompanyAddress3)
set	@labelCode = replace(@labelCode, '[SHIPTOADDRESS1]', @ShipToAddress1)
set	@labelCode = replace(@labelCode, '[SHIPTOADDRESS2]', @ShipToAddress2)
set	@labelCode = replace(@labelCode, '[SHIPTOADDRESS3]', @ShipToAddress3)
set	@labelCode = replace(@labelCode, '[SHIPTOADDRESS4]', @ShipToAddress4)
set	@labelCode = replace(@labelCode, '[PARTDESC1]', @PartDesc1)
set	@labelCode = replace(@labelCode, '[PARTDESC2]', @PartDesc2)
set	@labelCode = replace(@labelCode, '[PARTDESC3]', @PartDesc3)
set	@labelCode = replace(@labelCode, '[AAECL]', @AAECL)
set	@labelCode = replace(@labelCode, '[AADATE]', @AADate)
set	@labelCode = replace(@labelCode, '[HEATNUMBER]', @HeatNumber)
set	@labelCode = replace(@labelCode, '[GROSSWEIGHT]', @GrossWeight)
set	@labelCode = replace(@labelCode, '[TAREWEIGHT]', @TareWeight)
set @labelCode = replace(@labelCode, 'BK0303102000168', @2DBarCode) 
--- </Body>

---	<Return>
set @LabelData = @labelCode

set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@boxSerial int
,	@labelData varchar(8000)

set	@boxSerial = 10254204

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_GetLabel_L_FIN_ZEBRA
	@BoxSerial = @boxSerial
,	@LabelData = @labelData out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @labelData, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
