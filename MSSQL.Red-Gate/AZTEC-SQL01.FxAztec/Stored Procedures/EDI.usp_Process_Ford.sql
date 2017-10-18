SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI].[usp_Process_Ford]
	@TranDT datetime out
,	@Result integer out
,	@Testing int = 1
--<Debug>
,	@Debug integer = 0
--</Debug>
as
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
,	NewDocument int
)

insert
	@Current862s
select
	c.RawDocumentGUID
,	c.NewDocument
from
	fordEDI.Current862s() c

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
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ICCode varchar(15)
,	CustomerPart varchar(35)
,	NewDocument int
)

insert
	@Current830s
--select
--	c.RawDocumentGUID
--,	c.ShipToCode
--,	c.ShipFromCode
--,	c.ICCode
--,	c.CustomerPart
--,	c.NewDocument
--from
--	fordEDI.Current830s() c

select distinct
	fr.RawDocumentGUID
,	fr.ShipToCode
,	fr.ShipFromCode
,	fr.ICCode
,	fr.CustomerPart
,	case
		when fr.status = 0 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'New'))
			then 1
		else 0
	end
from
	EDI.Ford_830_Releases fr
	join EDI.Ford_830_Headers fh
		on fh.RawDocumentGUID = fr.RawDocumentGUID
where
	fr.Status in
	(	0 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Active'))
	)
	and fh.Status in
	(	0 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'Active'))
	)
	and fh.DocumentDT =
	(	select
			max(fh2.DocumentDT)
		from
			EDI.Ford_830_Headers fh2
			join EDI.Ford_830_Releases fr2
				on fr2.RawDocumentGUID = fh2.RawDocumentGUID
		where
			fr.ShipToCode = fr2.ShipToCode
			and fr.ShipFromCode = fr2.ShipFromCode
			and coalesce(fr.ICCode, '') = coalesce(fr2.ICCode, '')
			and fr.CustomerPart = fr2.CustomerPart
	)
	and fh.DocNumber =
	(	select
			max(fh2.DocNumber)
		from
			EDI.Ford_830_Headers fh2
			join EDI.Ford_830_Releases fr2
				on fr2.RawDocumentGUID = fh2.RawDocumentGUID
		where
			fr.ShipToCode = fr2.ShipToCode
			and fr.ShipFromCode = fr2.ShipFromCode
			and coalesce(fr.ICCode, '') = coalesce(fr2.ICCode, '')
			and fr.CustomerPart = fr2.CustomerPart
			and fh.DocumentDT = fh2.DocumentDT
	)
	and fh.DocumentImportDT =
	(	select
			max(fh2.DocumentImportDT)
		from
			EDI.Ford_830_Headers fh2
			join EDI.Ford_830_Releases fr2
				on fr2.RawDocumentGUID = fh2.RawDocumentGUID
		where
			fr.ShipToCode = fr2.ShipToCode
			and fr.ShipFromCode = fr2.ShipFromCode
			and coalesce(fr.ICCode, '') = coalesce(fr2.ICCode, '')
			and fr.CustomerPart = fr2.CustomerPart
			and fh.DocumentDT = fh2.DocumentDT
			and fh.DocNumber = fh2.DocNumber
			and fh.ControlNumber = fh2.ControlNumber
	)
order by
	fr.ShipToCode
,	fr.ShipFromCode
,	fr.ICCode
,	fr.CustomerPart

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
set	@TableName = 'EDI.Ford_862_Headers'

update
	fh
set
	Status =
		case
			when cd.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Replaced'))
		end
from
	EDI.Ford_862_Headers fh
	left join @Current862s cd
		on fh.RawDocumentGUID = cd.RawDocumentGUID
where
	fh.Status in
	(	0 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
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
set	@TableName = 'EDI.Ford_830_Releases'

update
	fr
set
	Status =
		case
			when c.RawDocumentGUID is not null
				then 1 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Active'))
			else 2 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Replaced'))
		end
from
	EDI.Ford_830_Releases fr
	left join @Current830s c
		on fr.RawDocumentGUID = c.RawDocumentGUID
		and fr.ShipToCode = c.ShipToCode
		and fr.ShipFromCode = c.ShipFromCode
		and coalesce(fr.ICCode, '') = coalesce(c.ICCode, '')
		and fr.CustomerPart = c.CustomerPart

where
	fr.Status in
	(	0 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Active'))
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
set	@TableName = 'EDI.Ford_830_Headers'

update
	fh
set
	Status =
	case
		when exists
			(	select
					*
				from
					EDI.Ford_830_Releases fr
				where
					fr.RawDocumentGUID = fh.RawDocumentGUID
					and fr.Status = 1 --(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Active')
			) then 1 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'Active'))
		else 2 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'Replaced'))
	end
