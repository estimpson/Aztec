declare
	@SupplierCode varchar(25) = '%'
,	@Destination varchar(25) = '%'

select
	spl.SupplierCode
,	spl.SupplierName
,	spo.ShipToCode
,	spo.ShipToName
,	spl.SupplierPartCode
,	spl.Status
,	spl.SupplierStdPack
,	spl.InternalPartCode
,	spl.Decription
,	spl.PartClass
,	spl.PartSubClass
,	spl.HasBlanketPO
,	spl.LabelFormatName
,	spo.PONumber
from
	SPORTAL.SupplierPartList spl
	cross apply
		(	select
		--top (1)
				PONumber = ph.po_number
			,	ShipToCode = ph.ship_to_destination
			,	ShipToName = d.name
			from
				dbo.po_header ph
				join dbo.destination d
					on d.vendor = ph.vendor_code
				join dbo.destination dst
					on dst.destination = ph.ship_to_destination
			where
				ph.blanket_part = spl.InternalPartCode
				and d.destination like @SupplierCode
				and ph.ship_to_destination like @Destination
			--order by
			--	ph.po_number desc		
		) spo
where
	spl.SupplierCode like @SupplierCode
	and spl.Status = 0
	and spo.ShipToCode not in ('AZTEC 1', 'AZTEC 2')
order by
	spl.SupplierCode
,	spo.ShipToCode
,	spl.InternalPartCode