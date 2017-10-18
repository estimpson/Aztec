SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [EDIToyota].[usp_Process]
	@TranDT datetime = null out
,	@Result integer = null out
,	@Testing int = 1
--<Debug>
,	@Debug integer = 0
--</Debug>
as
--if	@Debug = 0 return 100
set nocount on
set ansi_warnings on
set	@Result = 999999

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	set	@StartDT = GetDate ()
	print	'START.   ' + Convert (varchar (50), @StartDT)
	set	@ProcStartDT = GetDate ()
end
--</Debug>

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
/*	Mark any shipped manifests. */
--<Debug>
if @Debug & 1 = 1 begin
	print	'Mark any shipped manifests.'
end
--</Debug>
--- <Call>	
set	@CallProcName = 'EDIToyota.usp_MarkShippedManifests'
execute
	@ProcReturn = EDIToyota.usp_MarkShippedManifests
		@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

/*	Mark any shipped Ship Schedules. */
--<Debug>
if @Debug & 1 = 1 begin
	print	'Mark any shipped Ship Schedules.'
end
--</Debug>
--- <Call>	
set	@CallProcName = 'EDIToyota.usp_MarkShippedShipSchedules'
execute
	@ProcReturn = EDIToyota.usp_MarkShippedShipSchedules
		@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

--<Debug>
if @Debug & 1 = 1 begin
	print	'Determine the current 830s and 862s.'
	print	'	Active are all 862s for a Ship To / Ship From / last Document DT / last Imported Version (for Document Number / Control Number).'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	Determine the current 830s and 862s. */
/*		Active are all 862s for a Ship To / Ship From / last Document DT / last Imported Version (for Document Number / Control Number).*/
declare
	@Current862s table
(	RawDocumentGUID uniqueidentifier
,	ReleaseNo varchar(50)
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ConsigneeCode varchar(15)
,	CustomerPart varchar(35)
,	CustomerPO varchar(35)
,	CustomerModelYear varchar(35)
,	NewDocument int
)

insert
	@Current862s
select distinct
	RawDocumentGUID
,	ReleaseNo
,   ShipToCode
,   ShipFromCode
,   ConsigneeCode
,   CustomerPart
,   CustomerPO
,	CustomerModelYear
,   NewDocument
from
	EDIToyota.CurrentShipSchedules ()

--<Debug>
if @Debug & 1 = 1 begin
	print	'	Active are last Imported version of last Doc Number of last Document DT for every combination
		of ShipTo, ShipFrom, InterCompany, and CustomerPart.'
end
--</Debug>
/*		Active are last Imported version of last Doc Number of last Document DT for every combination
		of ShipTo, ShipFrom, InterCompany, and CustomerPart.  */
declare
	@Current830s table
(	RawDocumentGUID uniqueidentifier
,	ReleaseNo varchar(50)
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ConsigneeCode varchar(15)
,	CustomerPart varchar(35)
,	CustomerPO varchar(35)
,	CustomerModelYear varchar(35)
,	NewDocument int
)

insert
	@Current830s
select distinct
	RawDocumentGUID
,	ReleaseNo
,   ShipToCode
,   ShipFromCode
,   ConsigneeCode
,   CustomerPart
,   CustomerPO
,	CustomerModelYear
,   NewDocument
from
	EDIToyota.CurrentPlanningReleases ()

--<Debug>
if @Debug & 1 = 1 begin
	print	'...determined.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

/*		If the current 862s and 830s are already "Active", done. */
if	not exists
	(	select
			*
		from
			@Current862s cd
		where
			cd.NewDocument = 1
	)
	and not exists
	(	select
			*
		from
			@Current830s cd
		where
			cd.NewDocument = 1
	)
	and @Testing = 0 begin
	set @Result = 100
	rollback transaction @ProcName
	return
end

--<Debug>
if @Debug & 1 = 1 begin
	print	'Mark "Active" 862s and 830s.'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	Mark "Active" 862s and 830s. */
--- <Update rows="*">
set	@TableName = 'EDIToyota.SchipSchedules'

update
	ss
set
	Status =
		case
			when c.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Status', 'Replaced'))
		end
from
	EDIToyota.ShipSchedules ss
	left join @Current862s c
		on ss.RawDocumentGUID = c.RawDocumentGUID
		and ss.ShipToCode = c.ShipToCode
		and ss.CustomerPart = c.CustomerPart
		and coalesce(ss.CustomerPO, '') = coalesce(c.CustomerPO, '')
		and coalesce(ss.CustomerModelYear, '') = coalesce(c.CustomerModelYear, '')