from
	EDI.Ford_830_Headers fh
where
	fh.Status in
	(	0 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'New'))
	,	1 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'Active'))
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
		'Ford_862_Headers'

	select
		*
	from
		EDI.Ford_862_Headers fh

	select
		'Ford_830_Headers'
		
	select
		*
	from
		EDI.Ford_830_Headers fh
end

--<Debug>
if @Debug & 1 = 1 begin
	print	'Write new releases.'
	print	'	Calculate raw releases from active 862s and 830s.'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	Write new releases. */
/*		Calculate raw releases from active 862s and 830s. */
declare @RawReleases table
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
,	DockCode
,	LineFeedCode
,	ReserveLineFeedCode
,	RelPost
,	ReferenceAccum
,	NewDocument
)
select
	OrderNo = bo.BlanketOrderNo
,	Type = 1
,	ReleaseDT = fr.ReleaseDT
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.InternalShipTo
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = fr.ReleaseNo
,	DockCode = fr.DockCode
,	LineFeedCode = fr.LineFeedCode
,	ReserveLineFeedCode = fr.ReserveLineFeedCode
,	RelPost = fr.ReleaseQty
,	ReferenceAccum = bo.AccumShipped
,	NewDocument = c.NewDocument
from
	EDI.Ford_862_Headers fh
	join EDI.Ford_862_Releases fr
		on fr.RawDocumentGUID = fh.RawDocumentGUID
	join fordEDI.BlanketOrders bo
		on bo.ShipToCode = fr.ShipToCode
		and bo.CustomerPart = fr.CustomerPart
	left join @Current862s c
		on c.RawDocumentGUID = fh.RawDocumentGUID
where
	fh.Status = 1 --(select dbo.udf_StatusValue('EDI.Ford_862_Headers', 'Status', 'Active'))
union all
select
	OrderNo = bo.BlanketOrderNo
,	Type = 2
,	ReleaseDT = fr.ReleaseDT
,	BlanketPart = bo.PartCode
,	CustomerPart = bo.CustomerPart
,	ShipToID = bo.InternalShipTo
,	CustomerPO = bo.CustomerPO
,	ModelYear = bo.ModelYear
,	OrderUnit = bo.OrderUnit
,	ReleaseNo = fr.ReleaseNo
,	DockCode = null
,	LineFeedCode = null
,	ReserveLineFeedCode = null
,	RelPost = fr.ReleaseQty
,	ReferenceAccum = bo.AccumShipped
,	NewDocument = c.NewDocument
from
	EDI.Ford_830_Headers fh
	join EDI.Ford_830_Releases fr
		on fr.RawDocumentGUID = fh.RawDocumentGUID
	join fordEDI.BlanketOrders bo
		on bo.ShipToCode in (fr.ICCode, fr.ShipToCode)
		and bo.CustomerPart = fr.CustomerPart
	left join @Current830s c
		on fr.RawDocumentGUID = c.RawDocumentGUID
		and fr.ShipToCode = c.ShipToCode
		and fr.ShipFromCode = c.ShipFromCode
		and coalesce(fr.ICCode, '') = coalesce(c.ICCode, '')
		and fr.CustomerPart = c.CustomerPart
where
	fh.Status = 1 --(select dbo.udf_StatusValue('EDI.Ford_830_Headers', 'Status', 'Active'))
	and fr.Status = 1--(select dbo.udf_StatusValue('EDI.Ford_830_Releases', 'Status', 'Active'))
order by
	1, 2, 3

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

update
	rr
set
	ReleaseDT = (select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and Type = 1)
from
	@RawReleases rr
where
	rr.Type = 2
	and rr.ReleaseDT < (select max(ReleaseDT) from @RawReleases where OrderNo = rr.OrderNo and Type = 1)

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
	
	select
		*
	from
		@RawReleases rr
end

update
	rr
set
	Status = -1
from
	@RawReleases rr
where
	QtyRelease <= 0

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
	set	@StartDT = GetDate ()
