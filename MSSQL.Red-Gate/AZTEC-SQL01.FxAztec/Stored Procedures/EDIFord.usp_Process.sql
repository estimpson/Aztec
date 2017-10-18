SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [EDIFord].[usp_Process]
--modified update statement on order header from 862 data so that trading partner like 'AF52M' would not update order header Andre 2014-10-23 
--modified update statement on order header from 830 data so that trading partner like 'AF52M' updates order header with IC Andre 2015-03-19 

	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
,	@Testing INT = 1
--<Debug>
,	@Debug INTEGER = 0
--</Debug>
AS
set nocount on
set ansi_warnings on
set	@Result = 999999

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	set	@StartDT = GetDate ()
	print	'START.   ' + Convert (varchar (50), @StartDT)
	SET	@ProcStartDT = GETDATE ()
END
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIFORD.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
ELSE BEGIN
	SAVE TRAN @ProcName
END
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
--<Debug>
if @Debug & 1 = 1 begin
	print	'Determine the current 830s and 862s.'
	print	'	Active are all 862s for a Ship To / Ship From / last Document DT / last Imported Version (for Document Number / Control Number).'
	SET	@StartDT = GETDATE ()
END
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
	EDIFORD.CurrentShipSchedules ()

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
	EDIFORD.CurrentPlanningReleases ()

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
	RETURN
END

--<Debug>
if @Debug & 1 = 1 begin
	print	'Mark "Active" 862s and 830s.'
	SET	@StartDT = GETDATE ()
END
--- <Update rows="*">
set	@TableName = 'EDIFORD.SchipSchedules'

update
	ss
set
	Status =
		case
			when c.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDIFORD.ShipSchedules', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDIFORD.ShipSchedules', 'Status', 'Replaced'))
		end
from
	EDIFORD.ShipSchedules ss
	left join @Current862s c
		on ss.RawDocumentGUID = c.RawDocumentGUID
		and ss.ShipToCode = c.ShipToCode
		and ss.ShipFromCode = c.ShipFromCode
		and ss.CustomerPart = c.CustomerPart
		and coalesce(ss.CustomerPO, '') = coalesce(c.CustomerPO, '')
		and coalesce(ss.CustomerModelYear, '') = coalesce(c.CustomerModelYear, '')
