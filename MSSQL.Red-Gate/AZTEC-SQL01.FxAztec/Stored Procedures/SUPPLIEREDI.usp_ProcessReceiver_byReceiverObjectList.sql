SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SUPPLIEREDI].[usp_ProcessReceiver_byReceiverObjectList]
	@User varchar(5)
,	@ReceiverID int = null -- Pass working table or receiver ID or receiver object ID
,	@ReceiverObjectID int = null -- see @ReceiverID note
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
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

		set @DebugMsg = replicate(' -', (@Debug & 0x3E) / 2) + 'Start ' + user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
	end
	--- </TIC>

	--- <SP Begin Logging>
	declare
		@LogID int

	if	object_id('tempdb..#receiverObjectList') is null begin
		insert
			FXSYS.USP_Calls
		(	USP_Name
		,	BeginDT
		,	InArguments
		)
		select
			USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
		,	BeginDT = getdate()
		,	InArguments = convert
				(	varchar(max)
				,	(	select
							[@User] = @User
						,	[@ReceiverID] = @ReceiverID
						,	[@ReceiverObjectID] = @ReceiverObjectID
						,	[@TranDT] = @TranDT
						,	[@Result] = @Result
						,	[@Debug] = @Debug
						,	[@DebugMsg] = @DebugMsg
						,	[#receiverObjectList] = 'N/S'
						for xml raw			
					)
				)
	end
	else begin
		insert
			FXSYS.USP_Calls
		(	USP_Name
		,	BeginDT
		,	InArguments
		)
		select
			USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
		,	BeginDT = getdate()
		,	InArguments = convert
				(	varchar(max)
				,	(	select
							[@User] = @User
						,	[@ReceiverID] = @ReceiverID
						,	[@ReceiverObjectID] = @ReceiverObjectID
						,	[@TranDT] = @TranDT
						,	[@Result] = @Result
						,	[@Debug] = @Debug
						,	[@DebugMsg] = @DebugMsg
						,	[#receiverObjectList] =
								(	select
										*
									from
										#receiverObjectList rol
									for xml raw
								)
						for xml raw			
					)
				)
	end

	set	@LogID = scope_identity()
	--- </SP Begin Logging>

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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
	--- </Error Handling>

	/*	Record initial transaction count. */
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount

	begin try

		---	<ArgumentValidation>

		---	</ArgumentValidation>

		--- <Body>
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
		/*	Look for or create working table of receiver objects to create. */
		if	object_id('tempdb..#receiverObjectList') is null begin
			create table #receiverObjectList
			(	ReceiverObjectID int primary key
			)

			insert
				#receiverObjectList
			(	ReceiverObjectID
			)
			select
				ro.ReceiverObjectID
			from
				dbo.ReceiverHeaders rh
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
				join dbo.ReceiverObjects ro
					on ro.ReceiverLineID = rl.ReceiverLineID
			where
				rh.ReceiverID = coalesce(@ReceiverID, rh.ReceiverID)
				and ro.ReceiverObjectID = coalesce(@ReceiverObjectID, ro.ReceiverObjectID)
				and coalesce(@ReceiverID, @ReceiverObjectID) is not null
		end

		/*	Get all pertinent data for objects to receive. */
		set @TocMsg = 'Get all pertinent data for objects to receive'
		begin
			declare
				@objectsToReceive table
			(	ReceiverObjectID int primary key
			,	Serial int
			,	PartCode varchar(25)
			,	Lot varchar(50)
			,	Location varchar(20)
			,	UnitMeasure char(2)
			,	Status char(1)
			,	ShipperID varchar(50)
			,	Price numeric(20,6)
			,	Cost numeric(20,6)
			,	Note varchar(254)
			,	PONumber int
			,	ReleaseNo varchar(15)
			,	Vendor varchar(10)
			,	PartDescription varchar(50)
			,	Plant varchar(10)
			,	Quantity numeric(20,6)
			,	PackageType varchar(25)
			,	TareWeight numeric(20,6)
			,	StandardQty numeric(20,6)
			,	GLAccountCode varchar(50)
			,	UserDefinedStatus varchar(25)
			,	LicensePlate varchar(50)
			)

			insert
				@objectsToReceive
			(	ReceiverObjectID
			,	PartCode
			,	Lot
			,	Location
			,	UnitMeasure
			,	Status
			,	ShipperID
			,	Price
			,	Cost
			,	Note
			,	PONumber
			,	ReleaseNo
			,	Vendor
			,	PartDescription
			,	Plant
			,	Quantity
			,	PackageType
			,	TareWeight
			,	StandardQty
			,	GLAccountCode
			,	UserDefinedStatus
			,	LicensePlate
			)
			select
				ReceiverObjectID = ro.ReceiverObjectID
			,	PartCode = ro.PartCode
			,	Lot = ro.Lot
			,	Location = ro.Location
			,	UnitMeasure = pInv.standard_unit
			,	Status = 'P'
			,	ShipperID = rh.ConfirmedSID
			,	Price = pd.price
			,	Cost = ps.cost_cum
			,	Note = ro.Note
			,	PONumber = ro.PONumber
			,	ReleaseNo = convert(varchar(15), pd.release_no)
			,	Vendor = ph.vendor_code
			,	PartDescription = ro.PartDescription
			,	Plant = rh.Plant
			,	Quantity = ro.QtyObject
			,	PackageType = ro.PackageType
			,	TareWeight = coalesce(pm.weight, 0)
			,	StandardQty = ro.QtyObject
			,	GLAccountCode = ro.DrAccount
			,	UserDefinedStatus = 'Approved'
			,	LicensePlate = ro.SupplierLicensePlate
			from
				#receiverObjectList rol
				join dbo.ReceiverObjects ro
					on ro.ReceiverObjectID = rol.ReceiverObjectID
				join dbo.ReceiverLines rl
					on rl.ReceiverLineID = ro.ReceiverLineID
				join dbo.ReceiverHeaders rh
					on rh.ReceiverID = rl.ReceiverID
				join dbo.part p
					on p.part = ro.PartCode
				join dbo.part_inventory pInv
					on pInv.part = ro.PartCode
				join dbo.part_standard ps
					on ps.part = ro.PartCode
				join dbo.po_header ph
					on ph.po_number = ro.PONumber
				join dbo.po_detail pd
					on pd.po_number = ro.PONumber
					and pd.part_number = ro.PartCode
					and pd.date_due = ro.POLineDueDate
					and pd.row_id = ro.POLineNo
				left join dbo.package_materials pm
					on pm.code = ro.PackageType
			where
				ro.Status = 0
				and rh.Status in (0, 1, 2, 3, 4) -- 'New, Cofirmed, Shipped, 

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

		/*	Get block of serials and assign to new objects. */
		set @TocMsg = 'Get block of serials and assign to new objects'

		declare
			@objectCount int =
				(	select
						count(*)
					from
						@objectsToReceive
				)
			,	@firstNewSerial int

		if	@objectCount = 0 begin
			goto done
		end
		begin
			--- <Call>	
			set	@CallProcName = 'monitor.usp_NewSerialBlock'
				
			execute @ProcReturn = monitor.usp_NewSerialBlock
					@SerialBlockSize = @objectCount
				,	@FirstNewSerial = @firstNewSerial out
				,	@Result = @ProcResult out
				
			set	@Error = @@error
			if	@Error != 0 begin
				set	@Result = 900501
				raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			end
			if	@ProcReturn != 0 begin
				set	@Result = 900502
				raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			end
			if	@ProcResult != 0 begin
				set	@Result = 900502
				raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			end
			--- </Call>

			update
				otr
			set	Serial = otrLine.Serial
			from
				@objectsToReceive otr
				join
					(	select
							otr.ReceiverObjectID
						,	Serial = @firstNewSerial + row_number() over(order by otr.ReceiverObjectID) - 1
						from
							@objectsToReceive otr
					) otrLine
					on otrLine.ReceiverObjectID = otr.ReceiverObjectID

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

		/*	Create objects for all receiver objects belonging to this receiver. */
		set @TocMsg = 'Create objects for all receiver objects belonging to this receiver'
		begin
			insert
				dbo.object
			(	serial, part, lot, location
			,	last_date, unit_measure, operator
			,	status
			,	origin, cost, note, po_number
			,	name, plant, quantity, last_time
			,	package_type, std_quantity
			,	custom1, custom2, custom3, custom4, custom5
			,	user_defined_status
			,	std_cost, field1
			,	SupplierLicensePlate
			)
			select
				otr.Serial, otr.PartCode, otr.Lot, otr.Location
			,	@TranDT, otr.UnitMeasure, @User
			,	otr.Status
			,	otr.ShipperID, otr.Price, otr.Note, convert(varchar, otr.PONumber)
			,	otr.PartDescription, otr.Plant, otr.Quantity, @TranDT
			,	otr.PackageType, otr.StandardQty
			,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
			,	otr.UserDefinedStatus
			,	otr.Cost, '' /*field1*/
			,	LicensePlate = otr.LicensePlate
			from
				@objectsToReceive otr
			
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

		/*	Write audit trail for all receiver objects belonging to this receiver. */
		set @TocMsg = 'Write audit trail for all receiver objects belonging to this receiver'
		begin
			insert
				dbo.audit_trail
			(	serial, date_stamp, type, part
			,	quantity, remarks, price, vendor
			,	po_number, operator, from_loc, to_loc
			,	on_hand, lot
			,	weight
			,	status
			,	shipper, unit, std_quantity, cost, control_number
			,	custom1, custom2, custom3, custom4, custom5
			,	plant, notes, gl_account, package_type
			,	release_no, std_cost
			,	user_defined_status
			,	part_name, tare_weight, field1
			)
			select
				otr.Serial, @TranDT, 'R', otr.PartCode
			,	otr.Quantity, 'Receipt', otr.Price, otr.Vendor
			,	convert(varchar, otr.PONumber), @User, otr.Vendor, otr.Location
			,	dbo.udf_GetPartQtyOnHand(otr.PartCode), otr.Lot
			,	dbo.fn_Inventory_GetPartNetWeight(otr.PartCode, otr.StandardQty)
			,	otr.Status
			,	otr.ShipperID, otr.UnitMeasure, otr.StandardQty, otr.Cost, null
			,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
			,	otr.Plant, otr.Note, otr.GLAccountCode, otr.PackageType
			,	otr.ReleaseNo, otr.Cost
			,	otr.UserDefinedStatus
			,	otr.PartDescription, otr.TareWeight, '' /*field1*/
			from
				@objectsToReceive otr
			
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

		/*	Update part online. */
		set @TocMsg = 'Update part online'
		begin
			update
				po
			set
				po.on_hand = dbo.udf_GetPartQtyOnHand(po.part)
			from
				dbo.part_online po
				join @objectsToReceive otr
					on otr.PartCode = po.part
			
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

		/*	Process receipt against POs. */
		set @TocMsg = 'Process receipt against POs'
		begin
			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_Purchasing_AddReceipt_byReceiverObjectList'
			
			execute @ProcReturn = SUPPLIEREDI.usp_Purchasing_AddReceipt_byReceiverObjectList
					@User = @User
				,	@ReceiverObjectID = null
				,	@TranDT = @TranDT out
				,	@Result = @ProcResult out
			
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
		
		/*	Update receiver object, line, and header. */
		set @TocMsg = 'Update receiver object, line, and header'
		begin
			update
				ro
			set	ro.Status = 1 --(select dbo.udf_StatusValue('ReceiverObjects', 'Received'))
			,	ro.Serial = otr.Serial
			,	ro.ReceiveDT = @TranDT
			from
				dbo.ReceiverObjects ro
				join @objectsToReceive otr
					on otr.ReceiverObjectID = ro.ReceiverObjectID
			
			update
				rl
			set
				rl.Status =
					case
						when rb.RemainingBoxes = 0 then 4 --(select dbo.udf_StatusValue ('ReceiverLines', 'Received'))
						else rl.Status
					end,
				rl.ReceiptDT =
					case
						when rb.RemainingBoxes = 0 then @TranDT
						else rl.ReceiptDT
					end,
				rl.RemainingBoxes = rb.RemainingBoxes
			from
				dbo.ReceiverLines rl
				outer apply
					(	select
							RemainingBoxes = count(*)
						from
							dbo.ReceiverObjects ro2
						where
							ro2.ReceiverLineID = rl.ReceiverLineID
							and ro2.Status = 0
					) rb
			where
				exists
					(	select
							*
						from
							dbo.ReceiverObjects ro
							join @objectsToReceive otr
								on otr.ReceiverObjectID = ro.ReceiverObjectID
						where
							rl.ReceiverLineID = ro.ReceiverLineID
					)

			update
				rh
			set
				rh.Status =
					case
						when rb.RemainingBoxes = 0 then 5 --(select dbo.udf_StatusValue ('ReceiverHeaders', 'Put Away'))
						else rh.Status
					end
			,	rh.ReceiveDT =
					case
						when rb.RemainingBoxes = 0 then @TranDT
						when rh.Status < 3 --(select dbo.udf_StatusValue ('ReceiverHeaders', 'Arrived'))
							then 3 --(select dbo.udf_StatusValue ('ReceiverHeaders', 'Arrived'))
						else rh.ReceiveDT
					end
			from
				dbo.ReceiverHeaders rh
				outer apply
					(	select
							RemainingBoxes = sum(rl2.RemainingBoxes)
						from
							dbo.ReceiverLines rl2
						where
							rl2.ReceiverID= rh.ReceiverID
					) rb
			where
				exists
					(	select
							*
						from
							dbo.ReceiverLines rl
							join dbo.ReceiverObjects ro
								on rl.ReceiverLineID = ro.ReceiverLineID
							join @objectsToReceive otr
								on otr.ReceiverObjectID = ro.ReceiverObjectID
						where
							rl.ReceiverID = rh.ReceiverID
					)

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

		/*	Backflush. */
		set @TocMsg = 'Backflush'
		begin
			insert
				dbo.BackflushHeaders
			(	TranDT
			,	WorkOrderNumber
			,	WorkOrderDetailLine
			,	MachineCode
			,	PartProduced
			,	SerialProduced
			,	QtyProduced
			)
			select
				TranDT = @TranDT
			,	WorkOrderNumber = null
			,	WorkOrderDetailLine = null
			,	MachineCode = rh.ShipFrom
			,	PartProduced = ro.PartCode
			,	SerialProduced = ro.Serial
			,	QtyProduced = ro.QtyObject
			from
				@objectsToReceive otr
				join dbo.ReceiverObjects ro
					on ro.ReceiverObjectID = otr.ReceiverObjectID
				join dbo.ReceiverLines rl
					on rl.ReceiverLineID = ro.ReceiverLineID
				join dbo.ReceiverHeaders rh
					on rh.ReceiverID = rl.ReceiverID
			where
				rh.Type = 3 -- (select dbo.udf_TypeValue ('ReceiverHeaders', 'Outside Process'))
			
			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_ReceivingDock_Backflush_byReceiverObjectList'
			
			execute @ProcReturn = SUPPLIEREDI.usp_ReceivingDock_Backflush_byReceiverObjectList
					@User = @User
				,	@ReceiverObjectID = null
				,	@TranDT = @TranDT out
				,	@Result = @ProcResult out
				,	@Debug = @cDebug
				,	@DebugMsg = @cDebugMsg out
			
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
		
		/*	Send email report.*/
		
		--- </Body>

		done:
		---	<CloseTran AutoCommit=Yes>
		if	@TranCount = 0 begin
			commit tran @ProcName
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

--declare
--	@FinishedPart varchar(25) = 'ALC0598-HC02'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_ProcessReceiver_byReceiverObjectList
	@TranDT = @TranDT out
,	@Result = @ProcResult out

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