end
--</Debug>
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
	,	notes = case rr.Type when 1 then '862 Release' when 2 then '830 Release' end
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
		join fordEDI.BlanketOrders bo
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
	
	if  exists
		(	select
				*
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
			where 
				coalesce(oh.dock_code,'') != coalesce(rr.DockCode,'')
				or coalesce(oh.line_feed_code,'') != coalesce(rr.LineFeedCode,'')
				or coalesce(oh.zone_code,'') != coalesce(rr.ReserveLineFeedCode,'')
		) begin
	
		insert
			EDI.Ford862DockHeader
		(	SystemDT
		)
		select
			@TranDT
		
		insert 	
			EDI.Ford862DockDetails
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
		
		--- <Update rows="*">
		set	@TableName = 'dbo.order_header'
		
		update
			oh
		set
			dock_code = COALESCE(rr.DockCode,'')
		,	line_feed_code = COALESCE(rr.LineFeedCode,'')
		,	zone_code = COALESCE(rr.ReserveLineFeedCode,'')
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
				where (COALESCE(rr.DockCode,'')!= COALESCE(oh.dock_code,'') or COALESCE(line_feed_code,'') != COALESCE(rr.LineFeedCode,'') or COALESCE(zone_code,'') != COALESCE(rr.ReserveLineFeedCode,''))
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
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
	,	notes = case rr.Type when 1 then '862 Release' when 2 then '830 Release' end
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
		join fordEDI.BlanketOrders bo
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

---	<Return>
--if	@Testing != 0
--	and @@trancount > 0 begin
--	rollback tran @ProcName
--end
/* Start E-Mail Alerts and Exceptions*/

