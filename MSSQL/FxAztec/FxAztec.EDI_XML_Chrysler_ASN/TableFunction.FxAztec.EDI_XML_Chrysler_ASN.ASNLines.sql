
/*
Create function TableFunction.FxAztec.EDI_XML_Chrysler_ASN.ASNLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.ASNLines'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.ASNLines
end
go

create function EDI_XML_Chrysler_ASN.ASNLines
(	@shipperID int
)
returns @ASNLines table
(	PackingSlip varchar(25)
,	CustomerPart varchar(35)
,	ECL varchar(25)
,	BoxType varchar(25)
,	BoxCount int
,	PalletType varchar(25)
,	PalletCount int
,	QtyPacked int
,	AccumShipped int
,	PONumber varchar(20)
,	DockCode varchar(10)
,	ShipTo varchar(20)
,	ACIndicator char(1)
,	ACHandler char(2)
,	ACClause char(3)
,	ACCharge numeric(20,6)
)
as
begin
--- <Body>
	insert
		@ASNLines
	select
		PackingSlip = si.PackingSlip
	,	CustomrPart = bo.CustomerPart
	,	ECL = right(rtrim(bo.CustomerPart), 2)
	,	BoxType = si.PackageType
	,	BoxCount = si.Boxes
	,	PalletType = si.PalletPackageType
	,	PalletCount = si.Pallets
	,	QtyPacked = convert(int, si.QtyPacked)
	,	AccumShipped = convert(int, bo.AccumShipped)
	,	PONumber = bo.CustomerPO
	,	DockCode = bo.DockCode
	,	ShipTo = bo.EDIShipToCode
	,	ACIndicator = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then 'C'
		end
	,	ACHandler = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then '06'
		end
	,	ACClause = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then '092'
		end
	,	ACCharge = case when bo.Returnable = 'Y'
					and si.PackingSlip like '%E%'
					and bo.Clause092UnitCost > 0 then bo.Clause092UnitCost
		end * si.QtyPacked
	from
		ChryslerEDI.fn_ShipperInventory(@shipperID) si
		join dbo.shipper_detail sd
			on si.Part = sd.part_original
			   and sd.shipper = @shipperID
		join ChryslerEDI.BlanketOrders bo
			on sd.order_no = bo.BlanketOrderNo
		join shipper s
			on sd.shipper = s.id
		join edi_setups es
			on s.destination = es.destination
--- </Body>

---	<Return>
	return
end
go

declare
	@shipperID int = 75448

select
	*
from
	EDI_XML_Chrysler_ASN.ASNLines (@shipperID)
