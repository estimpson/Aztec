SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[Inventory_BreakOutHistory]
as
select
	FromSerial = atBreakFrom.serial
,	TranDT = atBreakFrom.date_stamp
,	FromPartCode = atBreakFrom.part
,	ToSerial = atBreakTo.serial
,	Quantity = atBreakTo.std_quantity
from
	dbo.audit_trail atBreakFrom
	join
		(	select
				*
			from
				dbo.audit_trail at
			where
				at.type = 'B'
				and at.from_loc like '%[0-9]%'
				and at.from_loc not like '%[^0-9]%'
		) atBreakTo
		on convert(int, atBreakTo.from_loc) = atBreakFrom.serial
		and datediff(second, atBreakTo.date_stamp, atBreakFrom.date_stamp) between 0 and 10
where
	atBreakFrom.type = 'B'
GO
