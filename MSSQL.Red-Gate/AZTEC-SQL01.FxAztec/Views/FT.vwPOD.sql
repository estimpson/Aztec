SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwPOD]
(	PONumber,
	VendorCode,
	Part,
	DueDT,
	LineID,
	DeliveryWeek,
	StdQty,
	LeadDays,
	RawDays,
	FABDays,
	ReleaseControl,
	NonOrderStatus
)
as
--	Description:
--	Get open purchase order details (must be an updateable view).
select
	PONumber = po_detail.po_number,
	VendorCode = po_detail.vendor_code,
	Part = po_detail.part_number,
	DueDT = po_detail.date_due,
	LineID = po_detail.row_id,
	DeliveryWeek = DateDiff (week, FT.fn_DTGlobal ('BaseWeek'), po_detail.date_due) - DateDiff (week, FT.fn_DTGlobal ('BaseWeek'), GetDate ()),
	StdQty = po_detail.balance,
	LeadDays = coalesce (
	(	select
			min ( part_vendor.lead_time )
		from
			dbo.part_vendor
		where
			po_detail.part_number = part_vendor.part
			and
				po_detail.vendor_code = part_vendor.vendor
	), 0 ),
	RawDays = 28,
	FABDays = 14,
	ReleaseControl =
	(	select
			po_header.release_control
		from
			dbo.po_header
		where
			po_detail.po_number = po_header.po_number
	),
	NonOrderStatus = 'N'
from
	dbo.po_detail
where
	po_detail.balance >= 0
	and
		exists
		(	select
				po_header.po_number
			from
				dbo.po_header
			where
				po_detail.po_number = po_header.po_number
				and
					po_header.status = 'A'
		)
GO
