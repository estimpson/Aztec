
/*
Create function TableFunction.FxAztec.EDI_XML_FORD_ASN.ASNReturnables.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_FORD_ASN.ASNReturnables'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_FORD_ASN.ASNReturnables
end
go

create function EDI_XML_FORD_ASN.ASNReturnables
(	@ShipperID int
)
returns @Returnables table
(	ReturnableCode varchar(20)
,	ReturnableCount int
,	RowNumber int
)
as
begin
--- <Body>
	insert
		@Returnables
	(	ReturnableCode
	,	ReturnableCount
	,	RowNumber
	)
	select
		returnables.ReturnableCode
	,	returnables.ReturnableCount
	,	RowNumber = row_number() over (order by returnables.ReturnableCode)
	from
		(	select
				ReturnableCode = at.package_type
			,	ReturnableCount = count(at.package_type)
			from
				dbo.audit_trail at
				join dbo.package_materials pm
					on pm.code = at.package_type
					and pm.returnable = 'Y'
			where
				at.shipper = convert(varchar, @ShipperID)
				and at.part != '3366'
				and at.package_type not like '%PB12L12%'
			group by
				at.package_type
			union
			select
				' ' + bom.part + ' '
			,	ceiling(shipper_detail.qty_packed * bom.quantity)
			from
				shipper_detail
				join dbo.bill_of_material bom
					on bom.parent_part = shipper_detail.part_original
			where
				shipper = @ShipperID
				and part_original = '3366'
				and bom.part = 'PB12L12'
		) returnables
	order by
		returnables.ReturnableCode
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	EDI_XML_FORD_ASN.ASNReturnables(75964)
