SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_InventoryAnalysisDetailed]
	@PartCode varchar(25) = '1227'
as
set nocount on
set ansi_warnings off

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>

select
	RowID = identity(int, 1, 1)
,	oh.SnapshotName
,	SnapshotDT = min(oh.RowModifiedDT)
,	OnHand = sum(oh.StdQuantity)
into
	#temp
from
	dbo.ObjectHistory oh
where
	oh.Part = @PartCode
	and oh.Status = 'A'
group by
	oh.SnapshotName
,	oh.Status
order by
	3
;

with
	Snapshots
	(	RowID
	,	BeginSnapshotName
	,	BeginSnapshotDT
	,	BeginInventory
	,	EndSnapshotName
	,	EndSnapshotDT
	,	EndInventory
	,	DeltaInventory
	)
	as
		(	select
				t1.RowID
			,	BeginSnapshotName = t1.SnapshotName
			,	BeginShapshotDT = t1.SnapshotDT
			,	BeginInventory = t1.OnHand
			,	EndSnapshotName = t2.SnapshotName
			,	EndSnapshotDT = t2.SnapshotDT
			,	EndInventory = t2.OnHand
			,	DeltaInventory = t2.Onhand - t1.Onhand
			from
				#temp t1
				join #temp t2
					on t2.RowID = t1.RowID + 1
		)
,	Backflushing
	(	RowID
	,	QtyIssue
	,	QtyOverage
	)
	as
		(	select
				s.RowID
			,	QtyIssue = coalesce(sum(bd.QtyIssue), 0)
			,	QtyOverage = coalesce(sum(bd.QtyOverage), 0)
			from
				Snapshots s
				left join dbo.BackflushHeaders bh
					join dbo.BackflushDetails bd
						on bd.BackflushNumber = bh.BackflushNumber
						and bd.PartConsumed = @PartCode
					on bh.RowCreateDT between s.BeginSnapshotDT and s.EndSnapshotDT
			group by
				s.RowID
		)
,	Production
	(	RowID
	,	QtyProduced
	)
	as
		(	select
				s.RowID
			,	QtyProduced = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('J', 'R')
					and at.part = @PartCode
			group by
				s.RowID
		)
,	ManualConsumption
	(	RowID
	,	QtyManualIssued
	)
	as
		(	select
				s.RowID
			,	QtyManualIssued = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('M')
					and at.part = @PartCode
					and not exists
						(	select
			  					*
			  				from
			  					dbo.BackflushDetails bd
									join dbo.BackflushHeaders bh
										on bh.BackflushNumber = bd.BackflushNumber
							where
								at.serial = bd.SerialConsumed
								and at.date_stamp = bh.TranDT
						)
			group by
				s.RowID
		)
,	Scraps
	(	RowID
	,	QtyScrapped
	)
	as
		(	select
				s.RowID
			,	QtyScrapped = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('Q')
					and at.part = @PartCode
					and at.from_loc = 'A' and at.to_loc = 'S'
			group by
				s.RowID
		)
,	Additions
	(	RowID
	,	QtyAdded
	)
	as
		(	select
				s.RowID
			,	QtyAdded = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('A')
					and at.part = @PartCode
			group by
				s.RowID
		)
,	Deletions
	(	RowID
	,	QtyDeleted
	)
	as
		(	select
				s.RowID
			,	QtyDeleted = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('D')
					and at.part = @PartCode
			group by
				s.RowID
		)
,	Corrections
	(	RowID
	,	QtyCorrections
	)
	as
		(	select
				s.RowID
			,	QtyCorrections = coalesce(sum(at.quantity), 0)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.type in ('E')
					and at.part = @PartCode
			group by
				s.RowID
		)
,	Summary
	(	RowID
	,	SerialCount
	,	TranCount
	)
	as
		(	select
				s.RowID
			,	SerialCount = count(distinct at.serial)
			,	TranCount = count(*)
			from
				Snapshots s
				left join dbo.audit_trail at
					on at.date_stamp between s.BeginSnapshotDT and s.EndSnapshotDT
					and at.quantity != 0
					and at.part = @PartCode
			group by
				s.RowID
		)
select
	s.RowID
,	s.BeginSnapshotName
,	s.EndSnapshotName
,	s.BeginSnapshotDT
,	s.EndSnapshotDT
,	s.BeginInventory
,	s.EndInventory
,	s.DeltaInventory
,	b.QtyIssue
,	b.QtyOverage
,	p.QtyProduced
,	scrap.QtyScrapped
,	mc.QtyManualIssued
,	a.QtyAdded
,	d.QtyDeleted
,	CalcDeltaInventory = (p.QtyProduced + a.QtyAdded) - (b.QtyIssue + mc.QtyManualIssued + scrap.QtyScrapped + d.QtyDeleted)
,	Discrepancy = s.DeltaInventory - ((p.QtyProduced + a.QtyAdded) - (b.QtyIssue + mc.QtyManualIssued + scrap.QtyScrapped + d.QtyDeleted))
,	Corrections = c.QtyCorrections
,	Summary.SerialCount
,	Summary.TranCount
from
	Snapshots s
	join Backflushing b
		on b.RowID = s.RowID
	join Production p
		on p.RowID = s.RowID
	join Scraps scrap
		on scrap.RowID = s.RowID
	join ManualConsumption mc
		on mc.RowID = s.RowID
	join Additions a
		on a.RowID = s.RowID
	join Deletions d
		on d.RowID = s.RowID
	join Corrections c
		on c.RowID = s.RowID
	join Summary
		on Summary.RowID = s.RowID
--- </Body>
GO
