SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [SPORTAL].[SupplierPartList]
as
select
	spl.SupplierCode
,	spl.SupplierName
,	spl.SupplierPartCode
,	Status = case when spl.SupplierPartCode > '' and spl.InternalPartCount = 1 and HasBlanketPO = 1 then 0 else -1 end
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
							where
								ph.blanket_part = p.part
								and ph.vendor_code = sl.SupplierCode
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
					on sl.SupplierCode = pv.vendor
				on pv.part = p.part
		where
			p.class != 'O'
	) spl

GO