where
	ss.Status in
	(	0 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIToyota.ShipScheduleHeaders'

update
	ssh
set
	Status =
	case
		when exists
			(	select
					*
				from
					EDIToyota.ShipSchedules ss
				where
					ss.RawDocumentGUID = ssh.RawDocumentGUID
					and ss.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active')
			) then 1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
		else 2 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Replaced'))
	end
from
	EDIToyota.ShipScheduleHeaders ssh
where
	ssh.Status in
	(	0 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...marked.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--- <Update rows="*">
set	@TableName = 'EDIToyota.PlanningReleases'

update
	PR
set
	Status =
		case
			when c.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'Replaced'))
		end
from
	EDIToyota.PlanningReleases PR
	left join @Current830s c
		on PR.RawDocumentGUID = c.RawDocumentGUID
		and PR.ShipToCode = c.ShipToCode
		and PR.CustomerPart = c.CustomerPart
		and coalesce(PR.CustomerPO, '') = coalesce(c.CustomerPO, '')
		and coalesce(PR.CustomerModelYear, '') = coalesce(c.CustomerModelYear, '')

where
	PR.Status in
	(	0 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIToyota.PlanningHeaders'

update
	ph
set
	Status =
		case
			when exists
				(	select
						*
					from
						EDIToyota.PlanningReleases pr
					where
						pr.RawDocumentGUID = ph.RawDocumentGUID
						and pr.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'Active')
				) then 1 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'Replaced'))
		end
from
	EDIToyota.PlanningHeaders ph
