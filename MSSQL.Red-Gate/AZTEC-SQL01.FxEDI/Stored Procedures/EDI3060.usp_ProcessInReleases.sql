SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI3060].[usp_ProcessInReleases]
	@Test int = 1
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 1
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on

	--- <TIC>
	declare
		@cDebug int = @Debug + 2 -- Proc level

	if	@Debug & 0x01 = 0x01 begin
		declare
			@TicDT datetime = getdate()
		,	@TocDT datetime
		,	@TimeDiff varchar(max)
		,	@TocMsg varchar(max)
		,	@cDebugMsg varchar(max)

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)
	end
	--- </TIC>

	--- <SP Begin Logging>
	declare
		@LogID int

	insert
		FXSYS.USP_Calls
	(	USP_Name
	,	BeginDT
	,	InArguments
	)
	select
		USP_Name = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)
	,	BeginDT = getdate()
	,	InArguments = convert
			(	varchar(max)
			,	(	select
						[@Test] = @Test
					,	[@TranDT] = @TranDT
					,	[@Result] = @Result
					,	[@Debug] = @Debug
					,	[@DebugMsg] = @DebugMsg
					for xml raw			
				)
			)

	set	@LogID = scope_identity()
	--- </SP Begin Logging>

	set	@Result = 999999

	--- <Error Handling>
	declare
		@CallProcName sysname
	,	@TableName sysname
	,	@ProcName sysname
	,	@ProcReturn integer
	,	@ProcResult integer
	,	@Error integer
	,	@RowCount integer

	set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI3060.usp_Test
	--- </Error Handling>

	/*	Record initial transaction count. */
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount

	begin try

		---	<ArgumentValidation>

		---	</ArgumentValidation>

		--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
		if	@TranCount = 0 begin
			begin tran @ProcName
		end
		else begin
			save tran @ProcName
		end
		set	@TranDT = coalesce(@TranDT, GetDate())
		--- </Tran>

		--- <Body>
		/*	Get current ship schedules and release plans. */
		set @TocMsg = 'Get current ship schedules and release plans'
		begin
			declare
				@CurrentShipSchedules table
			(	RawDocumentGUID uniqueidentifier not null
			,	ReleaseNo varchar(50) null
			,	ShipToCode varchar(15) null
			,	ShipFromCode varchar(15) null
			,	ConsigneeCode varchar(15) null
			,	CustomerPart varchar(50) null
			,	CustomerPO varchar(50) null
			,	CustomerModelYear varchar(50) null
			,	NewDocument tinyint
			,	SalesOrderNumber int
			,	DuplicateBlanketOrders tinyint
			,	MissingBlanketOrder tinyint
			)

			insert
				@CurrentShipSchedules
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ShipFromCode
			,	ConsigneeCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	NewDocument
			,	SalesOrderNumber
			,	DuplicateBlanketOrders
			,	MissingBlanketOrder
			)
			select
				css.RawDocumentGUID
			,	css.ReleaseNo
			,	css.ShipToCode
			,	css.ShipFromCode
			,	css.ConsigneeCode
			,	css.CustomerPart
			,	css.CustomerPO
			,	css.CustomerModelYear
			,	css.NewDocument
			,	css.SalesOrderNumber
			,	css.DuplicateBlanketOrders
			,	css.MissingBlanketOrder
			from
				EDI3060.CurrentShipSchedules() css

			if	@Debug & 0x01 = 0x01 begin
				select '@CurrentShipSchedules', * from @CurrentShipSchedules css
			end

			declare
				@CurrentReleasePlans table
			(	RawDocumentGUID uniqueidentifier not null
			,	ReleaseNo varchar(50) null
			,	ShipToCode varchar(15) null
			,	ShipFromCode varchar(15) null
			,	ConsigneeCode varchar(15) null
			,	CustomerPart varchar(50) null
			,	CustomerPO varchar(50) null
			,	CustomerModelYear varchar(50) null
			,	NewDocument tinyint
			,	SalesOrderNumber int
			,	DuplicateBlanketOrders tinyint
			,	MissingBlanketOrder tinyint
			)

			insert
				@CurrentReleasePlans
			(	RawDocumentGUID
			,	ReleaseNo
			,	ShipToCode
			,	ShipFromCode
			,	ConsigneeCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	NewDocument
			,	SalesOrderNumber
			,	DuplicateBlanketOrders
			,	MissingBlanketOrder
			)
			select
				crp.RawDocumentGUID
			,	crp.ReleaseNo
			,	crp.ShipToCode
			,	crp.ShipFromCode
			,	crp.ConsigneeCode
			,	crp.CustomerPart
			,	crp.CustomerPO
			,	crp.CustomerModelYear
			,	crp.NewDocument
			,	crp.SalesOrderNumber
			,	crp.DuplicateBlanketOrders
			,	crp.MissingBlanketOrder
			from
				EDI3060.CurrentReleasePlans() crp

			if	@Debug & 0x01 = 0x01 begin
				select '@CurrentReleasePlans', * from @CurrentReleasePlans crp
			end
			
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	If all current ship schedules and release plans are active (and not testing), done. */
		set @TocMsg = 'If all current ship schedules and release plans are active (and not testing), done'
		if	not exists
			(	select
					*
				from
					@CurrentShipSchedules css
				where
					css.NewDocument = 1
			)
			and not exists
			(	select
					*
				from
					@CurrentReleasePlans crp
				where
					crp.NewDocument = 1
			)
			and @Test = 0
		begin
			/* Goto done after logging. */
				
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>

			goto done
		end
		
		--return

		/*	Update status of ship schedules and release plans. */
		set @TocMsg = 'Update status of ship schedules and release plans'
		begin
			/*	New/Active releases are Active if they are current, replaced if they are not current. */
			update
				ssr
			set	ssr.Status =
					case
						when css.RawDocumentGUID is not null then 1
						else 2
					end
			from
				EDI3060.ShipScheduleReleases ssr
				left join @CurrentShipSchedules css
					on css.RawDocumentGUID = ssr.RawDocumentGUID
					and css.ShipToCode = ssr.ShipToCode
					and css.CustomerPart = ssr.CustomerPart
					and coalesce(css.CustomerPO, '') = coalesce(ssr.CustomerPO, '')
					and coalesce(css.CustomerModelYear, '') = coalesce(ssr.CustomerModelYear, '')
			where
				ssr.Status in (0, 1)

			update
				rpr
			set	rpr.Status =
					case
						when crp.RawDocumentGUID is not null then 1
						else 2
					end
			from
				EDI3060.ReleasePlanReleases rpr
				left join @CurrentReleasePlans crp
					on crp.RawDocumentGUID = rpr.RawDocumentGUID
					and crp.ShipToCode = rpr.ShipToCode
					and crp.CustomerPart = rpr.CustomerPart
					and coalesce(crp.CustomerPO, '') = coalesce(rpr.CustomerPO, '')
					and coalesce(crp.CustomerModelYear, '') = coalesce(rpr.CustomerModelYear, '')
			where
				rpr.Status in (0, 1)

			/*	New/active headers are Active if any release is active, otherwise replaced. */
			update
				ssh
			set	ssh.Status =
				case
					when exists
						(	select
								*
							from
								EDI3060.ShipScheduleReleases ssr
							where
								ssr.RawDocumentGUID = ssh.RawDocumentGUID
								and ssr.Status = 1
						) then 1
					else 2
				end
			from
				EDI3060.ShipScheduleHeaders ssh
			where
				ssh.Status in (0, 1)

			update
				rph
			set	rph.Status =
				case
					when exists
						(	select
								*
							from
								EDI3060.ReleasePlanReleases rpr
							where
								rpr.RawDocumentGUID = rph.RawDocumentGUID
								and rpr.Status = 1
						) then 1
					else 2
				end
			from
				EDI3060.ReleasePlanHeaders rph
			where
				rph.Status in (0, 1)

			if	@Debug & 0x01 = 0x01 begin
				select * from EDI3060.ShipScheduleHeaders ssh
				select * from EDI3060.ReleasePlanHeaders rph
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Calculate raw releases. */
		set @TocMsg = 'Calculate raw releases'
		begin
			declare
				@RawReleases table
			(	RowID int not null identity(1, 1) primary key
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
			,	NewDocument tinyint
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
			,	RelPrior
			,	RelPost
			,	NewDocument
			)
			/*	Any ship schedule with Customer Accum higher than Reference accum that doesn't have current day's release. */
			select
				ReleaseType = 1
			,	OrderNo = bo.BlanketOrderNo
			,	Type = 1
			,	ReleaseDT = convert(date, getdate())
			,	BlanketPart = min(bo.PartCode)
			,	CustomerPart = min(bo.CustomerPart)
			,	ShipToID = min(bo.ShipToCode)
			,	CustomerPO = min(bo.CustomerPO)
			,	ModelYear = min(bo.ModelYear)
			,	OrderUnit = min(bo.OrderUnit)
			,	ReleaseNo = 'Accum Demand'
			,	QtyRelease = 0
			,	StdQtyRelease = 0
			,	ReferenceAccum =
					case bo.ReferenceAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'C'
							then
							min(coalesce(convert(int, ssa.LastAccumQty), 0))
						else
							min(coalesce(convert(int, bo.AccumShipped), 0))
					end
			,	CustomerAccum =
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, ssaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, ssa.LastAccumQty), 0))
					end
			,	RelPrior = 
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, ssaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, ssa.LastAccumQty), 0))
					end
			,	RelPost =
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, ssaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, ssa.LastAccumQty), 0))
					end
			,	NewDocument = min(css.NewDocument)
			from
				@CurrentShipSchedules css
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = css.SalesOrderNumber
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
				left join EDI3060.ShipScheduleAccums ssa
					on ssa.RawDocumentGUID = css.RawDocumentGUID
					   and ssa.CustomerPart = css.CustomerPart
					   and ssa.ShipToCode = css.ShipToCode
					   and coalesce(ssa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
				left join EDI3060.ShipScheduleAuthAccums ssaa
					on ssaa.RawDocumentGUID = css.RawDocumentGUID
					   and ssaa.CustomerPart = css.CustomerPart
					   and ssaa.ShipToCode = css.ShipToCode
					   and coalesce(ssaa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssaa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
			where
				(	css.NewDocument = 1
					or exists
						(	select
								*
							from
								@CurrentReleasePlans crp2
							where
								css.SalesOrderNumber = crp2.SalesOrderNumber
								and crp2.NewDocument = 1
						)
				)
				and not exists
				(	select
						*
					from
						EDI3060.ShipScheduleReleases ssr
					where
						ssr.Status = 1
						and ssr.RawDocumentGUID = css.RawDocumentGUID
						and ssr.CustomerPart = css.CustomerPart
						and ssr.ShipToCode = css.ShipToCode
						and ssr.ReleaseDT = convert(date,getdate())
				)
			group by
				css.RawDocumentGUID
			,	bo.BlanketOrderNo
			,	bo.ReferenceAccum
			,	bo.AdjustmentAccum
			having
				case bo.AdjustmentAccum
					when 'N'
						then
						min(coalesce(convert(int, bo.AccumShipped), 0))
					when 'P'
						then
						min(coalesce(convert(int, ssaa.PriorCUM), 0))
					else
						min(coalesce(convert(int, ssa.LastAccumQty), 0))
				end >
					case bo.ReferenceAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'C'
							then
							min(coalesce(convert(int, ssa.LastAccumQty), 0))
						else
							min(coalesce(convert(int, bo.AccumShipped), 0))
					end
			union all
			/*	Current ship schedules. */
			select
				ReleaseType = 1
			,	OrderNo = bo.BlanketOrderNo
			,	Type = 1
			,	ReleaseDT = ssr.ReleaseDT + bo.ReleaseDueDTOffsetDays
			,	BlanketPart = bo.PartCode
			,	CustomerPart = bo.CustomerPart
			,	ShipToID = bo.ShipToCode
			,	CustomerPO = bo.CustomerPO
			,	ModelYear = bo.ModelYear
			,	OrderUnit = bo.OrderUnit
			,	ReleaseNo = ssr.ReleaseNo
			,	QtyRelease = ssr.ReleaseQty
			,	StdQtyRelease = ssr.ReleaseQty
			,	ReferenceAccum =
					case bo.ReferenceAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'C' then coalesce(convert(int, ssa.LastAccumQty), 0)
						else coalesce(convert(int, bo.AccumShipped), 0)
					end
			,	CustomerAccum =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, ssaa.PriorCUM), 0)
						else coalesce(convert(int, ssa.LastAccumQty), 0)
					end
			,	RelPrior =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, ssaa.PriorCUM), 0)
						else coalesce(convert(int, ssa.LastAccumQty), 0)
					end
					+ sum(ssr.ReleaseQty) over (partition by bo.BlanketOrderNo order by ssr.ReleaseDT) - ssr.ReleaseQty
			,	RelPost =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, ssaa.PriorCUM), 0)
						else coalesce(convert(int, ssa.LastAccumQty), 0)
					end
					+ sum(ssr.ReleaseQty) over (partition by bo.BlanketOrderNo order by ssr.ReleaseDT)
			,	NewDocument = css.NewDocument
			from
				@CurrentShipSchedules css
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = css.SalesOrderNumber
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
				join EDI3060.ShipScheduleReleases ssr
					on ssr.RawDocumentGUID = css.RawDocumentGUID
					   and ssr.CustomerPart = css.CustomerPart
					   and ssr.ShipToCode = css.ShipToCode
					   and coalesce(ssr.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssr.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
				left join EDI3060.ShipScheduleAccums ssa
					on ssa.RawDocumentGUID = css.RawDocumentGUID
					   and ssa.CustomerPart = css.CustomerPart
					   and ssa.ShipToCode = css.ShipToCode
					   and coalesce(ssa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
				left join EDI3060.ShipScheduleAuthAccums ssaa
					on ssaa.RawDocumentGUID = css.RawDocumentGUID
					   and ssaa.CustomerPart = css.CustomerPart
					   and ssaa.ShipToCode = css.ShipToCode
					   and coalesce(ssaa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssaa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
			where
				(	css.NewDocument = 1
					or exists
						(	select
								*
							from
								@CurrentReleasePlans crp2
							where
								css.SalesOrderNumber = crp2.SalesOrderNumber
								and crp2.NewDocument = 1
						)
				)
				and ssr.Status = 1
			union all
			/*	Any release plan with Customer Accum higher than Reference accum that doesn't have current day's release. */
			select
				ReleaseType = 2
			,	OrderNo = bo.BlanketOrderNo
			,	Type =
					case
						when max(bo.PlanningFlag) = 'P' then 2
						when max(bo.PlanningFlag) = 'F' then 1
						else 1
					end
			,	ReleaseDT = convert(date, getdate())
			,	BlanketPart = min(bo.PartCode)
			,	CustomerPart = min(bo.CustomerPart)
			,	ShipToID = min(bo.ShipToCode)
			,	CustomerPO = min(bo.CustomerPO)
			,	ModelYear = min(bo.ModelYear)
			,	OrderUnit = min(bo.OrderUnit)
			,	ReleaseNo = 'Accum Demand'
			,	QtyRelease = 0
			,	StdQtyRelease = 0
			,	ReferenceAccum =
					case bo.ReferenceAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'C'
							then
							min(coalesce(convert(int, rpa.LastAccumQty), 0))
						else
							min(coalesce(convert(int, bo.AccumShipped), 0))
					end
			,	CustomerAccum =
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, rpaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, rpa.LastAccumQty), 0))
					end
			,	RelPrior =
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, rpaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, rpa.LastAccumQty), 0))
					end
			,	RelPost =
					case bo.AdjustmentAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'P'
							then
							min(coalesce(convert(int, rpaa.PriorCUM), 0))
						else
							min(coalesce(convert(int, rpa.LastAccumQty), 0))
					end
			,	NewDocument = min(crp.NewDocument)
			from
				@CurrentReleasePlans crp
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = crp.SalesOrderNumber
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
				left join EDI3060.ReleasePlanAccums rpa
					on rpa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpa.CustomerPart = crp.CustomerPart
					   and rpa.ShipToCode = crp.ShipToCode
					   and coalesce(rpa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				left join EDI3060.ReleasePlanAuthAccums rpaa
					on rpaa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpaa.CustomerPart = crp.CustomerPart
					   and rpaa.ShipToCode = crp.ShipToCode
					   and coalesce(rpaa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpaa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
			where
				(	crp.NewDocument = 1
					or exists
						(	select
								*
							from
								@CurrentShipSchedules css2
							where
								crp.SalesOrderNumber = css2.SalesOrderNumber
								and css2.NewDocument = 1
						)
				)
				and not exists
				(	select
						*
					from
						EDI3060.ReleasePlanReleases rpr
					where
						rpr.Status = 1
						and rpr.RawDocumentGUID = crp.RawDocumentGUID
						and rpr.CustomerPart = crp.CustomerPart
						and rpr.ShipToCode = crp.ShipToCode
						and rpr.ReleaseDT = convert(date,getdate())
				)
			group by
				crp.RawDocumentGUID
			,	bo.BlanketOrderNo
			,	bo.ReferenceAccum
			,	bo.AdjustmentAccum
			having
				case bo.AdjustmentAccum
					when 'N'
						then
						min(coalesce(convert(int, bo.AccumShipped), 0))
					when 'P'
						then
						min(coalesce(convert(int, rpaa.PriorCUM), 0))
					else
						min(coalesce(convert(int, rpa.LastAccumQty), 0))
				end >
					case bo.ReferenceAccum
						when 'N'
							then
							min(coalesce(convert(int, bo.AccumShipped), 0))
						when 'C'
							then
							min(coalesce(convert(int, rpa.LastAccumQty), 0))
						else
							min(coalesce(convert(int, bo.AccumShipped), 0))
					end
			union all
			/*	Current release plans. */
			select
				ReleaseType = 2
			,	OrderNo = bo.BlanketOrderNo
			,	Type =
					case
						when bo.PlanningFlag = 'P' then 2
						when bo.PlanningFlag = 'F' then 1
						when bo.PlanningFlag = 'A' and rpr.ScheduleType not in ('C', 'A', 'Z') then 2
						else 1
					end
			,	ReleaseDT = rpr.ReleaseDT + bo.ReleaseDueDTOffsetDays
			,	BlanketPart = bo.PartCode
			,	CustomerPart = bo.CustomerPart
			,	ShipToID = bo.ShipToCode
			,	CustomerPO = bo.CustomerPO
			,	ModelYear = bo.ModelYear
			,	OrderUnit = bo.OrderUnit
			,	ReleaseNo = rpr.ReleaseNo
			,	QtyRelease = rpr.ReleaseQty
			,	StdQtyRelease = rpr.ReleaseQty
			,	ReferenceAccum =
					case bo.ReferenceAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'C' then coalesce(convert(int, rpa.LastAccumQty), 0)
						else coalesce(convert(int, bo.AccumShipped), 0)
					end
			,	CustomerAccum =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, rpaa.PriorCUM), 0)
						else coalesce(convert(int, rpa.LastAccumQty), 0)
					end
			,	RelPrior =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, rpaa.PriorCUM), 0)
						else coalesce(convert(int, rpa.LastAccumQty), 0)
					end
					+ sum(rpr.ReleaseQty) over (partition by bo.BlanketOrderNo order by rpr.ReleaseDT) - rpr.ReleaseQty
			,	RelPost =
					case bo.AdjustmentAccum
						when 'N' then coalesce(convert(int, bo.AccumShipped), 0)
						when 'P' then coalesce(convert(int, rpaa.PriorCUM), 0)
						else coalesce(convert(int, rpa.LastAccumQty), 0)
					end
					+ sum(rpr.ReleaseQty) over (partition by bo.BlanketOrderNo order by rpr.ReleaseDT)
			,	NewDocument = crp.NewDocument
			from
				@CurrentReleasePlans crp
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = crp.SalesOrderNumber
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
				join EDI3060.ReleasePlanReleases rpr
					on rpr.RawDocumentGUID = crp.RawDocumentGUID
					   and rpr.CustomerPart = crp.CustomerPart
					   and rpr.ShipToCode = crp.ShipToCode
					   and coalesce(rpr.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpr.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				left join EDI3060.ReleasePlanAccums rpa
					on rpa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpa.CustomerPart = crp.CustomerPart
					   and rpa.ShipToCode = crp.ShipToCode
					   and coalesce(rpa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				left join EDI3060.ReleasePlanAuthAccums rpaa
					on rpaa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpaa.CustomerPart = crp.CustomerPart
					   and rpaa.ShipToCode = crp.ShipToCode
					   and coalesce(rpaa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpaa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
			where
				(	crp.NewDocument = 1
					or exists
						(	select
								*
							from
								@CurrentShipSchedules css2
							where
								crp.SalesOrderNumber = css2.SalesOrderNumber
								and css2.NewDocument = 1
						)
				)
				and rpr.Status = 1
			order by
				OrderNo
			,	ReleaseType
			,	ReleaseDT

			if	@Debug & 0x01 = 0x01 begin
				select '@RawReleases', * from @RawReleases rr order by rr.RowID
			end
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Adjust raw releases. */
		set @TocMsg = 'Adjust raw releases'
		begin
			
			update
				rr
			set	rr.RelPost = case when rr.ReferenceAccum > rr.RelPost then rr.ReferenceAccum else rr.RelPost end
			from
				@RawReleases rr
			
			update
				rr
			set	rr.RelPrior = coalesce
					(	(	select
					 			max(rr2.RelPost)
					 		from
					 			@RawReleases rr2
							where
								rr2.OrderNo = rr.OrderNo
								and rr2.RowID < rr.RowID
					 	)
					,	rr.ReferenceAccum)
				
			from
				@RawReleases rr

			update
				rr
			set	rr.QtyRelease = rr.RelPost - rr.RelPrior
			,	rr.StdQtyRelease = rr.RelPost - rr.RelPrior
			,	Status =
					case
						when rr.RelPost - rr.RelPrior > rr.QtyRelease then 1
						when rr.RelPost - rr.RelPrior > 0 then 0
						else -1
					end
			from
				@RawReleases rr
			
			update
				rr
			set	rr.ReleaseDT = rr2.LastShipSchedDT + 1
			from
				@RawReleases rr
				cross apply
					(	select
							LastShipSchedDT = max(rr2.ReleaseDT)
						from
							@RawReleases rr2
						where
							rr2.OrderNo = rr.OrderNo
							and rr2.ReleaseType = 1
							and rr2.Status in (0, 1)
					) rr2
			where
				rr.ReleaseType = 2
				and rr.ReleaseDT < rr2.LastShipSchedDT
				
			update
				rr
			set rr.Line =
					(	select
							count(*)
						from
							@RawReleases rr2
						where
							rr2.Status in (0, 1)
							and rr2.OrderNo = rr.OrderNo
							and rr2.RowID <= rr.RowID
					)
			from
				@RawReleases rr
			where
				rr.Status in (0, 1)


			if	@Debug & 0x01 = 0x01 begin
				select '@RawReleases', * from @RawReleases rr order by rr.RowID
			end
			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Write order detail. */
		set @TocMsg = 'Write order detail'
		if	@Test = 0
		begin
			
			if	objectproperty(object_id('Fx.order_detail_deleted'), 'IsTable') is not null begin
				drop table Fx.order_detail_deleted
			end
			
			select
				*
			into
				Fx.order_detail_deleted
			from
				Fx.order_detail od
			where
				exists
					(	select
							*
						from
							@RawReleases rr
						where
							rr.OrderNo = od.order_no
					)

			delete
				od
			from
				Fx.order_detail od
			where
				exists
					(	select
							*
						from
							@RawReleases rr
						where
							rr.OrderNo = od.order_no
					)
			
			insert
				Fx.order_detail
			(	order_no, sequence, part_number, product_name, type, quantity
			,	status, notes, unit, due_date, release_no, destination
			,	customer_part, row_id, flag, ship_type, packline_qty, packaging_type
			,	weight, plant, week_no, std_qty, our_cum, the_cum, price
			,	alternate_price, committed_qty
			)
			select
				order_no = rr.OrderNo
			,	sequence = rr.Line
			,	part_number = rr.BlanketPart
			,	product_name = p.name
			,	type = case rr.Type when 1 then 'F' when 2 then 'P' else 'O' end
			,	quantity = rr.RelPost - rr.relPrior
			,	status = ''
			,	notes =
					'Processed Date : '
						+ convert(varchar(20), @TranDT, 120)
						+ ' ~ '
						+ case rr.Type when 1 then 'EDI Processed Release (Ship Sched)' when 2 then 'EDI Processed Release (Release Plan)' else '' end
						+ case when rr.Status = 1 then ' ~ Accum Adjustment' else '' end
			,	unit = oh.unit
			,	due_date = rr.ReleaseDT
			,	release_no = rr.ReleaseNo
			,	destination = rr.ShipToID
			,	customer_part = rr.CustomerPart
			,	row_id = rr.Line
			,	flag = 1
			,	ship_type = oh.ship_type
			,	packline_qty = 0
			,	packaging_type = bo.PackageType
			,	weight = (rr.RelPost - rr.relPrior) * bo.UnitWeight
			,	plant = oh.plant
			,	week_no = datediff(wk, parm.fiscal_year_begin, rr.ReleaseDT) + 1
			,	std_qty = rr.RelPost - rr.relPrior
			,	our_cum = rr.RelPrior
			,	the_cum = rr.RelPost
			,	price = oh.price
			,	alternate_price = oh.alternate_price
			,	committed_qty =
					case
						when rr.QtyShipper > rr.RelPost - bo.AccumShipped then rr.RelPost - rr.relPrior
						when rr.QtyShipper > rr.RelPrior - bo.AccumShipped then rr.QtyShipper - (rr.RelPrior - bo.AccumShipped)
						else 0
					end
			from
				@RawReleases rr
				join Fx.order_header oh
					join Fx.part p
						on p.part = oh.blanket_part
					on oh.order_no = rr.OrderNo
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = rr.OrderNo
				cross join Fx.parameters parm
			where
				rr.Status in (0, 1)
			order by
				rr.OrderNo
			,	rr.Line

			if	@Debug & 0x01 = 0x01 begin
				select * from Fx.order_detail od where od.order_no in (select OrderNo from @RawReleases rr)
			end

			if	@Debug & 0x01 = 0x01 begin
				select
					rr.OrderNo
				,	NewOrderQty = sum(rr.QtyRelease)
				,	OldOrderQty =
						(	select
								sum(odd.quantity)
							from
								Fx.order_detail_deleted odd
							where
								odd.order_no = rr.OrderNo
						)
				from
					@RawReleases rr
				group by
					rr.OrderNo
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		else begin
			
			if	objectproperty(object_id('FxTest.order_detail_deleted'), 'IsTable') is not null begin
				drop table FxTest.order_detail_deleted
			end
			
			select
				*
			into
				FxTest.order_detail_deleted
			from
				FxTest.order_detail od
			where
				exists
					(	select
							*
						from
							@RawReleases rr
						where
							rr.OrderNo = od.order_no
					)

			delete
				od
			from
				FxTest.order_detail od
			where
				exists
					(	select
							*
						from
							@RawReleases rr
						where
							rr.OrderNo = od.order_no
					)
			
			insert
				FxTest.order_detail
			(	order_no, sequence, part_number, product_name, type, quantity
			,	status, notes, unit, due_date, release_no, destination
			,	customer_part, row_id, flag, ship_type, packline_qty, packaging_type
			,	weight, plant, week_no, std_qty, our_cum, the_cum, price
			,	alternate_price, committed_qty
			)
			select
				order_no = rr.OrderNo
			,	sequence = rr.Line
			,	part_number = rr.BlanketPart
			,	product_name = p.name
			,	type = case rr.Type when 1 then 'F' when 2 then 'P' else 'O' end
			,	quantity = rr.RelPost - rr.relPrior
			,	status = ''
			,	notes =
					'Processed Date : '
						+ convert(varchar(20), @TranDT, 120)
						+ ' ~ '
						+ case rr.Type when 1 then 'EDI Processed Release (Ship Sched)' when 2 then 'EDI Processed Release (Release Plan)' else '' end
						+ case when rr.Status = 1 then ' ~ Accum Adjustment' else '' end
			,	unit = oh.unit
			,	due_date = rr.ReleaseDT
			,	release_no = rr.ReleaseNo
			,	destination = rr.ShipToID
			,	customer_part = rr.CustomerPart
			,	row_id = rr.Line
			,	flag = 1
			,	ship_type = oh.ship_type
			,	packline_qty = 0
			,	packaging_type = bo.PackageType
			,	weight = (rr.RelPost - rr.relPrior) * bo.UnitWeight
			,	plant = oh.plant
			,	week_no = datediff(wk, parm.fiscal_year_begin, rr.ReleaseDT) + 1
			,	std_qty = rr.RelPost - rr.relPrior
			,	our_cum = rr.RelPrior
			,	the_cum = rr.RelPost
			,	price = oh.price
			,	alternate_price = oh.alternate_price
			,	committed_qty =
					case
						when rr.QtyShipper > rr.RelPost - bo.AccumShipped then rr.RelPost - rr.relPrior
						when rr.QtyShipper > rr.RelPrior - bo.AccumShipped then rr.QtyShipper - (rr.RelPrior - bo.AccumShipped)
						else 0
					end
			from
				@RawReleases rr
				join FxTest.order_header oh
					join Fx.part p
						on p.part = oh.blanket_part
					on oh.order_no = rr.OrderNo
				join EDI3060.BlanketOrders bo
					on bo.BlanketOrderNo = rr.OrderNo
				cross join FxTest.parameters parm
			where
				rr.Status in (0, 1)
			order by
				rr.OrderNo
			,	rr.Line

			if	@Debug & 0x01 = 0x01 begin
				select * from FxTest.order_detail od where od.order_no in (select OrderNo from @RawReleases rr)
			end

			if	@Debug & 0x01 = 0x01 begin
				select
					rr.OrderNo
				,	NewOrderQty = sum(rr.QtyRelease)
				,	OldOrderQty =
						(	select
								sum(odd.quantity)
							from
								FxTest.order_detail_deleted odd
							where
								odd.order_no = rr.OrderNo
						)
				from
					@RawReleases rr
				group by
					rr.OrderNo
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Update order headers. */
		set @TocMsg = 'Update order headers'
		if	@Test = 0
		begin
			update
				oh
			set	oh.custom01 = rtrim(rps.UserDefined1)
			,	oh.dock_code = rtrim(rps.UserDefined1)
			,	oh.line_feed_code = rtrim(rps.UserDefined2)
			,	oh.zone_code = rtrim(rps.UserDefined3)
			,	oh.raw_cum = coalesce(rpaa.RAWCUM, oh.raw_cum)
			,	oh.fab_cum = coalesce(rpaa.FabCUM, oh.fab_cum)
			from
				Fx.order_header oh
				join @CurrentReleasePlans crp
					on oh.order_no = crp.SalesOrderNumber
				join EDI3060.ReleasePlanSupplemental rps
					on rps.RawDocumentGUID = crp.RawDocumentGUID
					and rps.CustomerPart = crp.CustomerPart
					and rps.ShipToCode = crp.ShipToCode
					and coalesce(rps.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					and coalesce(rps.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				left join EDI3060.ReleasePlanAuthAccums rpaa
					on rpaa.RawDocumentGUID = crp.RawDocumentGUID
					and rpaa.CustomerPart = crp.CustomerPart
					and rpaa.ShipToCode = crp.ShipToCode
					and coalesce(rpaa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					and coalesce(rpaa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				
			update
				oh
			set	oh.custom01 = rtrim(sss.UserDefined1)
			,	oh.dock_code = rtrim(sss.UserDefined1)
			,	oh.line_feed_code = rtrim(sss.UserDefined2)
			,	oh.zone_code = rtrim(sss.UserDefined3)
			,	oh.line11 = rtrim(sss.UserDefined11)
			,	oh.line12 = rtrim(sss.UserDefined12)
			,	oh.line13 = rtrim(sss.UserDefined13)
			,	oh.line14 = rtrim(sss.UserDefined14)
			,	oh.line15 = rtrim(sss.UserDefined15)
			,	oh.line16 = rtrim(sss.UserDefined16)
			,	oh.line17 = rtrim(sss.UserDefined17)
			,	oh.raw_cum = coalesce(ssaa.RAWCUM, oh.raw_cum)
			,	oh.fab_cum = coalesce(ssaa.FabCUM, oh.fab_cum)
			from
				Fx.order_header oh
				join @CurrentShipSchedules css
					on oh.order_no = css.SalesOrderNumber
				join EDI3060.ShipScheduleSupplemental sss
					on sss.RawDocumentGUID = css.RawDocumentGUID
					and sss.CustomerPart = css.CustomerPart
					and sss.ShipToCode = css.ShipToCode
					and coalesce(sss.CustomerPO, '') = coalesce(css.CustomerPO, '')
					and coalesce(sss.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
				left join EDI3060.ShipScheduleAuthAccums ssaa
					on ssaa.RawDocumentGUID = css.RawDocumentGUID
					and ssaa.CustomerPart = css.CustomerPart
					and ssaa.ShipToCode = css.ShipToCode
					and coalesce(ssaa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					and coalesce(ssaa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')

			if	@Debug & 0x01 = 0x01 begin
				select * from Fx.order_header oh where oh.order_no in (select OrderNo from @RawReleases rr)
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		else begin
			update
				oh
			set	oh.custom01 = rtrim(rps.UserDefined1)
			,	oh.dock_code = rtrim(rps.UserDefined1)
			,	oh.line_feed_code = rtrim(rps.UserDefined2)
			,	oh.zone_code = rtrim(rps.UserDefined3)
			from
				FxTest.order_header oh
				join @CurrentReleasePlans crp
					on oh.order_no = crp.SalesOrderNumber
				join EDI3060.ReleasePlanSupplemental rps
					on rps.RawDocumentGUID = crp.RawDocumentGUID
					and rps.CustomerPart = crp.CustomerPart
					and rps.ShipToCode = crp.ShipToCode
					and coalesce(rps.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					and coalesce(rps.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				
			update
				oh
			set	oh.custom01 = rtrim(sss.UserDefined1)
			,	oh.dock_code = rtrim(sss.UserDefined1)
			,	oh.line_feed_code = rtrim(sss.UserDefined2)
			,	oh.zone_code = rtrim(sss.UserDefined3)
			,	oh.line11 = rtrim(sss.UserDefined11)
			,	oh.line12 = rtrim(sss.UserDefined12)
			,	oh.line13 = rtrim(sss.UserDefined13)
			,	oh.line14 = rtrim(sss.UserDefined14)
			,	oh.line15 = rtrim(sss.UserDefined15)
			,	oh.line16 = rtrim(sss.UserDefined16)
			,	oh.line17 = rtrim(sss.UserDefined17)
			from
				FxTest.order_header oh
				join @CurrentShipSchedules css
					on oh.order_no = css.SalesOrderNumber
				join EDI3060.ShipScheduleSupplemental sss
					on sss.RawDocumentGUID = css.RawDocumentGUID
					and sss.CustomerPart = css.CustomerPart
					and sss.ShipToCode = css.ShipToCode
					and coalesce(sss.CustomerPO, '') = coalesce(css.CustomerPO, '')
					and coalesce(sss.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')

			if	@Debug & 0x01 = 0x01 begin
				select * from FxTest.order_header oh where oh.order_no in (select OrderNo from @RawReleases rr)
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Generate process report. */
		set @TocMsg = 'Generate process report'
		begin
			declare
				@ProcessReport table
			(	TradingPartner varchar(30)
			,	DocumentType varchar(30) null --'PR - Planning Release; SS - ShipSchedule'
			,	AlertType varchar(100) null
			,	ReleaseNo varchar(100) null
			,	ShipToCode varchar(100) null
			,	ConsigneeCode varchar(100) null
			,	ShipFromCode varchar(100) null
			,	CustomerPart varchar(100) null
			,	CustomerPO varchar(100) null
			,	CustomerModelYear varchar(100) null
			,	Description varchar(max)
			)

			/*	Missing blanket orders. */
			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select
				ssh.TradingPartner
			,	DocumentType = 'SS'
			,	AlertType = 'Exception'
			,	css.ReleaseNo
			,	css.ShipToCode
			,	css.ConsigneeCode
			,	css.ShipFromCode
			,	css.CustomerPart
			,	css.CustomerPO
			,	css.CustomerModelYear
			,	Description = 'Please add blanket order for these orders and reprocess EDI.'
					+ '  Qty due:  ' + convert(varchar(20), ssr.ReleaseQty)
					+ '  On:  ' + convert(varchar(20), ssr.ReleaseDT)
			from
				@CurrentShipSchedules css
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
				join EDI3060.ShipScheduleReleases ssr
					on ssr.RawDocumentGUID = css.RawDocumentGUID
					   and ssr.CustomerPart = css.CustomerPart
					   and ssr.ShipToCode = css.ShipToCode
					   and coalesce(ssr.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssr.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
			where
				css.MissingBlanketOrder = 1
				and ssr.ReleaseQty > 0
				and
				(	css.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentReleasePlans crp
						where
							crp.SalesOrderNumber = css.SalesOrderNumber
							and crp.NewDocument = 1
					)
				)
			order by
				ssh.TradingPartner
			,	css.ShipToCode
			,	css.CustomerPart
			,	ssr.ReleaseDT

			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select
				rph.TradingPartner
			,	DocumentType = 'RP'
			,	AlertType = 'Exception'
			,	crp.ReleaseNo
			,	crp.ShipToCode
			,	crp.ConsigneeCode
			,	crp.ShipFromCode
			,	crp.CustomerPart
			,	crp.CustomerPO
			,	crp.CustomerModelYear
			,	Description = 'Please add blanket order for these orders and reprocess EDI.'
					+ '  Qty due:  ' + convert(varchar(20), rpr.ReleaseQty)
					+ '  On:  ' + convert(varchar(20), rpr.ReleaseDT)
			from
				@CurrentReleasePlans crp
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
				join EDI3060.ReleasePlanReleases rpr
					on rpr.RawDocumentGUID = crp.RawDocumentGUID
					   and rpr.CustomerPart = crp.CustomerPart
					   and rpr.ShipToCode = crp.ShipToCode
					   and coalesce(rpr.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpr.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
			where
				crp.MissingBlanketOrder = 1
				and rpr.ReleaseQty > 0
				and
				(	crp.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentShipSchedules css
						where
							css.SalesOrderNumber = crp.SalesOrderNumber
							and css.NewDocument = 1
					)
				)
			order by
				rph.TradingPartner
			,	crp.ShipToCode
			,	crp.CustomerPart
			,	rpr.ReleaseDT
			option (QUERYTRACEON 460)
			
			/*	Duplicate blanket orders. */
			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				ssh.TradingPartner
			,	DocumentType = 'SS'
			,	AlertType = 'Warning'
			,	css.ReleaseNo
			,	css.ShipToCode
			,	css.ConsigneeCode
			,	css.ShipFromCode
			,	css.CustomerPart
			,	css.CustomerPO
			,	css.CustomerModelYear
			,	Description = 'Duplicate orders found.  Updated sales order:  ' + convert(varchar(15), css.SalesOrderNumber)
			from
				@CurrentShipSchedules css
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
			where
				css.DuplicateBlanketOrders = 1
				and
				(	css.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentReleasePlans crp
						where
							crp.SalesOrderNumber = css.SalesOrderNumber
							and crp.NewDocument = 1
					)
				)

			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				rph.TradingPartner
			,	DocumentType = 'RP'
			,	AlertType = 'Warning'
			,	crp.ReleaseNo
			,	crp.ShipToCode
			,	crp.ConsigneeCode
			,	crp.ShipFromCode
			,	crp.CustomerPart
			,	crp.CustomerPO
			,	crp.CustomerModelYear
			,	Description = 'Duplicate orders found.  Updated sales order:  ' + convert(varchar(15), crp.SalesOrderNumber)
			from
				@CurrentReleasePlans crp
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
			where
				crp.DuplicateBlanketOrders = 1
				and
				(	crp.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentShipSchedules css
						where
							css.SalesOrderNumber = crp.SalesOrderNumber
							and css.NewDocument = 1
					)
				)
			
			/*	Updated blanket order releases. */
			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				ssh.TradingPartner
			,	DocumentType = 'SS'
			,	AlertType = 'Success'
			,	css.ReleaseNo
			,	css.ShipToCode
			,	css.ConsigneeCode
			,	css.ShipFromCode
			,	css.CustomerPart
			,	css.CustomerPO
			,	css.CustomerModelYear
			,	Description = 'EDI processed.  Updated Sales Order: ' + convert(varchar(15), css.SalesOrderNumber)
				+ '  Old Quantity: '
				+	(	select
							coalesce(convert(varchar(12), convert(int, sum(odd.quantity))), '0')
						from
							Fx.order_detail_deleted odd
						where
							odd.order_no = css.SalesOrderNumber
					)
				+ '  New Quantity: '
				+	(	select
							coalesce(convert(varchar(12), convert(int, sum(od.quantity))), '0')
						from
							Fx.order_detail od
						where
							od.order_no = css.SalesOrderNumber
					)
			from
				@CurrentShipSchedules css
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
			where
				css.MissingBlanketOrder = 0
				and
				(	css.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentReleasePlans crp
						where
							crp.SalesOrderNumber = css.SalesOrderNumber
							and crp.NewDocument = 1
					)
				)

			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				rph.TradingPartner
			,	DocumentType = 'RP'
			,	AlertType = 'Success'
			,	crp.ReleaseNo
			,	crp.ShipToCode
			,	crp.ConsigneeCode
			,	crp.ShipFromCode
			,	crp.CustomerPart
			,	crp.CustomerPO
			,	crp.CustomerModelYear
			,	Description = 'EDI processed.  Updated Sales Order: ' + convert(varchar(15), crp.SalesOrderNumber)
				+ '  Old Quantity: '
				+	(	select
							coalesce(convert(varchar(12), convert(int, sum(odd.quantity))), '0')
						from
							Fx.order_detail_deleted odd
						where
							odd.order_no = crp.SalesOrderNumber
					)
				+ '  New Quantity: '
				+	(	select
							coalesce(convert(varchar(12), convert(int, sum(od.quantity))), '0')
						from
							Fx.order_detail od
						where
							od.order_no = crp.SalesOrderNumber
					)
			from
				@CurrentReleasePlans crp
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
			where
				crp.MissingBlanketOrder = 0
				and
				(	crp.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentShipSchedules css
						where
							css.SalesOrderNumber = crp.SalesOrderNumber
							and css.NewDocument = 1
					)
				)

			/*	Accum discrepancies. */
			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				ssh.TradingPartner
			,	DocumentType = 'SS'
			,	AlertType = 'Warning'
			,	css.ReleaseNo
			,	css.ShipToCode
			,	css.ConsigneeCode
			,	css.ShipFromCode
			,	css.CustomerPart
			,	css.CustomerPO
			,	css.CustomerModelYear
			,	Description = 'Customer accum received does not mach sales order accum. ' 
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
				@CurrentShipSchedules css
				join EDI3060.ShipScheduleHeaders ssh
					on ssh.RawDocumentGUID = css.RawDocumentGUID
				join EDI3060.BlanketOrders bo
					on css.SalesOrderNumber = bo.BlanketOrderNo
				join EDI3060.ShipScheduleAccums ssa
					on ssa.RawDocumentGUID = css.RawDocumentGUID
					   and ssa.CustomerPart = css.CustomerPart
					   and ssa.ShipToCode = css.ShipToCode
					   and coalesce(ssa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
				join EDI3060.ShipScheduleAuthAccums ssaa
					on ssaa.RawDocumentGUID = css.RawDocumentGUID
					   and ssaa.CustomerPart = css.CustomerPart
					   and ssaa.ShipToCode = css.ShipToCode
					   and coalesce(ssaa.CustomerPO, '') = coalesce(css.CustomerPO, '')
					   and coalesce(ssaa.CustomerModelYear, '') = coalesce(css.CustomerModelYear, '')
			where
				css.MissingBlanketOrder = 0
				and
				(	ssa.LastAccumQty != bo.AccumShipped
					and ssa.LastAccumQty + bo.LastShipQty != bo.AccumShipped
				)
				and
				(	css.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentReleasePlans crp
						where
							crp.SalesOrderNumber = css.SalesOrderNumber
							and crp.NewDocument = 1
					)
				)

			insert
				@ProcessReport
			(	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			)
			select distinct
				rph.TradingPartner
			,	DocumentType = 'RP'
			,	AlertType = 'Warning'
			,	crp.ReleaseNo
			,	crp.ShipToCode
			,	crp.ConsigneeCode
			,	crp.ShipFromCode
			,	crp.CustomerPart
			,	crp.CustomerPO
			,	crp.CustomerModelYear
			,	Description = 'Customer accum received does not mach sales order accum. ' 
					+ convert(varchar(15), bo.BlanketOrderNo) 
					+ '  Customer Accum: ' 
					+ convert(varchar(15), coalesce(rpa.LastAccumQty,0))
					+ '  Our Accum Shipped: '
					+ convert(varchar(15), coalesce(bo.AccumShipped,0))
					+ '  Customer Last Recvd Qty: ' 
					+ convert(varchar(15), coalesce(rpa.LastQtyReceived,0))
					+ '  Our Last Shipped Qty: '
					+ convert(varchar(15), coalesce(bo.LastShipQty,0))
					+ '  Customer Prior Auth Accum: ' 
					+ convert(varchar(15), coalesce(rpaa.PriorCUM,0))
			from
				@CurrentReleasePlans crp
				join EDI3060.ReleasePlanHeaders rph
					on rph.RawDocumentGUID = crp.RawDocumentGUID
				join EDI3060.BlanketOrders bo
					on crp.SalesOrderNumber = bo.BlanketOrderNo
				join EDI3060.ReleasePlanAccums rpa
					on rpa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpa.CustomerPart = crp.CustomerPart
					   and rpa.ShipToCode = crp.ShipToCode
					   and coalesce(rpa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
				join EDI3060.ReleasePlanAuthAccums rpaa
					on rpaa.RawDocumentGUID = crp.RawDocumentGUID
					   and rpaa.CustomerPart = crp.CustomerPart
					   and rpaa.ShipToCode = crp.ShipToCode
					   and coalesce(rpaa.CustomerPO, '') = coalesce(crp.CustomerPO, '')
					   and coalesce(rpaa.CustomerModelYear, '') = coalesce(crp.CustomerModelYear, '')
			where
				crp.MissingBlanketOrder = 0
				and
				(	rpa.LastAccumQty != bo.AccumShipped
					and rpa.LastAccumQty + bo.LastShipQty != bo.AccumShipped
				)
				and
				(	crp.NewDocument = 1
					or exists
					(	select
							*
						from
							@CurrentShipSchedules css
						where
							css.SalesOrderNumber = crp.SalesOrderNumber
							and css.NewDocument = 1
					)
				)
			
			insert
				EDI.ProcessReport
			(	ProcedureName
			,	TradingPartner
			,	DocumentType
			,	AlertType
			,	ReleaseNo
			,	ShipToCode
			,	ConsigneeCode
			,	ShipFromCode
			,	CustomerPart
			,	CustomerPO
			,	CustomerModelYear
			,	Description
			,	TranDT
			)
			select
				ProcedureName = @ProcName
			,	pr.TradingPartner
			,	pr.DocumentType
			,	pr.AlertType
			,	pr.ReleaseNo
			,	pr.ShipToCode
			,	pr.ConsigneeCode
			,	pr.ShipFromCode
			,	pr.CustomerPart
			,	pr.CustomerPO
			,	pr.CustomerModelYear
			,	pr.Description
			,	TranDT = @TranDT
			from
				@ProcessReport pr

			if	@Debug & 0x01 = 0x01 begin
				--select '@ProcessReport', * from @ProcessReport ea
				select * from EDI.ProcessReport pr where pr.TranDT = @TranDT
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		
		--return

		/*	Send process report email. */
		set @TocMsg = 'Send process report email'
		begin
			select
				pr.TradingPartner
			,	pr.DocumentType
			,	pr.AlertType
			,	pr.ReleaseNo
			,	pr.ShipToCode
			,	pr.ConsigneeCode
			,	pr.CustomerPart
			,	pr.CustomerPO
			,	pr.Description
			into
				#EDIAlertsEmail
			from
				@ProcessReport pr	
			
			declare
				@html nvarchar(max)
			
			--- <Call>	
			set	@CallProcName = 'FXSYS.usp_TableToHTML'
			execute
				@ProcReturn = FXSYS.usp_TableToHTML
					@TableName = '#EDIAlertsEmail'
				,	@OrderBy = N'AlertType'
				,	@Html = @html out
				,	@IncludeRowNumber = 0
				,	@CamelCaseHeaders = 1
			
			set	@Error = @@Error
			if	@Error != 0 begin
				set	@Result = 900501
				RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>
			
			if	@Debug & 0x01 = 0x01 begin
				exec FXSYS.usp_LongPrint @html
			end
			
			declare
				@emailHeader nvarchar(max) = N'EDI Processing for EDI3060'
			declare
				@emailBody nvarchar(max) = N'<H1>' + @emailHeader + N'</H1>' + @html
			,	@profileName sysname
			,	@recipients sysname
			,	@copyRecipients sysname

			select top(1)
				@profileName = aed.DBMailProfileName
			,	@recipients = aed.RecipientsList
			,	@copyRecipients = aed.CopyList
			from
				FxEDI.EDI.AlertEmailDefinition aed
			order by
				aed.RowID desc

			if	@Test = 0 begin
				exec msdb.dbo.sp_send_dbmail
					@profile_name = @profileName
				,	@recipients = @recipients
				,	@copy_recipients = @copyRecipients
				,	@subject = @emailHeader
				,	@body = @emailBody
				,	@body_format = 'HTML'
				,	@importance = 'HIGH'
			end

			--- <TOC>
			if	@Debug & 0x01 = 0x01 begin
				set @TocDT = getdate()
				set @TimeDiff =
					case
						when datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01')) > 1
							then convert(varchar, datediff(day, @TocDT - @TicDT, convert(datetime, '1900-01-01'))) + ' day(s) ' + convert(char(12), @TocDT - @TicDT, 114)
						else
							convert(varchar(12), @TocDT - @TicDT, 114)
					end
				set @DebugMsg = @DebugMsg + char(13) + char(10) + replicate(' -', (@Debug & 0x3E) / 2) + @TocMsg + ': ' + @TimeDiff
				set @TicDT = @TocDT
			end
			set @DebugMsg += coalesce(char(13) + char(10) + @cDebugMsg, N'')
			set @cDebugMsg = null
			--- </TOC>
		end
		--- </Body>

		done:
		---	<CloseTran AutoCommit=Yes>
		if	@TranCount = 0 begin
			if	@Test = 0 begin
				commit tran @ProcName
			end
			else begin
				rollback
			end
		end
		---	</CloseTran AutoCommit=Yes>

		--- <SP End Logging>
		update
			uc
		set	EndDT = getdate()
		,	OutArguments = convert
				(	varchar(max)
				,	(	select
							[@TranDT] = @TranDT
						,	[@Result] = @Result
						,	[@DebugMsg] = @DebugMsg
						for xml raw			
					)
				)
		from
			FXSYS.USP_Calls uc
		where
			uc.RowID = @LogID
		--- </SP End Logging>

		--- <TIC/TOC END>
		if	@Debug & 0x3F = 0x01 begin
			set @DebugMsg = @DebugMsg + char(13) + char(10)
			print @DebugMsg
		end
		--- </TIC/TOC END>

		---	<Return>
		set	@Result = 0
		return
			@Result
		--- </Return>
	end try
	begin catch
		declare
			@errorSeverity int
		,	@errorState int
		,	@errorMessage nvarchar(2048)
		,	@xact_state int
	
		select
			@errorSeverity = error_severity()
		,	@errorState = error_state ()
		,	@errorMessage = error_message()
		,	@xact_state = xact_state()

		execute FXSYS.usp_PrintError

		if	@xact_state = -1 begin 
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount = 0 begin
			rollback
			execute FXSYS.usp_LogError
		end
		if	@xact_state = 1 and @TranCount > 0 begin
			rollback transaction @ProcName
			execute FXSYS.usp_LogError
		end

		raiserror(@errorMessage, @errorSeverity, @errorState)
	end catch
end

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

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI3060.usp_ProcessInReleases
	@Test = 1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Debug = 1

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
