SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[fn_GetAccruedDowntime_forTimeSegment]
(	@SegmentBeginDT datetime
,	@SegmentEndDT datetime
,	@MachineCode varchar(10) = null
)
returns float
as
begin
--- <Body>
	declare
		@accruedDownTimeHours float
		
	select
		@accruedDownTimeHours = sum
		(	case
				when
					dte.StartDT between @SegmentBeginDT and @SegmentEndDT
					and dte.EndDT between @SegmentBeginDT and @SegmentEndDT
						then dte.DurationHours
				when
					dte.StartDT < @SegmentBeginDT
					and dte.EndDT between @SegmentBeginDT and @SegmentEndDT
						then datediff(second, @SegmentBeginDT, dte.EndDT) / 60.0 / 60.0
				when
					dte.StartDT between @SegmentBeginDT and @SegmentEndDT
					and dte.EndDT > @SegmentEndDT
						then datediff(second, dte.StartDT, @SegmentEndDT) / 60.0 / 60.0
				else
					datediff(second, @SegmentBeginDT, @SegmentEndDT) / 60.0 / 60.0
			end
		)
	from
		dbo.DownTimeEntries dte
	where
		dte.MachineCode = @MachineCode
		and dte.ParentEntryID is null
		and
		(	dte.StartDT between @SegmentBeginDT and @SegmentEndDT
			or dte.EndDT between @SegmentBeginDT and @SegmentEndDT)

--- </Body>

---	<Return>
	return
		@accruedDownTimeHours
end


GO