where
	ph.Status in
	(	0 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...marked.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

if	@Testing > 1 begin
	select
		'ShipScheduleHeaders'

	select
		*
	from
		EDIToyota.ShipScheduleHeaders fh

	select
		'PlanningHeaders'
		
	select
		*
	from
		EDIToyota.PlanningHeaders fh
end

/*	Create new pickups and manifest details. */
--- <Call>
set	@CallProcName = 'EDIToyota.usp_CreateNewPickupsAndManifestDetails'
execute
	@ProcReturn = EDIToyota.usp_CreateNewPickupsAndManifestDetails
		@TranDT = @TranDT out
	,	@Result = @ProcResult out
	,	@Testing = @Testing
	,	@Debug = @Debug

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

--<Debug>
if @Debug & 1 = 1 begin
	print	'Write new releases.'
	print	'	Calculate raw releases from active 862s and 830s.'
	set	@StartDT = GetDate ()
end
--</Debug>

/*	Write new releases. */
/*		Calculate raw releases from active 862s and 830s. */
declare
	@RawReleases table
(	RowID int not null IDENTITY(1, 1) primary key
,	Status int default(0)
,	ReleaseType int
,	OrderNo int
,	Type tinyint
,	ReleaseDT datetime
,	BlanketPart varchar(25)
,	CustomerPart varchar(35)
,	ShipToID varchar(20)
,	CustomerPO varchar(20)
,	ModelYear varchar(4)
,	OrderUnit char(2)
,	QtyShipper numeric(20,6)
,	Line int
,	ReleaseNo varchar(30)
,	DockCode varchar(30) null
,	LineFeedCode varchar(30) null
,	ReserveLineFeedCode varchar(30) null
,	QtyRelease numeric(20,6)
,	StdQtyRelease numeric(20,6)
,	ReferenceAccum numeric(20,6)
,	CustomerAccum numeric(20,6)
,	RelPrior numeric(20,6)
,	RelPost numeric(20,6)
,	NewDocument int
,	unique
	(	OrderNo
	,	NewDocument
	,	RowID
	)
,	unique
	(	OrderNo
	,	RowID
	,	RelPost
	,	QtyRelease
	,	StdQtyRelease
	)
,	unique
	(	OrderNo
	,	Type
	,	RowID
	)
)

insert
	@RawReleases
(	ReleaseType
,	OrderNo
,	Type
,	ReleaseDT
,	BlanketPart
,	CustomerPart
,	ShipToID
,	CustomerPO
,	ModelYear
,	OrderUnit
,	ReleaseNo
,	QtyRelease
,	StdQtyRelease
,	ReferenceAccum
,	CustomerAccum
,	NewDocument
)
/*		Add releases due today when behind and no release for today exists. */
select
	ReleaseType = 1
,	OrderNo = bo.BlanketOrderNo
,	Type = 1
,	ReleaseDT = FT.fn_TruncDate('dd', getdate())
,	BlanketPart = min(bo.PartCode)
,	CustomerPart = min(bo.CustomerPart)
,	ShipToID = min(bo.ShipToCode)
,	CustomerPO = min(bo.CustomerPO)
,	ModelYear = min(bo.ModelYear)
,	OrderUnit = min(bo.OrderUnit)
,	ReleaseNo = min(ss.UserDefined1)
,	QtyRelease = 0
,	StdQtyRelease = 0
,	ReferenceAccum =
		case bo.ReferenceAccum 
			when 'N' 
				then min(coalesce(convert(int,bo.AccumShipped),0))
			when 'C' 
				then min(coalesce(convert(int,ssa.LastAccumQty),0))
			else min(coalesce(convert(int,bo.AccumShipped),0))
		end
,	CustomerAccum =
		case bo.AdjustmentAccum 
			when 'N' 
				then min(coalesce(convert(int,bo.AccumShipped),0))
			when 'P' 
				then min(coalesce(convert(int,ssaa.PriorCUM),0))
			else min(coalesce(convert(int,ssa.LastAccumQty),0))
		end
,	NewDocument =
		(	select
				min(c.NewDocument)
			from
				@Current862s c
			where
				c.RawDocumentGUID = ssh.RawDocumentGUID
		)
from
	EDIToyota.ShipScheduleHeaders ssh
	join EDIToyota.ShipSchedules ss
		on ss.RawDocumentGUID = ssh.RawDocumentGUID
	left join EDIToyota.ShipScheduleAccums ssa
		on ssa.RawDocumentGUID = ssh.RawDocumentGUID
		and ssa.CustomerPart = ss.CustomerPart
		and	ssa.ShipToCode = ss.ShipToCode
		and	coalesce(ssa.CustomerPO,'') = coalesce(ss.CustomerPO,'')
		and	coalesce(ssa.CustomerModelYear,'') = coalesce(ss.CustomerModelYear,'')
	left join EDIToyota.ShipScheduleAuthAccums ssaa
		on ssaa.RawDocumentGUID = ssh.RawDocumentGUID
		and ssaa.CustomerPart = ss.CustomerPart
		and	ssaa.ShipToCode = ss.ShipToCode
		and	coalesce(ssaa.CustomerPO,'') = coalesce(ss.CustomerPO,'')
		and	coalesce(ssaa.CustomerModelYear,'') = coalesce(ss.CustomerModelYear,'')
	join EDIToyota.BlanketOrders bo
		on bo.EDIShipToCode = ss.ShipToCode
		and bo.CustomerPart = ss.CustomerPart
		and
		(	bo.CheckCustomerPOShipSchedule = 0
			or bo.CustomerPO = ss.CustomerPO
		)
		and
		(	bo.CheckModelYearShipSchedule = 0
			or bo.ModelYear862 = ss.CustomerModelYear
		)
		join
			@Current862s c 
			on
				c.CustomerPart = bo.customerpart and
				c.ShipToCode = bo.EDIShipToCode and
				(	bo.CheckCustomerPOShipSchedule = 0
							or bo.CustomerPO = c.CustomerPO
				)
					and	(	bo.CheckModelYearShipSchedule = 0
							or bo.ModelYear862 = c.CustomerModelYear
				)
where
	not exists
		(	select
				*
			from
				EDIToyota.ShipSchedules ss
			where
				ss.status = 1 and
				ss.RawDocumentGUID = c.RawDocumentGUID and
				ss.RawDocumentGUID = ss.RawDocumentGUID
				and ss.CustomerPart = ss.CustomerPart
				and ss.ShipToCode = ss.ShipToCode
				and	ss.ReleaseDT = ft.fn_TruncDate('dd', getdate())
		)
	and ssh.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
	and	c.RawDocumentGUID = ss.RawDocumentGUID
group by
	ssh.RawDocumentGUID
,	bo.BlanketOrderNo
,	bo.ReferenceAccum
,	bo.AdjustmentAccum 
having
	case bo.AdjustmentAccum 
		when 'N' 
			then min(coalesce(convert(int,bo.AccumShipped),0))
		when 'P' 
			then min(coalesce(convert(int,ssaa.PriorCUM),0))
		else min(coalesce(convert(int,ssa.LastAccumQty),0))
	end > 
	case bo.ReferenceAccum 
		when 'N' 
			then min(coalesce(convert(int,bo.AccumShipped),0))
		when 'C' 
			then min(coalesce(convert(int,ssa.LastAccumQty),0))
		else min(coalesce(convert(int,bo.AccumShipped),0))
	end
/*		862s. */
union all
select
distinct
	ReleaseType = 1
,	OrderNo = bo.BlanketOrderNo
,	Type = 1
,	ReleaseDT = dateadd(dd, ReleaseDueDTOffsetDays, ss.ReleaseDT)
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.ShipToCode
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = left(ss.UserDefined1,8)
,	QtyRelease = ss.ReleaseQty
,	StdQtyRelease = ss.ReleaseQty
,	ReferenceAccum =
		case bo.ReferenceAccum 
			when 'N' 
				then coalesce(convert(int,bo.AccumShipped),0)
			when 'C' 
				then coalesce(convert(int,ssa.LastAccumQty),0)
			else coalesce(convert(int,bo.AccumShipped),0)
		end
,	CustomerAccum =
		case bo.AdjustmentAccum 
			when 'N' 
				then coalesce(convert(int,bo.AccumShipped),0)
			when 'P' 
				then coalesce(convert(int,ssaa.PriorCUM),0)
			else coalesce(convert(int,ssa.LastAccumQty),0)
		end
,	NewDocument =
		(	select
				min(c.NewDocument)
			from
				@Current862s c
			where
				c.RawDocumentGUID = ssh.RawDocumentGUID
		)
from
	EDIToyota.ShipScheduleHeaders ssh
	join EDIToyota.ShipSchedules ss
		on ss.RawDocumentGUID = ssh.RawDocumentGUID
	left join EDIToyota.ShipScheduleAccums ssa
		on ssa.RawDocumentGUID = ssh.RawDocumentGUID
		and ssa.CustomerPart = ss.CustomerPart
		and	ssa.ShipToCode = ss.ShipToCode
		and	coalesce(ssa.CustomerPO,'') = coalesce(ss.CustomerPO,'')
		and	coalesce(ssa.CustomerModelYear,'') = coalesce(ss.CustomerModelYear,'')
	left join EDIToyota.ShipScheduleAuthAccums ssaa
		on ssaa.RawDocumentGUID = ssh.RawDocumentGUID
		and ssaa.CustomerPart = ss.CustomerPart
		and	ssaa.ShipToCode = ss.ShipToCode
		and	coalesce(ssaa.CustomerPO,'') = coalesce(ss.CustomerPO,'')
		and	coalesce(ssaa.CustomerModelYear,'') = coalesce(ss.CustomerModelYear,'')
	join EDIToyota.BlanketOrders bo
		on bo.EDIShipToCode = ss.ShipToCode
		and bo.CustomerPart = ss.CustomerPart
		and
		(	bo.CheckCustomerPOShipSchedule = 0
			or bo.CustomerPO = ss.CustomerPO
		)
		and
		(	bo.CheckModelYearShipSchedule = 0
			or bo.ModelYear862 = ss.CustomerModelYear
		)
	join @Current862s c
		on c.CustomerPart = bo.customerpart
		and c.ShipToCode = bo.EDIShipToCode
		and
		(	bo.CheckCustomerPOShipSchedule = 0
			or bo.CustomerPO = c.CustomerPO
		)
		and
		(	bo.CheckModelYearShipSchedule = 0
			or bo.ModelYear862 = c.CustomerModelYear
		)
where
	c.RawDocumentGUID = ss.RawDocumentGUID
	and ssh.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Status', 'Active'))
/*		830s. */
union all
select
	ReleaseType = 2
,	OrderNo = bo.BlanketOrderNo
,	Type =
		case 
			when bo.PlanningFlag = 'P' then 2
			when bo.PlanningFlag = 'F' then 1
			when bo.planningFlag = 'A' and pr.ScheduleType not in ('C', 'A', 'Z') then 2
			else 1
		end
,	ReleaseDT = dateadd(dd, ReleaseDueDTOffsetDays, pr.ReleaseDT)
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.ShipToCode
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = pr.UserDefined1
,	QtyRelease = pr.ReleaseQty
,	StdQtyRelease = pr.ReleaseQty
,	ReferenceAccum =
		case bo.ReferenceAccum 
			when 'N' 
				then coalesce(convert(int,bo.AccumShipped),0)
			when 'C' 
				then coalesce(convert(int,pa.LastAccumQty),0)
			else coalesce(convert(int,bo.AccumShipped),0)
		end
,	CustomerAccum =
		case bo.AdjustmentAccum 
			when 'N' 
				then coalesce(convert(int,bo.AccumShipped),0)
			when 'P' 
				then coalesce(convert(int,paa.PriorCUM),0)
			else coalesce(convert(int,pa.LastAccumQty),0)
		end
,	NewDocument =
		(	select
				min(c.NewDocument)
			from
				@Current830s c
			where
				c.RawDocumentGUID = ph.RawDocumentGUID
		)
from
	EDIToyota.PlanningHeaders ph
	join EDIToyota.PlanningReleases pr
		on pr.RawDocumentGUID = ph.RawDocumentGUID
	left join EDIToyota.PlanningAccums pa
		on pa.RawDocumentGUID = ph.RawDocumentGUID
		and pa.CustomerPart = pr.CustomerPart
		and	pa.ShipToCode = pr.ShipToCode
		and	coalesce(pa.CustomerPO,'') = coalesce(pr.CustomerPO,'')
		and	coalesce(pa.CustomerModelYear,'') = coalesce(pr.CustomerModelYear,'')
	left join EDIToyota.PlanningAuthAccums paa
		on paa.RawDocumentGUID = ph.RawDocumentGUID
		and paa.CustomerPart = pr.CustomerPart
		and	paa.ShipToCode = pr.ShipToCode
		and	coalesce(paa.CustomerPO,'') = coalesce(pr.CustomerPO,'')
		and	coalesce(paa.CustomerModelYear,'') = coalesce(pr.CustomerModelYear,'')
	join EDIToyota.BlanketOrders bo
		on bo.EDIShipToCode = pr.ShipToCode
		and bo.CustomerPart = pr.CustomerPart
		and
		(	bo.CheckCustomerPOPlanning = 0
			or bo.CustomerPO = pr.CustomerPO
		)
		and
		(	bo.CheckModelYearPlanning = 0
			or bo.ModelYear830 = pr.CustomerModelYear
		)
	join
		@Current830s c 
		on c.CustomerPart = bo.customerpart
		and c.ShipToCode = bo.EDIShipToCode
		and
		(	bo.CheckCustomerPOShipSchedule = 0
			or bo.CustomerPO = c.CustomerPO
		)
		and
		(	bo.CheckModelYearShipSchedule = 0
			or bo.ModelYear862 = c.CustomerModelYear
		)
where
	c.RawDocumentGUID = pr.RawDocumentGUID
	and ph.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.PlanningHeaders', 'Status', 'Active'))
	and pr.Status = 1 --(select dbo.udf_StatusValue('EDIToyota.PlanningReleases', 'Status', 'Active'))
	--and coalesce(nullif(pr.Scheduletype,''),'4') in ('4')
order by
	2,1,4

/*		Calculate orders to update. */
update
	rr
set
	NewDocument =
	(	select
			max(NewDocument)
		from
			@RawReleases rr2
		where
			rr2.OrderNo = rr.OrderNo
	)
from
	@RawReleases rr

if	@Testing = 0 begin
	delete
		rr
	from
		@RawReleases rr
	where
		rr.NewDocument = 0
end

/*		Update accums for Orders where Accum Difference has been inserted for immediate delivery */
--update
--	@RawReleases
--set
--	RelPost = CustomerAccum + coalesce (
--	(	select
--			sum (StdQtyRelease)
--		from
--			@RawReleases
--		where
--			OrderNo = rr.OrderNo
--			and Type = rr.Type
--			and	RowID <= rr.RowID), 0)
--from
--	@RawReleases rr

	
--/*		Calculate orders to update. */
--update
--	rr
--set
--	NewDocument =
--	(	select
--			max(NewDocument)
--		from
--			@RawReleases rr2
--		where
--			rr2.OrderNo = rr.OrderNo
--	)
--from
--	@RawReleases rr

--if	@Testing = 0 begin
--	delete
--		rr
--	from
--		@RawReleases rr
--	where
--		rr.NewDocument = 0
--end

update
	@RawReleases
set
	RelPost = CustomerAccum + coalesce (
	(	select
			sum (StdQtyRelease)
		from
			@RawReleases
		where
			OrderNo = rr.OrderNo
			and ReleaseType = rr.ReleaseType
			and	RowID <= rr.RowID), 0)
from
	@RawReleases rr

	
--/*		Calculate orders to update. */
--update
--	rr
--set
--	NewDocument =
--	(	select
--			max(NewDocument)
--		from
--			@RawReleases rr2
--		where
--			rr2.OrderNo = rr.OrderNo
--	)
--from
--	@RawReleases rr

--delete
--	rr
--from
--	@RawReleases rr
--where
--	rr.NewDocument = 0


/*		Calculate running cumulatives. */


update
	rr
set
	RelPost = case when rr.ReferenceAccum > rr.RelPost then rr.ReferenceAccum else rr.RelPost end
from
	@RawReleases rr


update
	rr
set
	RelPrior = coalesce (
	(	select
			max(RelPost)
		from
			@RawReleases
		where
			OrderNo = rr.OrderNo
			and	RowID < rr.RowID), ReferenceAccum)
from
	@RawReleases rr




update
	rr
set
	QtyRelease = RelPost - RelPrior
,	StdQtyRelease = RelPost - RelPrior
from
	@RawReleases rr

update
	rr
set
	Status = -1
from
	@RawReleases rr
where
	QtyRelease <= 0


/* Move Planning Release dates beyond last Ship Schedule Date that has a quantity due*/
update
	rr
set
	ReleaseDT = dateadd(dd,1,(select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and ReleaseType = 1))
from
	@RawReleases rr
where
	rr.ReleaseType = 2
	and rr.ReleaseDT <= (select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and ReleaseType = 1 and Status>-1)

/*	Calculate order line numbers and committed quantity. */
update
	rr
set	Line =
		(	select
				count(*)
			from
				@RawReleases
			where
				OrderNo = rr.OrderNo
				and	RowID <= rr.RowID
				and Status = 0
		)
,	QtyShipper = shipSchedule.qtyRequired
from
	@RawReleases rr
	left join
	(	select
			orderNo = sd.order_no
		,	qtyRequired = sum(qty_required)
		from
			dbo.shipper_detail sd
			join dbo.shipper s
				on s.id = sd.shipper
		where 
			s.type is null
			and s.status in ('O', 'A', 'S')
		group by
			sd.order_no
	) shipSchedule
		on shipSchedule.orderNo = rr.OrderNo
where
	rr.status = 0

--<Debug>
if @Debug & 1 = 1 begin
	print	'	...calculated.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--<Debug>
if @Debug & 1 = 1 begin
	print	'	Replace order detail.'
	set	@StartDT = GetDate ()
end
--</Debug>

if	@Testing = 2 begin
	select
		'@RawReleases'
	
	select
		*
	from
		@RawReleases rr
end

/*		Replace order detail. */
if	@Testing = 0 begin

	if	objectproperty(object_id('dbo.order_detail_deleted'), 'IsTable') is not null begin
		drop table dbo.order_detail_deleted
	end
	select
		*
	into
		dbo.order_detail_deleted
	from
		dbo.order_detail od
	where
		od.order_no in (select OrderNo from @RawReleases)
	order by
		order_no
	,	due_date
	,	sequence
	
	--- <Delete rows="*">
	set	@TableName = 'dbo.order_detail'
	
	delete
		od
	from
		dbo.order_detail od
	where
		od.order_no in (select OrderNo from @RawReleases)
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Delete>
	
	--- <Insert rows="*">
	set	@TableName = 'dbo.order_detail'
	
	insert
		dbo.order_detail
	(	order_no, sequence, part_number, product_name, type, quantity
	,	status, notes, unit, due_date, release_no, destination
	,	customer_part, row_id, flag, ship_type, packline_qty, packaging_type
	,	weight, plant, week_no, std_qty, our_cum, the_cum, price
	,	alternate_price, committed_qty
	)
	select
		order_no = rr.OrderNo
	,	sequence = rr.Line + coalesce((select max (sequence) from order_detail where order_no = rr.OrderNo), 0)
	,	part_number = rr.BlanketPart
	,	product_name = (select name from dbo.part where part = rr.BlanketPart)
	,	type = case rr.Type when 1 then 'F' when 2 then 'P' end
	,	quantity = rr.RelPost - rr.relPrior
	,	status = ''
	,	notes = 'Processed Date : '+ convert(varchar, getdate(), 120) + ' ~ ' + case rr.Type when 1 then 'EDI Processed Release' when 2 then 'EDI Processed Release' end
	,	unit = (select unit from order_header where order_no = rr.OrderNo)
	,	due_date = rr.ReleaseDT
	,	release_no = rr.ReleaseNo
	,	destination = rr.ShipToID
	,	customer_part = rr.CustomerPart
	,	row_id = rr.Line + coalesce((select max (row_id) from order_detail where order_no = rr.OrderNo), 0)
	,	flag = 1
	,	ship_type = 'N'
	,	packline_qty = 0
	,	packaging_type = bo.PackageType
	,	weight = (rr.RelPost - rr.relPrior) * bo.UnitWeight
	,	plant = (select plant from order_header where order_no = rr.OrderNo)
	,	week_no = datediff(wk, (select fiscal_year_begin from parameters), rr.ReleaseDT) + 1
	,	std_qty = rr.RelPost - rr.relPrior
	,	our_cum = rr.RelPrior
	,	the_cum = rr.RelPost
	,	price = (select price from order_header where order_no = rr.OrderNo)
	,	alternate_price = (select alternate_price from order_header where order_no = rr.OrderNo)
	,	committed_qty = coalesce
		(	case
				when rr.QtyShipper > rr.RelPost - bo.AccumShipped then rr.RelPost - rr.relPrior
				when rr.QtyShipper > rr.RelPrior - bo.AccumShipped then rr.QtyShipper - (rr.RelPrior - bo.AccumShipped)
			end
		,	0
		)
	from
		@RawReleases rr
		join EDIToyota.BlanketOrders bo
			on bo.BlanketOrderNo = rr.OrderNo
	where
		rr.Status = 0
	order by
		1, 2
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Insert>
	
	/*	Set dock code, line feed code, and reserve line feed code. */
	--- <Update rows="*">
	set	@TableName = 'dbo.order_header'
		
	update
		oh
	set
		custom01 = rtrim(prs.UserDefined1)
	,	dock_code = rtrim(prs.UserDefined1)
	,	line_feed_code = rtrim(prs.UserDefined2)
	,	zone_code = rtrim(prs.UserDefined3)

	from
		dbo.order_header oh
		join EDIToyota.blanketOrders bo
			on bo.BlanketOrderNo = oh.order_no
		join @Current830s c
			on c.CustomerPart = bo.customerpart
			and c.ShipToCode = bo.EDIShipToCode
			and
			(	bo.CheckCustomerPOPlanning = 0
				or bo.CustomerPO = c.CustomerPO
			)
			and
			(	bo.CheckModelYearPlanning = 0
				or bo.ModelYear830 = c.CustomerModelYear
			)
		join EDIToyota.PlanningSupplemental prs
			on prs.RawDocumentGUID = c.RawDocumentGUID
			and prs.CustomerPart = c.CustomerPart
			and coalesce(prs.CustomerPO, '') = c.CustomerPO
			and prs.CustomerModelYear = c.CustomerModelYear
			and prs.ShipToCode = c.ShipToCode
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
		
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
		
	--- <Update rows="*">
	set	@TableName = 'dbo.order_header'
		
	update
		oh
	set
		custom01 = rtrim(sss.UserDefined1)
	,	dock_code = rtrim(sss.UserDefined1)
	,	line_feed_code = rtrim(sss.UserDefined2)
	,	zone_code = rtrim(sss.UserDefined3)
	,	line11 = rtrim(sss.UserDefined11)
	,	line12 = rtrim(sss.UserDefined12)
	,	line13 = rtrim(sss.UserDefined13)
	,	line14 = rtrim(sss.UserDefined14)
	,	line15 = rtrim(sss.UserDefined15)
	,	line16 = rtrim(sss.UserDefined16)
	,	line17 = rtrim(sss.UserDefined17)
	from
		dbo.order_header oh
		join EDIToyota.blanketOrders bo
			on bo.BlanketOrderNo = oh.order_no
		join @Current862s c
			on c.CustomerPart = bo.customerpart
			and c.ShipToCode = bo.EDIShipToCode
			and
			(	bo.CheckCustomerPOShipSchedule = 0
				or bo.CustomerPO = c.CustomerPO
			)
			and
			(	bo.CheckModelYearShipSchedule = 0
				or bo.ModelYear862 = c.CustomerModelYear
			)
		join EDIToyota.ShipScheduleSupplemental sss
			on sss.RawDocumentGUID = c.RawDocumentGUID
			and sss.CustomerPart = c.CustomerPart
			and coalesce(sss.CustomerPO, '') = c.CustomerPO
			and sss.CustomerModelYear = c.CustomerModelYear
			and sss.ShipToCode = c.ShipToCode
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
		
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Update>
end
else begin
	if	@Testing > 1 begin
		select 'raw releases'
		
		select
			Type
		,	OrderNo
		,	BlanketPart
		,	CustomerPart
		,	ShipToID
		,	CustomerPO
		,	ModelYear
		,	OrderUnit
		,	QtyShipper
		,	Line
		,	ReleaseNo
		,	QtyRelease
		,	StdQtyRelease
		,	ReferenceAccum
		,	RelPrior
		,	RelPost
		,	ReleaseDT
		from
			@RawReleases
		order by
			OrderNo
		,	RowID
		
		select 'to be deleted'

		select
			od.*
		from
			dbo.order_detail od
		where
			od.order_no in (select OrderNo from @RawReleases)
		order by
			order_no
		,	due_date
		
		/*	to be inserted*/
		
		select 'to be inserted'
	end
		
	select
		order_no = rr.OrderNo
	,	sequence = rr.Line
	,	part_number = rr.BlanketPart
	,	product_name = (select name from dbo.part where part = rr.BlanketPart)
	,	type = case rr.Type when 1 then 'F' when 2 then 'P' end
	,	quantity = rr.RelPost - rr.relPrior
	,	status = ''
	,	notes = 'Processed Date : '+ convert(varchar, getdate(), 120) + ' ~ ' + case rr.Type when 1 then 'EDI Processed Release' when 2 then 'EDI Processed Release' end
	,	unit = (select unit from order_header where order_no = rr.OrderNo)
	,	due_date = rr.ReleaseDT
	,	release_no = rr.ReleaseNo
	,	destination = rr.ShipToID
	,	customer_part = rr.CustomerPart
	,	row_id = rr.Line
	,	flag = 1
	,	ship_type = 'N'
	,	packline_qty = 0
	,	packaging_type = bo.PackageType
	,	weight = (rr.RelPost - rr.relPrior) * bo.UnitWeight
	,	plant = (select plant from order_header where order_no = rr.OrderNo)
	,	week_no = datediff(wk, (select fiscal_year_begin from parameters), rr.ReleaseDT) + 1
	,	std_qty = rr.RelPost - rr.relPrior
	,	our_cum = rr.RelPrior
	,	the_cum = rr.RelPost
	,	price = (select price from order_header where order_no = rr.OrderNo)
	,	alternate_price = (select alternate_price from order_header where order_no = rr.OrderNo)
	,	committed_qty = coalesce
		(	case
				when rr.QtyShipper > rr.RelPost - bo.AccumShipped then rr.RelPost - rr.relPrior
				when rr.QtyShipper > rr.RelPrior - bo.AccumShipped then rr.QtyShipper - (rr.RelPrior - bo.AccumShipped)
			end
		,	0
		)
	from
		@RawReleases rr
		join EDIToyota.BlanketOrders bo
			on bo.BlanketOrderNo = rr.OrderNo
	order by
		1, 2
end
--<Debug>
if @Debug & 1 = 1 begin
	print	'	...replaced.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>
--- </Body>

--<Debug>
if @Debug & 1 = 1 begin
	print	'FINISHED.   ' + Convert (varchar, DateDiff (ms, @ProcStartDT, GetDate ())) + ' ms'
end
--</Debug>

--- <Closetran AutoRollback=Yes>
if	@TranCount = 0 begin
	rollback tran @ProcName
end
--- </Closetran>

/* Start E-Mail Alerts and Exceptions*/
select
	*
into
	#current862s
from
	@current862s

select
	*
into
	#current830s
from
	@current830s

--- <Call>	
set	@CallProcName = 'EDIToyota.usp_SendProcessEmailNotification'
execute
	@ProcReturn = EDIToyota.usp_SendProcessEmailNotification
		@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

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

begin transaction
go

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDIToyota.usp_Process
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Testing = 0


set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go


go

commit transaction
--rollback transaction

go

set statistics io off
set statistics time off
go

}

Results {
}
*/


















































GO