where
	ss.Status in
	(	0 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIFORD.ShipScheduleHeaders'

update
	ssh
set
	Status =
	case
		when exists
			(	select
					*
				from
					EDIFORD.ShipSchedules ss
				where
					ss.RawDocumentGUID = ssh.RawDocumentGUID
					and ss.Status = 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active')
			) then 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Active'))
		else 2 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Replaced'))
	end
from
	EDIFORD.ShipScheduleHeaders ssh
where
	ssh.Status in
	(	0 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
--- </Update>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...marked.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--- <Update rows="*">
set	@TableName = 'EDIFORD.PlanningReleases'

update
	PR
set
	Status =
		case
			when c.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Replaced'))
		end
from
	EDIFORD.PlanningReleases PR
	left join @Current830s c
		on PR.RawDocumentGUID = c.RawDocumentGUID
		and PR.ShipToCode = c.ShipToCode
		and PR.ShipFromCode = c.ShipFromCode
		and PR.CustomerPart = c.CustomerPart
		and coalesce(PR.CustomerPO, '') = coalesce(c.CustomerPO, '')
		and coalesce(PR.CustomerModelYear, '') = coalesce(c.CustomerModelYear, '')

where
	PR.Status in
	(	0 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
--- </Update>

--- <Update rows="*">
set	@TableName = 'EDIFORD.PlanningHeaders'

update
	fh
set
	Status =
	case
		when exists
			(	select
					*
				from
					EDIFORD.PlanningReleases fr
				where
					fr.RawDocumentGUID = fh.RawDocumentGUID
					and fr.Status = 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active')
			) then 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Active'))
		else 2 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Replaced'))
	end
from
	EDIFORD.PlanningHeaders fh
where
	fh.Status in
	(	0 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Active'))
	)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	RETURN
END
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
		EDIFORD.ShipScheduleHeaders fh

	select
		'PlanningHeaders'
		
	SELECT
		*
	FROM
		EDIFORD.PlanningHeaders fh
END

--<Debug>
if @Debug & 1 = 1 begin
	print	'Write new releases.'
	print	'	Calculate raw releases from active 862s and 830s.'
	SET	@StartDT = GETDATE ()
END
--</Debug>
/*	Write new releases. */
/*		Calculate raw releases from active 862s and 830s. */
declare
	@RawReleases table
(	RowID int not null IDENTITY(1, 1) primary key
,	Status int default(0)
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
(	OrderNo
,	Type
,	ReleaseDT
,	BlanketPart
,	CustomerPart
,	ShipToID
,	CustomerPO
,	ModelYear
,	OrderUnit
,	ReleaseNo
,	RelPost
,	ReferenceAccum
,	NewDocument
)

Select
	OrderNo = bo.BlanketOrderNo
,	Type = 1
,	ReleaseDT = dateadd(dd, ReleaseDueDTOffsetDays, fr.ReleaseDT)
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.ShipToCode
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = fr.ReleaseNo
,   RelPost = fr.ReleaseQty
,	ReferenceAccum = case bo.ReferenceAccum 
												When 'N' 
												then coalesce(convert(int,bo.AccumShipped),0)
												When 'C' 
												then coalesce(convert(int,fa.LastAccumQty),0)
												else coalesce(convert(int,bo.AccumShipped),0)
												end

	,	(	select
				min(c.NewDocument)
			from
				@Current862s c
			where
				c.RawDocumentGUID = fh.RawDocumentGUID
		)
from
	EDIFORD.ShipScheduleHeaders fh
	join EDIFORD.ShipSchedules fr
		on fr.RawDocumentGUID = fh.RawDocumentGUID
	left join EDIFORD.ShipScheduleAccums fa
		on fa.RawDocumentGUID = fh.RawDocumentGUID
		and fa.CustomerPart = fr.CustomerPart
		and	fa.ShipToCode = fr.ShipToCode
		and	fa.ShipFromCode = fr.ShipFromCode
		and	coalesce(fa.CustomerPO,'') = coalesce(fr.CustomerPO,'')
		and	coalesce(fa.CustomerModelYear,'') = coalesce(fr.CustomerModelYear,'')
	left join EDIFORD.ShipScheduleAuthAccums faa
		on faa.RawDocumentGUID = fh.RawDocumentGUID
		and faa.CustomerPart = fr.CustomerPart
		and	faa.ShipToCode = fr.ShipToCode
		and	faa.ShipFromCode = fr.ShipFromCode
		and	coalesce(faa.CustomerPO,'') = coalesce(fr.CustomerPO,'')
		and	coalesce(faa.CustomerModelYear,'') = coalesce(fr.CustomerModelYear,'')
	join EDIFORD.BlanketOrders bo
		on bo.EDIShipToCode = fr.ShipToCode
		and bo.CustomerPart = fr.CustomerPart
		AND bo.SupplierCode = fr.ShipFromCode
		and
		(	bo.CheckCustomerPOShipSchedule = 0
			or bo.CustomerPO = fr.CustomerPO
		)
		and
		(	bo.CheckModelYearShipSchedule = 0
			or bo.ModelYear862 = fr.CustomerModelYear
		)
		join
				(Select * From @Current862s) c 
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
				c.RawDocumentGUID = fr.RawDocumentGUID
and	fh.Status = 1 --(select dbo.udf_StatusValue('EDIFORD.ShipScheduleHeaders', 'Status', 'Active'))
		

/*		830s. */
Union all
select
	OrderNo = bo.BlanketOrderNo
,	Type = (	case 
					when bo.PlanningFlag = 'P' then 2
					when bo.PlanningFlag = 'F' then 1
					when bo.planningFlag = 'A' and fr.ScheduleType = 'D' then 2
					else 1
					end
			  )
,	ReleaseDT = dateadd(dd, ReleaseDueDTOffsetDays, fr.ReleaseDT)
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.ShipToCode
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = fr.ReleaseNo
, RelPost = fr.ReleaseQty
,	ReferenceAccum = case bo.ReferenceAccum 
												When 'N' 
												then coalesce(convert(int,bo.AccumShipped),0)
												When 'C' 
												then coalesce(convert(int,fa.LastAccumQty),0)
												else coalesce(convert(int,bo.AccumShipped),0)
												end
,	NewDocument =
		(	select
				min(c.NewDocument)
			from
				@Current830s c
			where
				c.RawDocumentGUID = fh.RawDocumentGUID
		)
from
	EDIFORD.PlanningHeaders fh
	join EDIFORD.PlanningReleases fr
		on fr.RawDocumentGUID = fh.RawDocumentGUID
	left join EDIFORD.PlanningAccums fa
		on fa.RawDocumentGUID = fh.RawDocumentGUID
		and fa.CustomerPart = fr.CustomerPart
		and	fa.ShipToCode = fr.ShipToCode
		and	fa.ShipFromCode = fr.ShipFromCode
		and	coalesce(fa.CustomerPO,'') = coalesce(fr.CustomerPO,'')
		and	coalesce(fa.CustomerModelYear,'') = coalesce(fr.CustomerModelYear,'')
	left join EDIFORD.PlanningAuthAccums faa
		on faa.RawDocumentGUID = fh.RawDocumentGUID
		and faa.CustomerPart = fr.CustomerPart
		and	faa.ShipToCode = fr.ShipToCode
		and	faa.ShipFromCode = fr.ShipFromCode
		and	coalesce(faa.CustomerPO,'') = coalesce(fr.CustomerPO,'')
		and	coalesce(faa.CustomerModelYear,'') = coalesce(fr.CustomerModelYear,'')
	join EDIFORD.BlanketOrders bo
		on bo.EDIShipToCode = fr.ShipToCode
		and bo.CustomerPart = fr.CustomerPart
		and bo.SupplierCode = fr.ShipFromCode
		and
		(	bo.CheckCustomerPOPlanning = 0
			or bo.CustomerPO = fr.CustomerPO
		)
		and
		(	bo.CheckModelYearPlanning = 0
			or bo.ModelYear830 = fr.CustomerModelYear
		)
		join
				(Select * From @Current830s) c 
			on
				c.CustomerPart = bo.customerpart AND
                c.ShipFromCode = bo.SupplierCode and
				c.ShipToCode = bo.EDIShipToCode and
				(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = c.CustomerPO
				)
					and	(	bo.CheckModelYearplanning = 0
							or bo.ModelYear830= c.CustomerModelYear
				)
where
				c.RawDocumentGUID = fr.RawDocumentGUID
	and	fh.Status = 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningHeaders', 'Status', 'Active'))
	and		fr.Status = 1 --(select dbo.udf_StatusValue('EDIFORD.PlanningReleases', 'Status', 'Active'))
	--and coalesce(nullif(fr.Scheduletype,''),'4') in ('4')
	
order by
	1, 2, 3

/*		Calculate orders to update. */
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

delete
	rr
from
	@RawReleases rr
where
	rr.NewDocument = 0

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

		--For Armada Only..Update Release Number with Accum Increase if customer's accum causes the qty to be increased
	update
	rr
set
		releaseNo = 'Accum Increase'
from
	@RawReleases rr
where
		RelPost-RelPrior > QtyRelease


update
	rr
set
	QtyRelease = RelPost - RelPrior
,	StdQtyRelease = RelPost - RelPrior
from
	@RawReleases rr

if	@Testing = 2 begin
	select
		'@RawReleases'
	
	SELECT
		*
	FROM
		@RawReleases rr
END

update
	rr
set
	Status = -1
from
	@RawReleases rr
where
	QtyRelease <= 0

	update
	rr
set
	ReleaseDT = dateadd(dd,1,(select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and Type = 1and Status>-1))
from
	@RawReleases rr
where
	rr.Type = 2
	and rr.ReleaseDT <= (select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and Type = 1 and Status>-1)

/*	Calculate order line numbers. */
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
			and StdQtyRelease > 0)
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


--<Debug>
if @Debug & 1 = 1 begin
	print	'	...calculated.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--<Debug>
if @Debug & 1 = 1 begin
	print	'	Replace order detail.'
	SET	@StartDT = GETDATE ()
END
--</Debug>

if	@Testing = 2 begin
	select
		'@RawReleases'
	
	SELECT
		*
	FROM
		@RawReleases rr
END

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
		RETURN
	END
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
		join EDIFORD.BlanketOrders bo
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
		RETURN
	END
	--- </Insert>
	
	/*	Set dock code, line feed code, and reserve line feed code. */
	/*if  exists
		(	select
				*
			from
				dbo.order_header oh
				join EDIFORD.PlanningHeaders fh
					join EDIFORD.PlanningSupplemental ps
						on ps.RawDocumentGUID = fh.RawDocumentGUID
					join EDIFORD.BlanketOrders bo
						on bo.EDIShipToCode = coalesce (ps.ConsigneeCode, ps.ShipToCode)
						and bo.CustomerPart = ps.CustomerPart
					on bo.BlanketOrderNo = oh.order_no
				join @Current830s c
					on ps.RawDocumentGUID = c.RawDocumentGUID
					and ps.ShipToCode = c.ShipToCode
					and coalesce(ps.ShipFromCode,'') = coalesce(c.ShipFromCode,'')
					and coalesce(ps.ConsigneeCode, '') = coalesce(c.ConsigneeCode, '')
					and ps.CustomerPart = c.CustomerPart
			where 
				coalesce(oh.dock_code,'') != coalesce(ps.UserDefined1, '')
				or coalesce(oh.line_feed_code,'') != coalesce(ps.UserDefined2,'')
				or coalesce(oh.zone_code,'') != coalesce(ps.UserDefined3,'')
		) or
		exists
		(	select
				*
			from
				dbo.order_header oh
				join EDIFORD.ShipScheduleHeaders fh
					join EDIFORD.ShipScheduleSupplemental sss
						on sss.RawDocumentGUID = fh.RawDocumentGUID
					join EDIFORD.BlanketOrders bo
						on bo.EDIShipToCode = sss.ShipToCode
						and bo.CustomerPart = sss.CustomerPart
					on bo.BlanketOrderNo = oh.order_no
				join @Current862s c
					on sss.RawDocumentGUID = c.RawDocumentGUID
					and sss.ShipToCode = c.ShipToCode
					and sss.CustomerPart = c.CustomerPart
			where 
				coalesce(oh.dock_code,'') != coalesce(sss.UserDefined1, '')
				or coalesce(oh.line_feed_code,'') != coalesce(sss.UserDefined2,'')
				or coalesce(oh.zone_code,'') != coalesce(sss.UserDefined3,'')
		) begin
		*/
		/*
		insert
			EDIFORD.LabelInfoHeader
		(	SystemDT
		)
		select
			@TranDT
		
		insert 	
			EDIFORD.LabelInfoHeader
		(	HeaderTimeStamp
		,	OrderNo
		,	NewDockCode
		,	OldDockCode
		,	NewLineFeed
		,	OldLineFeed
		,	NewReserveLineFeed
		,	OldReserveLineFeed
		)
		select
			HeaderTimeStamp
		,	rr.OrderNo
		,	rr.DockCode
		,	oh.dock_code
		,	rr.LineFeedCode
		,	oh.line_feed_code
		,	rr.ReserveLineFeedCode
		,	oh.zone_code
		from
			dbo.order_header oh
			join @RawReleases rr
				on rr.OrderNo = oh.order_no
				   and rr.RowID =
				   (	select
							min(rr2.RowID)
						from
							@RawReleases rr2
						where
							rr2.OrderNo = oh.order_no
							and rr2.Type = 1
					)
			cross join
			(	select
					convert(int,@@DBTS) as HeaderTimeStamp
			) HeaderTimeStamp
		where
			coalesce(oh.dock_code,'') != coalesce(rr.DockCode,'')
			or coalesce(oh.line_feed_code,'') != coalesce(rr.LineFeedCode,'')
			or coalesce(oh.zone_code,'') != coalesce(rr.ReserveLineFeedCode,'')
		*/
		
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
		join
				EDIFORD.blanketOrders bo
		on
				bo.BlanketOrderNo = oh.order_no
		join
				(Select * From @Current830s) cpr 
			on
				cpr.CustomerPart = bo.customerpart and
				cpr.ShipToCode = bo.EDIShipToCode AND
                cpr.ShipFromCode = bo.SupplierCode AND
				(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = cpr.CustomerPO
				)
					and	(	bo.CheckModelYearPlanning= 0
							or bo.ModelYear830 = cpr.CustomerModelYear
				)
		  join
				EDIFORD.PlanningSupplemental prs
		on
				prs.RawDocumentGUID = cpr.RawDocumentGUID and
				prs.CustomerPart = cpr.CustomerPart and
				coalesce(prs.CustomerPO,'') = cpr.CustomerPO and
				prs.CustomerModelYear = cpr.CustomerModelYear  and
				prs.ShipToCode = cpr.ShipToCode and
				prs.ShipFromCode = cpr.ShipFromCode

--Added 3-19-2015 Andre S. Boulanger to allow for new Af52M data structure
update
			oh
		set
			
			dock_code = rtrim(cpr.ConsigneeCode)
	 

		from
			dbo.order_header oh
		join
				EDIFORD.blanketOrders bo
		on
				bo.BlanketOrderNo = oh.order_no
		join
				(Select * From @Current830s) cpr 
			on
				cpr.CustomerPart = bo.customerpart and
				cpr.ShipToCode = bo.EDIShipToCode AND
                cpr.ShipFromCode = bo.SupplierCode and
				(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = cpr.CustomerPO
				)
					and	(	bo.CheckModelYearPlanning= 0
							or bo.ModelYear830 = cpr.CustomerModelYear
				)
		  
		JOIN
			EDIFord.PlanningHeaders ph ON ph.RawDocumentGUID = cpr.RawDocumentGUID
		WHERE
			ph.TradingPartner LIKE '%AF52M%'
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			RETURN
		END
		
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
		JOIN
			edi_setups es ON es.destination = oh.destination
		join
				EDIFORD.blanketOrders bo
		on
				bo.BlanketOrderNo = oh.order_no
		join
				(Select * From @Current862s) css 
			on
				css.CustomerPart = bo.customerpart and
				css.ShipToCode = bo.EDIShipToCode AND
                css.ShipFromCode = bo.SupplierCode and
				(	bo.CheckCustomerPOShipSchedule = 0
							or bo.CustomerPO = css.CustomerPO
				)
					and	(	bo.CheckModelYearShipSchedule = 0
							or bo.ModelYear862 = css.CustomerModelYear
				)
		  join
				EDIFORD.ShipScheduleSupplemental sss
		on
				sss.RawDocumentGUID = css.RawDocumentGUID and
				sss.CustomerPart = css.CustomerPart and
				coalesce(sss.CustomerPO,'') = css.CustomerPO and
				sss.CustomerModelYear = css.CustomerModelYear  and
				sss.ShipToCode = css.ShipToCode AND
                sss.ShipFromCode = css.ShipFromCode
		WHERE es.trading_partner_code NOT LIKE '%AF52M%'
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			RETURN
		END
	

					/* Custom For Armada Rubber*/

		/*				update
			oh
		set	
		custom01 = c.ConsigneeCode,
		location = left(oh.destination,5)+c.ConsigneeCode
		from
			dbo.order_header oh
		join
				EDIFORD.blanketOrders bo
		on
				bo.BlanketOrderNo = oh.order_no
		join
				(Select * From @Current830s) cpr 
			on
				cpr.CustomerPart = bo.customerpart and
				cpr.ShipToCode = bo.EDIShipToCode and
				(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = cpr.CustomerPO
				)
					and	(	bo.CheckModelYearPlanning= 0
							or bo.ModelYear830 = cpr.CustomerModelYear
				)
		  join
				EDIFORD.PlanningSupplemental prs
		on
				prs.RawDocumentGUID = cpr.RawDocumentGUID and
				prs.CustomerPart = cpr.CustomerPart and
				coalesce(prs.CustomerPO,'') = cpr.CustomerPO and
				prs.CustomerModelYear = cpr.CustomerModelYear  and
				prs.ShipToCode = cpr.ShipToCode
	*/
	/*update
			oh
		set	
		custom01 = c.ConsigneeCode,
		location = left(oh.destination,5)+c.ConsigneeCode
		from
			dbo.order_header oh
			join 
				EDIFORD.ShipScheduleHeaders fh
			join 
				EDIFORD.ShipSchedules ps on ps.RawDocumentGUID = fh.RawDocumentGUID
			join 
				EDIFORD.BlanketOrders bo	on bo.EDIShipToCode =  ps.ShipToCode
					and bo.CustomerPart = ps.CustomerPart
					and	(	bo.CheckCustomerPOPlanning = 0
							or bo.CustomerPO = ps.CustomerPO
						)
					and	(	bo.CheckModelYearPlanning = 0
							or bo.ModelYear = ps.CustomerModelYear
						)
				on	bo.BlanketOrderNo = oh.order_no
			join 
				@Current862s c on ps.RawDocumentGUID = c.RawDocumentGUID
				and ps.ShipToCode = c.ShipToCode
				
				and ps.CustomerPart = c.CustomerPart
				and	(	bo.CheckCustomerPOPlanning = 0
						or bo.CustomerPO = c.CustomerPO
					)
				and	(	bo.CheckModelYearPlanning = 0
						or bo.ModelYear = c.CustomerModelYear
					)
*/

				/* End Custom For Armada Rubber	*/
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			RETURN
		END
		
	
		IF	@Error != 0 BEGIN
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			RETURN
		END
	END
	--- </Update>
--end
ELSE BEGIN
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
		
		SELECT 'to be inserted'
	END
		
	SELECT
		order_no = rr.OrderNo
	,	sequence = rr.Line
	,	part_number = rr.BlanketPart
	,	product_name = (SELECT name FROM dbo.part WHERE part = rr.BlanketPart)
	,	type = CASE rr.Type WHEN 1 THEN 'F' WHEN 2 THEN 'P' END
	,	quantity = rr.RelPost - rr.relPrior
	,	status = ''
	,	notes = 'Processed Date : '+ CONVERT(VARCHAR, GETDATE(), 120) + ' ~ ' + CASE rr.Type WHEN 1 THEN 'EDI Processed Release' WHEN 2 THEN 'EDI Processed Release' END
	,	unit = (SELECT unit FROM order_header WHERE order_no = rr.OrderNo)
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
	,	plant = (SELECT plant FROM order_header WHERE order_no = rr.OrderNo)
	,	week_no = DATEDIFF(wk, (SELECT fiscal_year_begin FROM parameters), rr.ReleaseDT) + 1
	,	std_qty = rr.RelPost - rr.relPrior
	,	our_cum = rr.RelPrior
	,	the_cum = rr.RelPost
	,	price = (SELECT price FROM order_header WHERE order_no = rr.OrderNo)
	,	alternate_price = (SELECT alternate_price FROM order_header WHERE order_no = rr.OrderNo)
	,	committed_qty = COALESCE
		(	CASE
				WHEN rr.QtyShipper > rr.RelPost - bo.AccumShipped THEN rr.RelPost - rr.relPrior
				WHEN rr.QtyShipper > rr.RelPrior - bo.AccumShipped THEN rr.QtyShipper - (rr.RelPrior - bo.AccumShipped)
			END
		,	0
		)
	FROM
		@RawReleases rr
		JOIN EDIFORD.BlanketOrders bo
			ON bo.BlanketOrderNo = rr.OrderNo
	ORDER BY
		1, 2
END
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

---	<Return>
--if	@Testing != 0
--	and @@trancount > 0 begin
--	rollback tran @ProcName
--end
/* Start E-Mail Alerts and Exceptions*/

Declare @EDIOrdersAlert table (
	TradingPartner varchar(30) NULL,
	DocumentType varchar(30) NULL, --'PR - Planning Release; SS - ShipSchedule'
	AlertType varchar(100) NULL,
	ReleaseNo varchar(100) NULL,
	ShipToCode varchar(100) NULL,
	ConsigneeCode varchar(100) NULL,
	ShipFromCode varchar(100) NULL,
	CustomerPart varchar(100) NULL,
	CustomerPO varchar(100) NULL,
	CustomerModelYear varchar NULL,
	Description varchar (max)
	)
		
insert	
	@EDIOrdersAlert
(	TradingPartner,
	DocumentType,
	AlertType,
	ReleaseNo ,
	ShipToCode,
	ConsigneeCode,
	ShipFromCode,
	CustomerPart,
	CustomerPO,
	CustomerModelYear,
	Description 
)

Select
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  ' Exception'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'Please Add Blanket Order to Fx and Reprocess EDI'
from
	@Current862s a
Where
		coalesce(a.newDocument,0) = 1
and not exists
( Select 1 from 
		EDIFord.ShipSchedules b
 Join 
	EDIFord.BlanketOrders bo on b.CustomerPart = bo.CustomerPart
and
	b.ShipToCode = bo.EDIShipToCode
and
	b.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = b.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = b.CustomerModelYear)
where
				a.RawDocumentGUID = b.RawDocumentGUID and
				a.CustomerPart = b.CustomerPart and
				a.ShipToCode = b.ShipToCode AND
                a.ShipFromCode = b.ShipFromCode and
				coalesce(a.customerPO,'') = coalesce(b.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(b.CustomerModelYear,'')
)
union
Select
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'PR'
,	AlertType =  ' Exception'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'Please Add Blanket Order to Fx and Reprocess EDI'
from
	@Current830s a
Where
		coalesce(a.newDocument,0) = 1
and not exists
( Select 1 from 
		EDIFord.PlanningReleases b
 Join 
	EDIFord.BlanketOrders bo on b.CustomerPart = bo.CustomerPart
and
	b.ShipToCode = bo.EDIShipToCode
and
	b.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOPlanning = 0
	or bo.CustomerPO = b.CustomerPO)
and
(	bo.CheckModelYearPlanning = 0
	or bo.ModelYear830 = b.CustomerModelYear)
where
				a.RawDocumentGUID = b.RawDocumentGUID and
				a.CustomerPart = b.CustomerPart and
				a.ShipToCode = b.ShipToCode AND
                a.ShipFromCode = b.ShipFromCode and
				coalesce(a.customerPO,'') = coalesce(b.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(b.CustomerModelYear,'')
)
union

--Orders Processed
Select 
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  ' OrderProcessed'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'EDI Processed for Fx Blanket Sales Order No: ' + convert(varchar(15), bo.BlanketOrderNo)
from
	@Current862s a
	 Join 
	EDIFord.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
and
	a.ShipToCode = bo.EDIShipToCode
and
	a.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = a.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = a.CustomerModelYear)
	Where
		coalesce(a.newDocument,0) = 1 

union
Select 
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'PR'
,	AlertType =  ' OrderProcessed'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'EDI Processed for Fx Blanket Sales Order No: ' + convert(varchar(15), bo.BlanketOrderNo)
from
	@Current830s a
	 Join 
	EDIFord.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
and
	a.ShipToCode = bo.EDIShipToCode
and
	a.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOPlanning = 0
	or bo.CustomerPO = a.CustomerPO)
and
(	bo.CheckModelYearPlanning = 0
	or bo.ModelYear830 = a.CustomerModelYear)
	Where
		coalesce(a.newDocument,0) = 1

--Accums Reporting
union
Select 
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  ' Accum Notice'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'Customer Accum Received != Fx Accum Shipped for BlanketOrder No ' 
					+ convert(varchar(15), bo.BlanketOrderNo) 
					+ '  Customer Accum: ' 
					+ convert(varchar(15), coalesce(ssa.LastAccumQty,0))
					+ '  Our Accum Shipped: '
					+ convert(varchar(15), coalesce(bo.AccumShipped,0))
					+ '  Customer Last Recvd Qty: ' 
					+ convert(varchar(15), coalesce(ssa.LastQtyReceived,0))
					+ '  Our Last Shipped Qty: '
					+ convert(varchar(15), coalesce(bo.LastShipQty,0))
					+ '  Customer Prior Auth Accum: ' 
					+ convert(varchar(15), coalesce(ssaa.PriorCUM,0))
from
	@Current862s a
	 Join 
	EDIFord.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
and
	a.ShipToCode = bo.EDIShipToCode
and
	a.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = a.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = a.CustomerModelYear)
	left join
		EDIFord.ShipScheduleAccums ssa on 
		ssa.RawDocumentGUID = a.RawDocumentGUID and
		ssa.ShipToCode = a.ShipToCode AND
        ssa.ShipFromCode = a.ShipFromCode and
		ssa.CustomerPart = a.CustomerPart and
		coalesce(ssa.CustomerPO,'') = coalesce(a.customerPO,'') and
		coalesce(ssa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
 	left join
		EDIFord.ShipScheduleAuthAccums ssaa on 
		ssaa.RawDocumentGUID = a.RawDocumentGUID and
		ssaa.ShipToCode = a.ShipToCode AND
        ssaa.ShipFromCode = a.ShipFromCode and
		ssaa.CustomerPart = a.CustomerPart and
		coalesce(ssaa.CustomerPO,'') = coalesce(a.customerPO,'') and
		coalesce(ssaa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
										
	Where
		coalesce(a.newDocument,0) = 1 and
		coalesce(bo.AccumShipped,0) != coalesce(ssa.LastAccumQty,0)


union
Select 
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'PR'
,	AlertType =  ' Accum Notice'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'Customer Accum Received != Fx Accum Shipped for BlanketOrder No ' 
					+ convert(varchar(15), bo.BlanketOrderNo) 
					+ '  Customer Accum: ' 
					+ convert(varchar(15), coalesce(pra.LastAccumQty,0))
					+ '  Our Accum Shipped: '
					+ convert(varchar(15), coalesce(bo.AccumShipped,0))
					+ '  Customer Last Recvd Qty: ' 
					+ convert(varchar(15), coalesce(pra.LastQtyReceived,0))
					+ '  Our Last Shipped Qty: '
					+ convert(varchar(15), coalesce(bo.LastShipQty,0))
					+ '  Customer Prior Auth Accum: ' 
					+ convert(varchar(15), coalesce(praa.PriorCUM,0))
from
	@Current830s  a
	 Join 
	EDIFord.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
and
	a.ShipToCode = bo.EDIShipToCode
and
	a.ShipFromCode = bo.SupplierCode
and
(	bo.CheckCustomerPOPlanning = 0
	or bo.CustomerPO = a.CustomerPO)
and
(	bo.CheckModelYearPlanning = 0
	or bo.ModelYear830 = a.CustomerModelYear)
	left join
		EDIFord.PlanningAccums pra on 
		pra.RawDocumentGUID = a.RawDocumentGUID and
		pra.ShipToCode = a.ShipToCode AND
        pra.ShipFromCode = a.ShipFromCode and
		pra.CustomerPart = a.CustomerPart and
		coalesce(pra.CustomerPO,'') = coalesce(a.customerPO,'') and
		coalesce(pra.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
 	left join
		EDIFord.PlanningAuthAccums praa on 
		praa.RawDocumentGUID = a.RawDocumentGUID and
		praa.ShipToCode = a.ShipToCode AND
        praa.ShipFromCode = a.ShipFromCode and
		praa.CustomerPart = a.CustomerPart and
		coalesce(praa.CustomerPO,'') = coalesce(a.customerPO,'') and
		coalesce(praa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
										
	Where
		coalesce(a.newDocument,0) = 1 and
		coalesce(bo.AccumShipped,0) != coalesce(pra.LastAccumQty,0)


order by 1,2,5,4,7


--Update Order Header with Customer's Accum Received ---Armada Only

--Update oh
--		set oh.raw_cum = coalesce(ssa.LastAccumQty,0)
--from
--	@Current862s a
--	 Join 
--	EDIFORD.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
--and
--	a.ShipToCode = bo.EDIShipToCode
--and
--(	bo.CheckCustomerPOShipSchedule = 0
--	or bo.CustomerPO = a.CustomerPO)
--and
--(	bo.CheckModelYearShipSchedule = 0
--	or bo.ModelYear862 = a.CustomerModelYear)
--	left join
--		EDIFORD.ShipScheduleAccums ssa on 
--		ssa.RawDocumentGUID = a.RawDocumentGUID and
--		ssa.ShipToCode = a.ShipToCode and
--		ssa.CustomerPart = a.CustomerPart and
--		coalesce(ssa.CustomerPO,'') = coalesce(a.customerPO,'') and
--		coalesce(ssa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
-- 	left join
--		EDIFORD.ShipScheduleAuthAccums ssaa on 
--		ssaa.RawDocumentGUID = a.RawDocumentGUID and
--		ssaa.ShipToCode = a.ShipToCode and
--		ssaa.CustomerPart = a.CustomerPart and
--		coalesce(ssaa.CustomerPO,'') = coalesce(a.customerPO,'') and
--		coalesce(ssaa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
--join
--		order_header oh on oh.order_no = bo.BlanketOrderNo
										
--	Where
--		coalesce(a.newDocument,0) = 1

--Update oh
--		set oh.fab_cum = coalesce(pra.LastAccumQty,0)
--from
--	@Current830s  a
--	 Join 
--	EDIFORD.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
--and
--	a.ShipToCode = bo.EDIShipToCode
--and
--(	bo.CheckCustomerPOPlanning = 0
--	or bo.CustomerPO = a.CustomerPO)
--and
--(	bo.CheckModelYearPlanning = 0
--	or bo.ModelYear830 = a.CustomerModelYear)
--	left join
--		EDIFORD.PlanningAccums pra on 
--		pra.RawDocumentGUID = a.RawDocumentGUID and
--		pra.ShipToCode = a.ShipToCode and
--		pra.CustomerPart = a.CustomerPart and
--		coalesce(pra.CustomerPO,'') = coalesce(a.customerPO,'') and
--		coalesce(pra.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
-- 	left join
--		EDIFORD.PlanningAuthAccums praa on 
--		praa.RawDocumentGUID = a.RawDocumentGUID and
--		praa.ShipToCode = a.ShipToCode and
--		praa.CustomerPart = a.CustomerPart and
--		coalesce(praa.CustomerPO,'') = coalesce(a.customerPO,'') and
--		coalesce(praa.CustomerModelYear,'') = coalesce(a.customerModelYear,'')
--join
--		order_header oh on oh.order_no = bo.BlanketOrderNo
										
--	Where
--		coalesce(a.newDocument,0) = 1
		
Select	*
into	#EDIAlerts
From	@EDIOrdersAlert

Select	TradingPartner ,
				DocumentType , --'PR - Planning Release; SS - ShipSchedule'
				AlertType ,
				ReleaseNo ,
				ShipToCode,
				ConsigneeCode ,				
				CustomerPart ,
				CustomerPO ,
				Description 
				
into	#EDIAlertsEmail
From	@EDIOrdersAlert


If Exists (Select 1 From #EDIAlerts)

Begin
		

		declare
			@html nvarchar(max),
			@EmailTableName sysname  = N'#EDIAlertsEmail'
		
		exec [FT].[usp_TableToHTML]
				@tableName = @Emailtablename
			,	@orderBy = N'AlertType'
			,	@html = @html OUTPUT
			,	@includeRowNumber = 0
			,	@camelCaseHeaders = 1
		
		DECLARE
			@EmailBody NVARCHAR(MAX)
		,	@EmailHeader NVARCHAR(MAX) = 'EDI Processing for EDIFORD' 

		SELECT
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'FxAlerts'-- sysname
	,		@recipients = 'edialerts@aztecmfgcorp.com' -- varchar(max)
	,		@copy_recipients = 'rjohnson@aztecmfgcorp.com' -- varchar(max)
	, 	@subject = @EmailHeader
	,  	@body = @EmailBody
	,  	@body_format = 'HTML'
	,		@importance = 'High' 
					

INSERT [EDIAlerts].[ProcessedReleases]

(	 EDIGroup
	,TradingPartner
	,DocumentType --'PR - Planning Release; SS - ShipSchedule'
	,AlertType 
	,ReleaseNo
	,ShipToCode
	,ConsigneeCode 
	,ShipFromCode 
	,CustomerPart
	,CustomerPO
	,CustomerModelYear
	,Description
)


SELECT 
	'EDIFORD'
	,*
FROM
	#EDIAlerts
UNION
SELECT
	'EDIFORD'
	,TradingPartner = COALESCE((SELECT MAX(TradingPartner) FROM fxEDI.EDI.EDIDocuments WHERE GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  'Exception Quantity Due'
,	ReleaseNo =  COALESCE(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  COALESCE(a.ConsigneeCode,'')
,	ShipFromCode = COALESCE(a.ShipFromCode,'')
,	CustomerPart = COALESCE(a.CustomerPart,'')
,	CustomerPO = COALESCE(a.CustomerPO,'')
,	CustomerModelYear = COALESCE(a.CustomerModelYear,'')
, Description = 'Qty Due : ' + CONVERT(VARCHAR(MAX), c.ReleaseQty) + ' on - ' + CONVERT(VARCHAR(MAX), c.ReleaseDT)
FROM
	@Current862s a
JOIN
		EDIFORD.ShipSchedules c
ON			c.RawDocumentGUID = a.RawDocumentGUID AND
				a.CustomerPart = c.CustomerPart AND
				a.ShipToCode =c.ShipToCode AND
				a.ShipFromCode =c.ShipfromCode AND
				COALESCE(a.customerPO,'') = COALESCE(c.CustomerPO,'') AND
				COALESCE(a.CustomerModelYear,'') = COALESCE(c.CustomerModelYear,'')
WHERE
		COALESCE(a.newDocument,0) = 1
AND NOT EXISTS
( SELECT 1 FROM 
		EDIFORD.ShipSchedules b
 JOIN 
	EDIFORD.BlanketOrders bo ON b.CustomerPart = bo.CustomerPart
AND
	b.ShipToCode = bo.EDIShipToCode
AND
	b.ShipFromCode = bo.SupplierCode
AND
(	bo.CheckCustomerPOShipSchedule = 0
	OR bo.CustomerPO = b.CustomerPO)
AND
(	bo.CheckModelYearShipSchedule = 0
	OR bo.ModelYear862 = b.CustomerModelYear)
WHERE
				a.RawDocumentGUID = b.RawDocumentGUID AND
				a.CustomerPart = b.CustomerPart AND
				a.ShipToCode = b.ShipToCode AND
				a.ShipFromCode = b.ShipFromCode AND
				COALESCE(a.customerPO,'') = COALESCE(b.CustomerPO,'') AND
				COALESCE(a.CustomerModelYear,'') = COALESCE(b.CustomerModelYear,''))

UNION
SELECT
	'EDIFORD'
	,TradingPartner = COALESCE((SELECT MAX(TradingPartner) FROM fxEDI.EDI.EDIDocuments WHERE GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'PR'
,	AlertType =  'Exception Quantity Due'
,	ReleaseNo =  COALESCE(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  COALESCE(a.ConsigneeCode,'')
,	ShipFromCode = COALESCE(a.ShipFromCode,'')
,	CustomerPart = COALESCE(a.CustomerPart,'')
,	CustomerPO = COALESCE(a.CustomerPO,'')
,	CustomerModelYear = COALESCE(a.CustomerModelYear,'')
,  Description = 'Qty Due : ' + CONVERT(VARCHAR(MAX), c.ReleaseQty) + ' on - ' + CONVERT(VARCHAR(MAX), c.ReleaseDT)
FROM
	@Current830s a
JOIN
		EDIFORD.PlanningReleases c
ON			c.RawDocumentGUID = a.RawDocumentGUID AND
				a.CustomerPart = c.CustomerPart AND
				a.ShipToCode =c.ShipToCode AND
				a.ShipFromCode =c.ShipFromCode AND
				COALESCE(a.customerPO,'') = COALESCE(c.CustomerPO,'') AND
				COALESCE(a.CustomerModelYear,'') = COALESCE(c.CustomerModelYear,'')
WHERE
		COALESCE(a.newDocument,0) = 1
AND  NOT EXISTS
( SELECT 1 FROM 
		EDIFORD.PlanningReleases b
 JOIN 
	EDIFORD.BlanketOrders bo ON b.CustomerPart = bo.CustomerPart
AND
	b.ShipToCode = bo.EDIShipToCode
AND
	b.ShipFromCode = bo.SupplierCode
AND
(	bo.CheckCustomerPOPlanning = 0
	OR bo.CustomerPO = b.CustomerPO)
AND
(	bo.CheckModelYearPlanning = 0
	OR bo.ModelYear830 = b.CustomerModelYear)
WHERE
				a.RawDocumentGUID = b.RawDocumentGUID AND
				a.CustomerPart = b.CustomerPart AND
				a.ShipToCode = b.ShipToCode AND
				a.ShipFromCode = b.ShipFromCode AND
				COALESCE(a.customerPO,'') = COALESCE(b.CustomerPO,'') AND
				COALESCE(a.CustomerModelYear,'') = COALESCE(b.CustomerModelYear,''))


END




/* End E-Mail and Exceptions */


---	<Return>
SET	@Result = 0
RETURN
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
	@ProcReturn = EDIFORD.usp_Process
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
