SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_prod_grid] @start_dt datetime, @mode char (1)
as
create table #mps (
	ai_row	integer )

insert	#mps (
	ai_row )
select	ai_row
from	master_prod_sched
order by part, due

if	@mode = 'D'
	select	mps.part,
		mps.due,
		mps.plant,
		mps.qnty,
		mps.qty_assigned,
		0 qty_onhand,
		mps.origin,
		part.product_line,
		part.class,
		part.commodity,
		part_machine.activity,
		( case
			when	due < @start_dt then -1
			when	due < dateadd ( day, 14, @start_dt ) and due >= @start_dt then datediff ( day, @start_dt, due )
			else	14
		end ) bucket_no,
		( case
			when	due < @start_dt then qnty 
			else 0
		end ) demandpast,
		( case
			when	due < dateadd ( day, 1, @start_dt ) and due >= @start_dt then qnty  
			else 0
		end ) demand1,
		( case
			when	due < dateadd ( day, 2, @start_dt ) and due >= dateadd ( day, 1, @start_dt ) then qnty 
			else 0
		end ) demand2,
		( case
			when	due < dateadd ( day, 3, @start_dt ) and due >= dateadd ( day, 2, @start_dt ) then qnty 
			else 0
		end ) demand3,
		( case
			when	due < dateadd ( day, 4, @start_dt ) and due >= dateadd ( day, 3, @start_dt ) then qnty 
			else 0
		end ) demand4,
		( case
			when	due < dateadd ( day, 5, @start_dt ) and due >= dateadd ( day, 4, @start_dt ) then qnty 
			else 0
		end ) demand5,
		( case
			when	due < dateadd ( day, 6, @start_dt ) and due >= dateadd ( day, 5, @start_dt ) then qnty 
			else 0
		end ) demand6,
		( case
			when	due < dateadd ( day, 7, @start_dt ) and due >= dateadd ( day, 6, @start_dt ) then qnty 
			else 0
		end ) demand7,
		( case
			when	due < dateadd ( day, 8, @start_dt ) and due >= dateadd ( day, 7, @start_dt ) then qnty 
			else 0
		end ) demand8,
		( case
			when	due < dateadd ( day, 9, @start_dt ) and due >= dateadd ( day, 8, @start_dt ) then qnty 
			else 0
		end ) demand9,
		( case
			when	due < dateadd ( day, 10, @start_dt ) and due >= dateadd ( day, 9, @start_dt ) then qnty 
			else 0
		end ) demand10,
		( case
			when	due < dateadd ( day, 11, @start_dt ) and due >= dateadd ( day, 10, @start_dt ) then qnty 
			else 0
		end ) demand11,
		( case
			when	due < dateadd ( day, 12, @start_dt ) and due >= dateadd ( day, 11, @start_dt ) then qnty 
			else 0
		end ) demand12,
		( case
			when	due < dateadd ( day, 13, @start_dt ) and due >= dateadd ( day, 12, @start_dt ) then qnty 
			else 0
		end ) demand13,
		( case
			when	due < dateadd ( day, 14, @start_dt ) and due >= dateadd ( day, 13, @start_dt ) then qnty 
			else 0
		end ) demand14,
		( case
			when	due >= dateadd ( day, 14, @start_dt ) then qnty 
			else 0
		end ) demandfuture,
		part.type,
		0,
		part.engineering_level,
		part.group_technology,
		mps.source,
		mps.qty_assigned queue
	from	#mps
		join master_prod_sched mps on #mps.ai_row = mps.ai_row
		join part on mps.part = part.part
		left outer join part_machine on mps.part = part_machine.part and
			part_machine.sequence = 1
else
	select	mps.part,
		mps.due,
		mps.plant,
		mps.qnty,
		mps.qty_assigned,
		0 qty_onhand,
		mps.origin,
		part.product_line,
		part.class,
		part.commodity,
		part_machine.activity,
		( case
			when	due < @start_dt then -1
			when	due < dateadd ( week, 14, @start_dt ) and due >= @start_dt then datediff ( day, @start_dt, due ) / 7
			else	14
		end ) bucket_no,
		( case
			when	due < @start_dt then qnty 
			else 0
		end ) demandpast,
		( case
			when	due < dateadd ( week, 1, @start_dt ) and due >= @start_dt then qnty 
			else 0
		end ) demand1,
		( case
			when	due < dateadd ( week, 2, @start_dt ) and due >= dateadd ( week, 1, @start_dt ) then qnty 
			else 0
		end ) demand2,
		( case
			when	due < dateadd ( week, 3, @start_dt ) and due >= dateadd ( week, 2, @start_dt ) then qnty 
			else 0
		end ) demand3,
		( case
			when	due < dateadd ( week, 4, @start_dt ) and due >= dateadd ( week, 3, @start_dt ) then qnty 
			else 0
		end ) demand4,
		( case
			when	due < dateadd ( week, 5, @start_dt ) and due >= dateadd ( week, 4, @start_dt ) then qnty 
			else 0
		end ) demand5,
		( case
			when	due < dateadd ( week, 6, @start_dt ) and due >= dateadd ( week, 5, @start_dt ) then qnty 
			else 0
		end ) demand6,
		( case
			when	due < dateadd ( week, 7, @start_dt ) and due >= dateadd ( week, 6, @start_dt ) then qnty 
			else 0
		end ) demand7,
		( case
			when	due < dateadd ( week, 8, @start_dt ) and due >= dateadd ( week, 7, @start_dt ) then qnty 
			else 0
		end ) demand8,
		( case
			when	due < dateadd ( week, 9, @start_dt ) and due >= dateadd ( week, 8, @start_dt ) then qnty 
			else 0
		end ) demand9,
		( case
			when	due < dateadd ( week, 10, @start_dt ) and due >= dateadd ( week, 9, @start_dt ) then qnty 
			else 0
		end ) demand10,
		( case
			when	due < dateadd ( week, 11, @start_dt ) and due >= dateadd ( week, 10, @start_dt ) then qnty 
			else 0
		end ) demand11,
		( case
			when	due < dateadd ( week, 12, @start_dt ) and due >= dateadd ( week, 11, @start_dt ) then qnty 
			else 0
		end ) demand12,
		( case
			when	due < dateadd ( week, 13, @start_dt ) and due >= dateadd ( week, 12, @start_dt ) then qnty 
			else 0
		end ) demand13,
		( case
			when	due < dateadd ( week, 14, @start_dt ) and due >= dateadd ( week, 13, @start_dt ) then qnty 
			else 0
		end ) demand14,
		( case
			when	due >= dateadd ( week, 14, @start_dt ) then qnty 
			else 0
		end ) demandfuture,
		part.type,
		0,
		part.engineering_level,
		part.group_technology,
		mps.source,
		mps.qty_assigned queue
	from	#mps
		join master_prod_sched mps on #mps.ai_row = mps.ai_row
		join part on mps.part = part.part
		left outer join part_machine on mps.part = part_machine.part and
			part_machine.sequence = 1
GO
