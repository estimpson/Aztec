SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE function [EDI_XML_Ford_ASN].[ASNReturnables]
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
				and at.type = 'S'
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

GO