Declare @EDIOrdersAlert table (
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[ReleaseNo] [varchar](100) NULL,
	[CustomerPart] [varchar](100) NULL,
	[CustomerPO] [varchar](100) NULL,
	[ShipToCode] [varchar](100) NULL,
	[Type] [varchar](100) NULL,
	[Notes] [varchar](255) NULL
	)
		
		if exists (select 1 
						from 
							@Current862s F862c
						join	
							EDI.Ford_862_Releases F862r on F862c.RawDocumentGUID = F862r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode = F862r.ShipToCode
						and 
							bo.CustomerPart = F862r.CustomerPart
						where 
							bo.BlanketOrderNo is null
						union
						select 1 
						from 
							@Current830s F830c
						join	
							EDI.Ford_830_Releases F830r on F830c.RawDocumentGUID = F830r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode in (F830r.ICCode, F830r.ShipToCode)
						and 
							bo.CustomerPart = F830r.CustomerPart
						where 
							bo.BlanketOrderNo is null)
		Begin
		insert	@EDIOrdersAlert
		        ( ReleaseNo ,
		          CustomerPart ,
		          CustomerPO ,
		          ShipToCode ,
		          Type ,
		          Notes 
		        )
		select		
				distinct
				Coalesce(ReleaseNo,'')
			,	Coalesce(CustomerPart,'')
			,	Coalesce(CustomerPO,'')
			,	Coalesce(ShipToID,'')
			,	'Exception'
			,	'Blanket sales order not found; please add blanket sales order and reprocess EDI'
		         
		from (select
						F862r.ReleaseNo ReleaseNo, 
						F862r.CustomerPart CustomerPart,
						F862r.CustomerPO CustomerPO,
						F862r.ShipToCode ShipToID
						from 
							@Current862s F862c
						join	
							EDI.Ford_862_Releases F862r on F862c.RawDocumentGUID = F862r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode = F862r.ShipToCode
						and 
							bo.CustomerPart = F862r.CustomerPart
						where 
							bo.BlanketOrderNo is null
						union
					select
						F830r.ReleaseNo ReleaseNo, 
						F830r.CustomerPart CustomerPart,
						F830r.CustomerPO CustomerPO,
						F830r.ShipToCode ShipToID						 
						from 
							@Current830s F830c
						join	
							EDI.Ford_830_Releases F830r on F830c.RawDocumentGUID = F830r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode in (F830r.ICCode, F830r.ShipToCode)
						and 
							bo.CustomerPart = F830r.CustomerPart
						where 
							bo.BlanketOrderNo is null
					
				) FordEDIExceptions
		
		
	order by
		2,3,4
		
		DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>Ford EDI Exceptions</H1>' +
    N'<table border="1">' +
    N'<tr><th>ReleaseNo</th>' +
    N'<th>CustomerPart</th><th>CustomerPO</th><th>ShipToCode</th>' +
    N'<th>Notes</th></tr>' +
    CAST ( ( SELECT td = eo.ReleaseNo, '',
                    td = eo.CustomerPart, '',
                    td = eo.CustomerPO, '',
                    td = eo.ShipToCode, '',
                    td = eo.notes
              FROM @EDIOrdersAlert  eo
             where	type = 'Exception'
             order by 1,2,3  
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;
    
exec msdb.dbo.sp_send_dbmail @profile_name = 'DoNotReply', -- sysname
    @recipients = 'rjohnson@aztecmfgcorp.com', -- varchar(max)
    @copy_recipients = 'aboulanger@fore-thought.com,rreyna@aztecmfgcorp.com,rvasquez@aztecmfgcorp.com', -- varchar(max)
    --@blind_copy_recipients = 'aboulanger@fore-thought.com;estimpson@fore-thought.com', -- varchar(max)
    @subject = N'EDI Data Exception when processing Ford EDI Document(s)', -- nvarchar(255)
    @body = @TableHTML, -- nvarchar(max)
    @body_format = 'HTML', -- varchar(20)
    @importance = 'High' -- varchar(6)
    
		end
		
		
		if exists (select 
						1
						from 
							@Current862s F862c
						join	
							EDI.Ford_862_Releases F862r on F862c.RawDocumentGUID = F862r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode = F862r.ShipToCode
						and 
							bo.CustomerPart = F862r.CustomerPart
						where 
							bo.BlanketOrderNo is not null
						union
						select 
						1
						from 
							@Current830s F830c
						join	
							EDI.Ford_830_Releases F830r on F830c.RawDocumentGUID = F830r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode in (F830r.ICCode, F830r.ShipToCode)
						and 
							bo.CustomerPart = F830r.CustomerPart
						where 
							bo.BlanketOrderNo is not null)
		Begin
		insert	@EDIOrdersAlert
		        ( ReleaseNo ,
		          CustomerPart ,
		          CustomerPO ,
		          ShipToCode ,
		          Type ,
		          Notes 
		        )
		select		
				distinct
				Coalesce(ReleaseNo,'')
			,	Coalesce(CustomerPart,'')
			,	Coalesce(CustomerPO,'')
			,	Coalesce(ShipToID,'')
			,	'Alert'
			,	'Blanket sales order  ' + convert(varchar (8), OrderNo)+ ' Updated'
		         
		from (select
						F862r.ReleaseNo ReleaseNo, 
						F862r.CustomerPart CustomerPart,
						F862r.CustomerPO CustomerPO,
						F862r.ShipToCode ShipToID,
						bo.BlanketOrderNo OrderNo
						from 
							@Current862s F862c
						join	
							EDI.Ford_862_Releases F862r on F862c.RawDocumentGUID = F862r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode = F862r.ShipToCode
						and 
							bo.CustomerPart = F862r.CustomerPart
						where 
							bo.BlanketOrderNo is not null
						union
					select
						F830r.ReleaseNo ReleaseNo, 
						F830r.CustomerPart CustomerPart,
						F830r.CustomerPO CustomerPO,
						F830r.ShipToCode ShipToID,
						bo.BlanketOrderNo OrderNo						 
						from 
							@Current830s F830c
						join	
							EDI.Ford_830_Releases F830r on F830c.RawDocumentGUID = F830r.RawDocumentGUID and NewDocument = 1
						left join 
							fordEDI.BlanketOrders bo	on bo.ShipToCode in (F830r.ICCode, F830r.ShipToCode)
						and 
							bo.CustomerPart = F830r.CustomerPart

						where 
							bo.BlanketOrderNo is not null
					
				) FordEDIAlerts
		
		
	order by
		2,3,4
		
		DECLARE @tableHTMLA  NVARCHAR(MAX) ;

SET @tableHTMLA =
    N'<H1>Ford EDI Alert</H1>' +
    N'<table border="1">' +
    N'<tr><th>ReleaseNo</th>' +
    N'<th>CustomerPart</th><th>CustomerPO</th><th>ShipToCode</th>' +
    N'<th>Notes</th></tr>' +
    CAST ( ( SELECT td = eo.ReleaseNo, '',
                    td = eo.CustomerPart, '',
                    td = eo.CustomerPO, '',
                    td = eo.ShipToCode, '',
                    td = eo.notes
              FROM @EDIOrdersAlert  eo
             where	[type] = 'Alert'
            order by 1,2,3 
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;
    
exec msdb.dbo.sp_send_dbmail @profile_name = 'DoNotReply', -- sysname
    @recipients = 'rjohnson@aztecmfgcorp.com', -- varchar(max)
    @copy_recipients = 'aboulanger@fore-thought.com,rreyna@aztecmfgcorp.com,rvasquez@aztecmfgcorp.com', -- varchar(max)
    --@blind_copy_recipients = 'aboulanger@fore-thought.com;estimpson@fore-thought.com', -- varchar(max)
    @subject = N'EDI Data Alert Ford EDI Document(s) Updated FX Sales Orders', -- nvarchar(255)
    @body = @TableHTMLA, -- nvarchar(max)
    @body_format = 'HTML', -- varchar(20)
    @importance = 'Normal' -- varchar(6)
   end


/* End E-Mail and Exceptions */


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

update
	sdhv
set	Status = 0
from
	EDI.Ford_862_Headers sdhv
where
	RawDocumentGUID = 'FDF9D8F2-0C03-4021-BECB-68995E7E19CD'
go

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_Process_Ford
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Testing = 0
,	@Debug = 1

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go


go

--commit transaction
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
