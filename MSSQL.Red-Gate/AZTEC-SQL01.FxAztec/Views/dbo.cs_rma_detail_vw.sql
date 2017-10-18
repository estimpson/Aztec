SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_rma_detail_vw]
as 
select	distinct	shipper,
	part_original,
	isnull(suffix,0) as suffix,
	part,
	qty_required,
	qty_packed,
	shipper_detail.operator,
	price,
	customer as rmacustomer,
	shipper_detail.old_shipper as original_shipper,
	(case 
		when abs(isnull(qty_packed,0)) >= abs(isnull(qty_required,0)) then 'RMA CLOSED & READY FOR INVOICING '
		else 'RMA PENDING & NOT READY FOR INVOICING ' 
	end) RMAstatus
from 	shipper_detail 
	join shipper on id=shipper
GO
