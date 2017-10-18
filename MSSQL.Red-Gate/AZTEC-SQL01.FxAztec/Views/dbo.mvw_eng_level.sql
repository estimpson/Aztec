SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create view [dbo].[mvw_eng_level](el_part,
       engineering_level,
       effective_date) AS  
select el.part,
       el.engineering_level,       
       el.effective_date
from   effective_change_notice  el
join   mvw_effectivechangenotice ecn on ecn.ecn_part = el.part and ecn.effective_date = el.effective_date
GO
