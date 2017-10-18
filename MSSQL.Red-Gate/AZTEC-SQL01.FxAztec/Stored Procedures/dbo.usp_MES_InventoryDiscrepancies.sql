SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[usp_MES_InventoryDiscrepancies]
	@BeginSnapshot varchar(255) = null
,	@EndSnapshot varchar(255) = null
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Email bit = 1
as
set nocount on
set ansi_warnings on
set	@Result = 999999

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

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
if	object_id('tempdb.dbo.##Temp')is not null begin
	drop table ##Temp
end

select
	@BeginSnapshot = coalesce(@BeginSnapshot, max(oh.SnapshotName))
from
	dbo.ObjectHistory oh
where
	oh.SnapShotName <
	(	select
			max(SnapshotName)
		from
			dbo.ObjectHistory
	)

select
	@EndSnapshot = coalesce(@EndSnapshot, min(oh.SnapshotName))
from
	dbo.ObjectHistory oh
where
	oh.SnapshotName > @BeginSnapshot

declare
	@BeginSnapshotEffectiveDT datetime
,	@EndSnapshotEffectiveDT datetime

select
	@BeginSnapshotEffectiveDT = max(oh.RowCreateDT)
from
	dbo.ObjectHistory oh
where
	oh.SnapshotName = @BeginSnapshot

select
	@EndSnapshotEffectiveDT = max(oh.RowCreateDT)
from
	dbo.ObjectHistory oh
where
	oh.SnapshotName = @EndSnapshot

select
	Part = msbp.ID
,   Status = coalesce(BeginningInventory.Status, EndingInventory.Status, 'A')
,   Beginning_Inventory = coalesce(BeginningInventory.OnHand, 0)
,   Ending_Inventory = coalesce(EndingInventory.OnHand, 0)
,	[Qty_Produced_Added_Received] = coalesce(Produced.QtyProduced, 0)
,   [Qty_Backflushed] = coalesce(Backflush.Issued, 0)
,	[Qty_Overage] = coalesce(Backflush.Overage, 0)
,	[Qty_Manually_Issued_Deleted_Scrapped] = coalesce(Issued.QtyIssued, 0)
,	[Calculated_Discrepancy] = coalesce(BeginningInventory.OnHand, 0) - coalesce(EndingInventory.OnHand, 0) + coalesce(Produced.QtyProduced, 0) - coalesce(Backflush.Issued, 0) - coalesce(Issued.QtyIssued, 0)
into
	##Temp
from
	dbo.MES_SetupBackflushingPrinciples msbp
	left join
	(	select
			oh.Part
		,	oh.Status
		,	OnHand = sum(oh.StdQuantity)
		from
			dbo.ObjectHistory oh
		where
			oh.SnapshotName = @BeginSnapshot
		group by
			oh.Part
		,	oh.Status
	) BeginningInventory
		on BeginningInventory.Part = msbp.ID
	left join
	(	select
			oh.Part
		,	oh.Status
		,	OnHand = sum(oh.StdQuantity)
		from
			dbo.ObjectHistory oh
		where
			oh.SnapshotName = @EndSnapshot
		group by
			oh.Part
		,	oh.Status
		union all
		select
			Part = o.part
		,	Status = o.status
		,	OnHand = sum(o.std_quantity)
		from
			dbo.object o
		where
			@EndSnapshot is null
		group by
			o.part
		,	o.status
	) EndingInventory
		on EndingInventory.Part = msbp.ID
		and EndingInventory.status = BeginningInventory.Status
	left join
	(	select
			bd.PartConsumed
		,	Issued = sum(bd.QtyIssue)
		,	Overage = sum(bd.QtyOverage)
		from
			dbo.BackflushHeaders bh
			join dbo.BackflushDetails bd
				on bd.BackflushNumber = bh.BackflushNumber
		where
			bh.RowCreateDT between @BeginSnapshotEffectiveDT and coalesce(@EndSnapshotEffectiveDT, getdate())
		group by
			bd.PartConsumed
	) Backflush
		on Backflush.PartConsumed = msbp.ID
		and coalesce(BeginningInventory.Status, EndingInventory.Status) = 'A'
	left join
	(	select
			Part = atProd.part
		,	QtyProduced = sum(atProd.std_quantity)
		from
			dbo.audit_trail atProd with (index = date_type)
		where
			atProd.date_stamp between @BeginSnapshotEffectiveDT and coalesce(@EndSnapshotEffectiveDT, getdate())
			and atProd.type in ('J', 'A', 'R')
		group by
			atProd.part
	) Produced
		on Produced.Part = msbp.ID
		and coalesce(BeginningInventory.Status, EndingInventory.Status) = 'A'
	left join
	(	select
			Part = atIssued.part
		,	QtyIssued = sum(atIssued.std_quantity)
		from
			dbo.audit_trail atIssued with (index = date_type)
		where
			atIssued.date_stamp between @BeginSnapshotEffectiveDT and coalesce(@EndSnapshotEffectiveDT, getdate())
			and	(	atIssued.type in ('M', 'D')
					or
					(	atIssued.type = 'Q'
						and atIssued.from_loc = 'A'
						and atIssued.to_loc = 'S'
					)
				)
			and not exists
			    (	select
			  		*
			  	from
			  		dbo.BackflushDetails bd
							join dbo.BackflushHeaders bh
								on bh.BackflushNumber = bd.BackflushNumber
					where
						atIssued.serial = bd.SerialConsumed
						and atIssued.date_stamp = bh.TranDT
				)
		group by
			atIssued.part
	) Issued
		on Issued.Part = msbp.ID
		and coalesce(BeginningInventory.Status, EndingInventory.Status) = 'A'
where
	msbp.Type = 3
	and msbp.BackflushingPrinciple != 0
	and coalesce(BeginningInventory.OnHand, 0) != coalesce(EndingInventory.OnHand, 0)
	and Backflush.PartConsumed is not null

if	@Email = 1 begin
	declare
		@html nvarchar(max)
	
	if	not exists
		(	select
				*
			from
				##Temp
		) begin
		select
			@html = '<br/>No changes in inventory.'
	end
	else begin
		select
			@tableName = N'##Temp'

		execute
			FT.usp_TableToHTML
			@tableName = @tableName
		,	@html = @html out
		,	@orderBy = 'Part'
	end
	
	declare
		@EmailBody nvarchar(max)
	,	@EmailHeader nvarchar(max)
	
	select
		@EmailHeader = 'MES Inventory Reconciliation'
	
	select
		@EmailBody =
			N'<H1>' + @EmailHeader + ' - ' + @BeginSnapshot + N'</H1>' +
			@html
	
	exec msdb.dbo.sp_send_dbmail
		@profile_name = 'DBMail'
	,	@recipients = 'estimpson@fore-thought.com; aboulanger@fore-thought.com; jmclean@21stcpc.com; munderwood@21stcpc.com; tBursley@21stcpc.com; cwright@21stcpc.com'
	, 	@subject = @EmailHeader
	,	@body = @EmailBody
	,	@body_format = 'HTML'
end
else begin
	select
		*
	from
		##Temp t
	order by
		t.Part

	select
		'MES Inventory Reconciliation - ' + @BeginSnapshot
end
--- </Body>

if	@TranCount = 0 begin
	commit tran @ProcName
end

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Email bit

set	@Email = 0

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_InventoryDiscrepancies
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Email = @Email

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
