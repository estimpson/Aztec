
/*
Create table fx21st.dbo.Scheduling_InLineProcess
*/

use fx21st
go

--drop table dbo.Scheduling_InLineProcess
if	objectproperty(object_id('dbo.Scheduling_InLineProcess'), 'IsView') = 1 begin
	drop view dbo.Scheduling_InLineProcess
end
go

create view dbo.Scheduling_InLineProcess
as
select
	TopPartCode
,	DefaultOutputPartCode = coalesce
	(	(	select
				min(pm1.ChildPartCode)
			from
				(	select
						TopPartCode = xr.TopPart
					,   ChildPartCode = xr.ChildPart
					,	xr.Sequence
					,   xr.Hierarchy
					,   MachineCode = pm.machine
					from
						FT.XRt xr
						join dbo.part_machine pm
							on pm.part = xr.ChildPart
				) pm1
			where
				pm1.TopPartCode = pm.TopPartCode
				and pm1.Sequence =
				(	select
						max(pm2.Sequence)
					from
						(	select
								TopPartCode = xr.TopPart
							,   ChildPartCode = xr.ChildPart
							,	xr.Sequence
							,   xr.Hierarchy
							,   MachineCode = pm.machine
							from
								FT.XRt xr
								join dbo.part_machine pm
									on pm.part = xr.ChildPart
						) pm2
					where
						pm2.TopPartCode = pm.TopPartCode
						and pm.MachineCode in (pm2.MachineCode)
						and pm.Sequence > pm2.Sequence
						and pm.Hierarchy like pm2.Hierarchy + '%'
				)
				and not exists
				(	select
						*
					from
						(	select
								TopPartCode = xr.TopPart
							,   ChildPartCode = xr.ChildPart
							,	xr.Sequence
							,   xr.Hierarchy
							,   MachineCode = pm.machine
							from
								FT.XRt xr
								join dbo.part_machine pm
									on pm.part = xr.ChildPart
						) pm3
					where
						pm3.TopPartCode = pm.TopPartCode
						and pm3.Hierarchy like pm1.Hierarchy + '%'
						and pm.Hierarchy like pm3.Hierarchy + '%'
						and pm3.Sequence > pm1.Sequence
						and pm3.Sequence < pm.Sequence
						and not exists
						(	select
								*
							from
								(	select
										TopPartCode = xr.TopPart
									,   ChildPartCode = xr.ChildPart
									,	xr.Sequence
									,   xr.Hierarchy
									,   MachineCode = pm.machine
									from
										FT.XRt xr
										join dbo.part_machine pm
											on pm.part = xr.ChildPart
								) pm4
							where
								pm4.TopPartCode = pm.TopPartCode
								and pm4.Sequence = pm3.Sequence
								and pm4.MachineCode = pm.MachineCode
						)
				)
		)
	,	ChildPartCode
	)
,	OutputPartCode = ChildPartCode
,	Sequence
,	BOMLevel
,	XQty
,	MachineCode
,	Hierarchy
from
	(	select
			TopPartCode = xr.TopPart
		,   ChildPartCode = xr.ChildPart
		,	xr.Sequence
		,	xr.BOMLevel
		,	xr.XQty
		,   xr.Hierarchy
		,   MachineCode = pm.machine
		from
			FT.XRt xr
			join dbo.part_machine pm
				on pm.part = xr.ChildPart
	) pm
go


select
	xr.*, pm.*
from
	FT.XRt xr
	join dbo.WorkOrderDetails wod
		on wod.PartCode = xr.TopPart
	left join dbo.part_machine pm
		on pm.part = xr.ChildPart
		and pm.sequence = 1
order by
	xr.TopPart
,	xr.Sequence