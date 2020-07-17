SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SPORTAL].[SupplierPartList]
as
select
	spl.SupplierCode
,	spl.SupplierName
,	spl.SupplierPartCode
,	Status =
		case 
			when spl.SupplierCode = 'MID0010' and spl.InternalPartCode like '2488%' then -1
			when spl.SupplierCode = 'MID0010' and spl.SupplierPartCode > '' and spl.InternalPartCount > 0 and HasBlanketPO = 1 then 0
			when spl.SupplierCode = 'AUB0010' and spl.SupplierPartCode > '' and spl.InternalPartCount > 0 and HasBlanketPO = 1 then 0
			when spl.SupplierCode = 'HIB0010' and spl.SupplierPartCode > '' and spl.InternalPartCount > 0 and HasBlanketPO = 1 then 0
			when spl.SupplierCode = 'RDI0010' and spl.SupplierPartCode > '' and spl.InternalPartCount > 0 and HasBlanketPO = 1 then 0
			when spl.SupplierPartCode > '' and spl.InternalPartCount = 1 and HasBlanketPO = 1 then 0 
			else -1 
		end
,	spl.SupplierStdPack
,	spl.InternalPartCount
,	spl.InternalPartCode
,	spl.Decription
,	spl.PartClass
,	spl.PartSubClass
,	spl.HasBlanketPO
,	spl.LabelFormatName
,	spl.PrimaryLocation
,	spl.StdUnit
from
	(	select
			sl.SupplierCode
		,	SupplierName = sl.Name
		,	SupplierPartCode = rtrim(coalesce(pv.vendor_part, p.cross_ref))
		,	SupplierStdPack = coalesce(pv.vendor_standard_pack, pInv.standard_pack)
		,	InternalPartCount = count(p.part) over (partition by sl.SupplierCode, rtrim(coalesce(pv.vendor_part, p.cross_ref)))
		,	InternalPartCode = p.part
		,	Decription = p.name
		,	PartClass = case p.class when 'P' then 'Purch' when 'M' then 'Manuf' else 'Misc.' end
		,	PartSubClass = case p.type when 'F' then 'Fin' when 'W' then 'WIP' when 'R' then 'Raw' else 'Misc.' end
		,	HasBlanketPO =
				case
					when exists
						(	select
								*
							from
								dbo.po_header ph
								join dbo.destination d
									on d.vendor = ph.vendor_code
							where
								ph.blanket_part = p.part
								and d.destination = sl.SupplierCode
								and ph.status = 'A'
						) then 1
					else 0
				end
		,	LabelFormatName = pInv.label_format
		,	PrimaryLocation = pInv.primary_location
		,	StdUnit = pInv.standard_unit
		from
			dbo.part p
			join dbo.part_inventory pInv
				on pInv.part = p.part
			join dbo.part_vendor pv
				join SPORTAL.SupplierList sl
					join dbo.destination d
						on d.destination = sl.SupplierCode
					on d.vendor = pv.vendor
				on pv.part = p.part
		where
			p.class != 'O'
	) spl

GO
GRANT SELECT ON  [SPORTAL].[SupplierPartList] TO [SupplierPortal]
GO
