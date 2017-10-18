SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cdivw_scrapqtylist]
	(part,
	 scrapcode,
	scrapqty,
	scrapdate)
as	
select	df.part, 
	df.reason,
	df.quantity scrapqty,
	df.defect_date
from	defects df
union 
select	at.part,
	at.user_defined_status,
	at.quantity scrapqty,
	at.date_stamp
from	audit_trail at
where	at.status = 'S'
GO
