
select
	coalesce(oh.Serial, -1)
,	nm.Part
,	nm.BOMLevel
,	nm.Sequence
,	Suffix = 0
,	BOMID = coalesce(nm.BOMID, -1)
,	AllocationDT = oh.AllocationDT
,	QtyPer = nm.XQty
,	QtyAvailable = oh.QtyAvailable - coalesce(
	(	select
			sum(QtyIssue)
		from
			tempdb..Y y
		where
			y.Serial = oh.Serial
			and y.BOMID < nm.BOMID
		)
	,	0
	)
,	QtyRequired = nm.Balance + nm.QtyAvailable + nm.QtyWIP
,	QtyIssue = yInvAllocation.QtyIssue
,	HasChildren =
	case
		when exists
			(	select
					*
				from
					tempdb..XRt
				where
					TopPart = nm.Part
			) then 1
		else
			0
	end
,	QtyOverage =
		case
			when oh.Serial is null then nm.Balance - nm.QtySubAlloc - nm.QtyBuildable
			when oh.Serial =
				(	select
						max(Serial)
					from
						tempdb..OnHand
					where
						Part = nm.Part
						and AllocationDT = coalesce(LastAllocation.LastAllocated, oh.AllocationDT)
				) then nm.Balance - nm.QtySubAlloc - nm.QtyBuildable
			else 0
		end
from
	tempdb..NetMPS nm
	left join tempdb..Y yInvAllocation
		on nm.BOMID = yInvAllocation.BOMID
	left join tempdb..OnHand oh
		on yInvAllocation.Serial = oh.Serial
	left join
	(	select
			Part
		,	LastAllocated = max(AllocationDT)
		from
			tempdb..OnHand
		group by
			Part
	) LastAllocation
		on oh.Part = LastAllocation.Part
	join
	(	select
			Part
		,	TotalRequirement = sum(XQty)
		from
			tempdb..NetMPS
		group by
			Part
	) TotalRequirement
		on nm.Part = TotalRequirement.Part
order by
	nm.Sequence
,	oh.AllocationDT