while
	@@error = 0 and @@ROWCOUNT > 0 begin

declare
	@DupSerial int
,	@DupRowCDT datetime
,	@MaxRowID int

select top 1
	@DupSerial = oh.ObjectSerial
,	@DupRowCDT = oh.RowCreateDT
,	@MaxRowID = min(RowID)
from
	FT.ObjectHistory oh
--where
--	oh.ObjectSerial not in (1845151, 1845142, 1845134, 1845133)
group by
	oh.ObjectSerial
,	oh.RowCreateDT
having
	count(*) > 1
order by
	count(*) desc, oh.RowCreateDT desc

delete
	oh
from
	FT.ObjectHistory oh
where
	oh.RowCreateDT = @DupRowCDT
	and oh.ObjectSerial = @DupSerial
	and oh.RowID != @MaxRowID

end