SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create view [dbo].[mvw_effectivechangenotice](ecn_part,
       effective_date) AS  
select ecn.part,       
       max(ecn.effective_date)
from   effective_change_notice  ecn
group by ecn.part
GO
