SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_vendorlist] 
	(vendor,
	part ) 
as
select	part_vendor.vendor,
	part_vendor.part
from	part_vendor
where	part_vendor.vendor > ''
GO
