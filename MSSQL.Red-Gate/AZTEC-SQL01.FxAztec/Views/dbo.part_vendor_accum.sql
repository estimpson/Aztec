SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[part_vendor_accum](part,vendor,accum_qty) as 
  select part,vendor,
    (select Isnull(sum(audit_trail.quantity),0) 
  from audit_trail 
  where audit_trail.part=part_vendor.part and 
        audit_trail.vendor=part_vendor.vendor and 
	audit_trail.type='R' and 
	audit_trail.date_stamp>=part_vendor.beginning_inventory_date) 
  from part_vendor
GO
