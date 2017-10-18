SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_replenish] (
	part,
	std_qty )
as
select	part_number,
	standard_qty
from	po_detail
where	status <> 'C'
union all
select	part,
	qty_required
from	workorder_detail
GO
