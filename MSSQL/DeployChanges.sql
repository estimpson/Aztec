
/*
Create Synonym.FxAztec.FXSYS.usp_TableToHTML.sql
*/

use FxAztec
go

--	drop procedure FXSYS.usp_TableToHTML
--	select objectpropertyex(object_id('FXSYS.usp_TableToHTML'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.usp_TableToHTML'), 'BaseType') = 'P' begin
	drop synonym FXSYS.usp_TableToHTML
end
go

create synonym FXSYS.usp_TableToHTML for FxSYS.dbo.usp_TableToHTML
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Process.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Process'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Process
end
go

create procedure SUPPLIEREDI.usp_Process
	@TranDT datetime = null out
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

	insert
		FXSYS.USP_Calls
	(	USP_Name
	,	BeginDT
	,	InArguments
	)
	select
		--USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
		USP_Name = 'SUPPLIEREDI.usp_Process'
	,	BeginDT = getdate()
	,	InArguments = convert
			(	varchar(max)
			,	(	select
						[@TranDT] = @TranDT
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
		/*	Create structure for email report. */
		if	object_id('tempdb..#emailReport') is null begin
			create table
				#emailReport
			(	RowID int not null IDENTITY(1, 1) primary key
			,	ShortStatus varchar(15)
			,	Description varchar(255)
			)
		end

		/*	Get data for all Ship Notices that are ready to process. */
		set @TocMsg = 'Get a list of Ship Notices that are ready to process'
		begin
			declare
				@ShipNotices table
			(	RawDocumentGUID uniqueidentifier not null
			,	SNRowID int not null
			,	SNLRowID int not null
			,	SNORowID int not null
			,	ShipperID varchar(50) not null
			,	BillOfLadingNumber varchar(50) null
			,	ShipFromCode varchar(50) null
			,	ShipToCode varchar(50) null
			,	ShipDT datetime null
			,	SupplierPart varchar(50) not null
			,	PurchaseOrderRef varchar(50) null
			,	Quantity numeric(20,6) not null
			,	PartCode varchar(25) not null
			,	PurchaseOrderNumber int not null
			,	SupplierSerial varchar(50) null
			,	SupplierParentSerial varchar(50) null
			,	SupplierPackageType varchar(50) null
			,	SupplierLot varchar(50) null
			,	ObjectQuantity numeric(20,6) not null
			,	ObjectSerial int null
			,	ObjectParentSerial int null
			,	ObjectPackageType varchar(25) null
			,	OutsideProcess bit
			)

			insert
				@ShipNotices
			(	RawDocumentGUID
			,	SNRowID
			,	ShipperID
			,	BillOfLadingNumber
			,	ShipFromCode
			,	ShipToCode
			,	ShipDT
			,	SNLRowID
			,	SupplierPart
			,	PurchaseOrderRef
			,	Quantity
			,	PartCode
			,	PurchaseOrderNumber
			,	SNORowID
			,	SupplierSerial
			,	SupplierParentSerial
			,	SupplierPackageType
			,	SupplierLot
			,	ObjectQuantity
			,	ObjectSerial
			,	ObjectParentSerial
			,	ObjectPackageType
			,	OutsideProcess
			)
			select
				sn.RawDocumentGUID
			,	sn.RowID
			,	sn.ShipperID
			,	sn.BillOfLadingNumber
			,	sn.ShipFromCode
			,	sn.ShipToCode
			,	sn.ShipDT
			,	snl.RowID
			,	snl.SupplierPart
			,	snl.PurchaseOrderRef
			,	snl.Quantity
			,	snl.PartCode
			,	snl.PurchaseOrderNumber
			,	sno.RowID
			,	sno.SupplierSerial
			,	sno.SupplierParentSerial
			,	sno.SupplierPackageType
			,	sno.SupplierLot
			,	sno.ObjectQuantity
			,	sno.ObjectSerial
			,	sno.ObjectParentSerial
			,	sno.ObjectPackageType
			,	OutsideProcess = case when OP.OP = 1 then 1 else 0 end
			from
				SUPPLIEREDI.ShipNotices sn with (tablockx)
				join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
					on snl.RawDocumentGUID = sn.RawDocumentGUID
				join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
					on sno.RawDocumentGUID = sn.RawDocumentGUID
					and sno.SupplierPart = snl.SupplierPart
				outer apply
				(	select top(1)
						OP = 1
					from
						dbo.part_machine pmOP
					where
						pmOP.part = snl.PartCode
						and pmOP.machine = sn.ShipFromCode
					order by
						pmOP.sequence
				) OP
			where
				sn.Status = 0
				and snl.Quantity is not null
				and snl.PurchaseOrderNumber is not null
				and snl.PartCode is not null
				and sno.ObjectQuantity is not null

			insert
				#emailReport
			(	ShortStatus
			,	Description
			)
			select
				ShortStatus = 'N/A'
			,	Description = 'Process ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end
			from
				(	select
						FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn
					where
						sn.Status = 0
				) summary

			insert
				#emailReport
			(	ShortStatus
			,	Description
			)
			select
				ShortStatus = 'N/A'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn
					where
						sn.Status = 0
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
				) summary

			insert
				#emailReport
			(	ShortStatus
			,	Description
			)
			select
				ShortStatus = 'FAILURE'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with missing line quantity. '
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn with (tablockx)
						join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
							on snl.RawDocumentGUID = sn.RawDocumentGUID
						join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
							on sno.RawDocumentGUID = sn.RawDocumentGUID
							and sno.SupplierPart = snl.SupplierPart
					where
						sn.Status = 0
						and snl.Quantity is null
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
				) summary
			union all
			select
				ShortStatus = 'FAILURE'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with missing purchase order number. '
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn with (tablockx)
						join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
							on snl.RawDocumentGUID = sn.RawDocumentGUID
						join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
							on sno.RawDocumentGUID = sn.RawDocumentGUID
							and sno.SupplierPart = snl.SupplierPart
					where
						sn.Status = 0
						and snl.PurchaseOrderNumber is null
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
				) summary
			union all
			select
				ShortStatus = 'FAILURE'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with missing part number. '
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn with (tablockx)
						join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
							on snl.RawDocumentGUID = sn.RawDocumentGUID
						join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
							on sno.RawDocumentGUID = sn.RawDocumentGUID
							and sno.SupplierPart = snl.SupplierPart
					where
						sn.Status = 0
						and snl.PartCode is null
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
				) summary
			union all
			select
				ShortStatus = 'FAILURE'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with missing object quantity. '
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						SUPPLIEREDI.ShipNotices sn with (tablockx)
						join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
							on snl.RawDocumentGUID = sn.RawDocumentGUID
						join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
							on sno.RawDocumentGUID = sn.RawDocumentGUID
							and sno.SupplierPart = snl.SupplierPart
					where
						sn.Status = 0
						and sno.ObjectQuantity is null
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
				) summary

			if	not exists
				(	select
		  				*
		  			from
		  				@ShipNotices sn
		  		) begin
				goto done
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

		/*	Create receiver headers. */
		set @TocMsg = 'Create receiver headers'
		begin
			declare
				@newReceiverHeaders table
			(	ReceiverId int primary key
			,	ShipFrom varchar(20)
			,	Plant varchar(10)
			,	ConfirmedShipDT datetime
			,	ConfirmedSID varchar(50)
			,	TrackingNumber varchar(50)
			,	SupplierASNGuid uniqueidentifier
			)

			insert
				dbo.ReceiverHeaders
			(	ReceiverNumber
			,	Type
			,	Status
			,	ShipFrom
			,	Plant
			,	ExpectedReceiveDT
			,	ConfirmedShipDT
			,	ConfirmedSID
			,	ConfirmedArrivalDT
			,	TrackingNumber
			,	ActualArrivalDT
			,	ReceiveDT
			,	PutawayDT
			,	SupplierASNGuid
			)
			output
				Inserted.ReceiverID
			,	Inserted.ShipFrom
			,	Inserted.Plant
			,	Inserted.ConfirmedShipDT
			,	Inserted.ConfirmedSID
			,	Inserted.TrackingNumber
			,	Inserted.SupplierASNGuid
			into
				@newReceiverHeaders
			select distinct
				ReceiverNumber = 0
			,	Type =
					case
						when sn.OutsideProcess = 0 then 1  -- (select dbo.udf_TypeValue ('ReceiverHeaders', 'Purchase Order'))
						else 3 -- (select dbo.udf_TypeValue ('ReceiverHeaders', 'Outside Process'))
					end
			,	Status = 0 -- (select dbo.udf_StatusValue ('ReceiverHeaders', 'New'))
			,	ShipFrom = sn.ShipFromCode
			,	Plant = sn.ShipToCode
			,	ExpectedReceiveDT = sn.ShipDT + 365
			,	ConfirmedShipDT = sn.ShipDT
			,	ConfirmedSID = sn.ShipperID
			,	ConfirmedArrivalDT = null
			,	TrackingNumber =sn.BillOfLadingNumber
			,	ActualArrivalDT = null
			,	ReceiveDT = null
			,	PutawayDT = null
			,	SupplierASNGuid = sn.RawDocumentGUID
			from
				@ShipNotices sn

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

		/*	Create receiver lines. */
		set @TocMsg = 'Create receiver lines'
		begin
			declare
				@newReceiverLines table
			(	ReceiverId int
			,	ReceiverLineId int
			,	PONumber int
			,	PartCode varchar(25)
			,	POLineNo int
			,	POLineDueDate datetime
			)

			insert
				dbo.ReceiverLines
			(	ReceiverID
			,	[LineNo]
			,	PartCode
			,	PONumber
			,	POLineNo
			,	POLineDueDate
			,	PackageType
			,	RemainingBoxes
			,	StdPackQty
			,	SupplierLotNumber
			,	ArrivalDT
			)
			output
				Inserted.ReceiverID
			,	Inserted.ReceiverLineID
			,	Inserted.PONumber
			,	Inserted.PartCode
			,	Inserted.POLineNo
			,	Inserted.POLineDueDate
			into
				@newReceiverLines
			select
				nl.ReceiverID
			,	[LineNo] = row_number() over (partition by nl.ReceiverID order by nl.PartCode)
			,	nl.PartCode
			,	nl.PONumber
			,	nl.POLineNo
			,	nl.POLineDueDate
			,	nl.PackageType
			,	nl.RemainingBoxes
			,	nl.StdPackQty
			,	nl.SupplierLotNumber
			,	nl.ArrivalDT
			from
				(	select distinct
						ReceiverID = nrh.ReceiverId
					,	PartCode = sn.PartCode
					,	PONumber = sn.PurchaseOrderNumber
					,	POLineNo = pd.row_id
					,	POLineDueDate = pd.date_due
					,	PackageType = null
					,	RemainingBoxes =
							(	select
									count(*)
								from
									@ShipNotices sn2
								where
									sn2.PurchaseOrderNumber = sn.PurchaseOrderNumber
									and sn2.PartCode = sn.PartCode
									and sn2.ShipFromCode = sn.ShipFromCode
									and sn2.ShipToCode = sn.ShipToCode
									and sn2.ShipDT = sn.ShipDT
									and sn2.ShipperID = sn.ShipperID
									and sn2.BillOfLadingNumber =sn.BillOfLadingNumber
									and sn2.RawDocumentGUID = sn.RawDocumentGUID
							)
					,	StdPackQty = sn.Quantity
					,	SupplierLotNumber = null
					,	ArrivalDT = sn.ShipDT
					from
						@ShipNotices sn
						join @newReceiverHeaders nrh
							on nrh.ShipFrom = sn.ShipFromCode
								and nrh.Plant = sn.ShipToCode
								and nrh.ConfirmedShipDT = sn.ShipDT
								and nrh.ConfirmedSID = sn.ShipperID
								and nrh.TrackingNumber =sn.BillOfLadingNumber
								and nrh.SupplierASNGuid = sn.RawDocumentGUID
						cross apply
							(	select top 1
									pd.row_id
								,	pd.date_due
								from
									dbo.po_detail pd
								where
									pd.po_number = sn.PurchaseOrderNumber
									and pd.part_number = sn.PartCode
									and pd.balance > 0
								order by
									pd.date_due
								,	pd.row_id
							) pd
				) nl

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

		/*	Create receiver object. */
		declare
			@newReceiverObjects table
		(	ReceiverObjectID int primary key
		,	SupplierLicensePlate varchar(50)
		)

		set @TocMsg = 'Create receiver object'
		begin
			insert
				dbo.ReceiverObjects
			(	ReceiverLineID
			,	[LineNo]
			,	Status
			,	PONumber
			,	POLineNo
			,	POLineDueDate
			,	Serial
			,	PartCode
			,	PartDescription
			,	EngineeringLevel
			,	QtyObject
			,	PackageType
			,	Location
			,	Plant
			,	ParentSerial
			,	DrAccount
			,	CrAccount
			,	Lot
			,	Note
			,	UserDefinedStatus
			,	ReceiveDT
			,	ParentLicensePlate
			,	SupplierLicensePlate
			)
			output
				Inserted.ReceiverObjectID
			,	Inserted.SupplierLicensePlate
			into
				@newReceiverObjects
			select
				ReceiverLineID = nrl.ReceiverLineId
			,	[LineNo] = row_number() over (partition by nrl.ReceiverLineId order by sn.ObjectSerial)
			,	Status = 0
			,	PONumber = sn.PurchaseOrderNumber
			,	POLineNo = nrl.POLineNo
			,	POLineDueDate = nrl.POLineDueDate
			,	Serial = null
			,	PartCode = sn.PartCode
			,	PartDescription = p.name
			,	EngineeringLevel = null
			,	QtyObject = sn.ObjectQuantity
			,	PackageType = sn.ObjectPackageType
			,	Location = sn.ShipToCode
			,	Plant = sn.ShipToCode
			,	ParentSerial = null
			,	DrAccount = null
			,	CrAccount = null
			,	Lot = sn.ShipperID
			,	Note = 'Reciever object created via supplier ship notice. '
			,	UserDefinedStatus = null
			,	ReceiveDT = null
			,	ParentLicensePlate = null
			,	SupplierLicensePlate = sn.ShipFromCode + '_' + sn.SupplierSerial
			from
				@ShipNotices sn
				join @newReceiverHeaders nrh
					on nrh.ShipFrom = sn.ShipFromCode
						and nrh.Plant = sn.ShipToCode
						and nrh.ConfirmedShipDT = sn.ShipDT
						and nrh.ConfirmedSID = sn.ShipperID
						and nrh.TrackingNumber =sn.BillOfLadingNumber
						and nrh.SupplierASNGuid = sn.RawDocumentGUID
				join @newReceiverLines nrl
					on nrl.ReceiverId = nrh.ReceiverId
					and nrl.PONumber = sn.PurchaseOrderNumber
					and nrl.PartCode = sn.PartCode
				join dbo.part p
					on p.part = sn.PartCode

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

		/*	Process receiver. */
		set @TocMsg = 'Process receiver'
		begin
			create table
				#receiverObjectList
			(	ReceiverObjectID int primary key
			)

			insert
				#receiverObjectList
			(	ReceiverObjectID
			)
			select
				nro.ReceiverObjectID
			from
				@newReceiverObjects nro

			declare
				@user varchar(5) =
					(	select top (1)
							ph.vendor_code
						from
							@ShipNotices sn
							join dbo.po_header ph
								on ph.po_number = sn.PurchaseOrderNumber
						order by
							ph.vendor_code
					)

			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_ProcessReceiver_byReceiverObjectList'
			execute
				@ProcReturn = SUPPLIEREDI.usp_ProcessReceiver_byReceiverObjectList
					@User = @user
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
		
		/*	Mark Ship Notice as processed. */
		set @TocMsg = 'Mark Ship Notice as processed'
		begin
			update
				sno
			set
				sno.Status = ro.Status
			from
				SUPPLIEREDI.ShipNoticeObjects sno
				join @ShipNotices sn
					join @newReceiverObjects nro
						join dbo.ReceiverObjects ro
							on ro.ReceiverObjectID = nro.ReceiverObjectID
						on nro.SupplierLicensePlate = sn.ShipFromCode + '_' + sn.SupplierSerial
					on sn.RawDocumentGUID = sno.RawDocumentGUID
					and sn.SNORowID = sno.RowID
			
			update
				snl
			set
				snl.Status = rl.Status
			from
				SUPPLIEREDI.ShipNoticeLines snl
				join @ShipNotices sn
					join @newReceiverLines nrl
						join dbo.ReceiverLines rl
							join dbo.ReceiverHeaders rh
								on rh.ReceiverID = rl.ReceiverID
							on rl.ReceiverLineID = nrl.ReceiverLineId
						on nrl.PONumber = sn.PurchaseOrderNumber
						and nrl.PartCode = sn.PartCode
						and rh.SupplierASNGuid = sn.RawDocumentGUID
					on sn.SNLRowID = snl.RowID

			update
				sn
			set
				sn.Status = rh.Status
			from
				SUPPLIEREDI.ShipNotices sn
				join @ShipNotices sn2
					join dbo.ReceiverHeaders rh
						on rh.SupplierASNGuid = sn2.RawDocumentGUID
					on sn2.SNRowID = sn.RowID
			
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
		set @TocMsg = 'Send email report'
		begin
			insert
				#emailReport
			(	ShortStatus
			,	Description
			)
			select
				ShortStatus = 'FAILURE'
			,	Description = 'Contains ' +
					case
						when summary.FileCount = 1 then '1 file'
						else convert(varchar(3), summary.FileCount) + ' files'
					end +
					' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with invalid PO ' + convert(varchar(12), summary.PurchaseOrderNumber) + ' and/or part ' + summary.PartCode + ' combination or no releases. '
			from
				(	select
						sn.ShipFromCode
					,	sn.ShipToCode
					,	sn.PurchaseOrderNumber
					,	sn.PartCode
					,	FileCount = count(distinct sn.RawDocumentGUID)
					from
						@ShipNotices sn
					where
						not exists
							(	select
									*
								from
									dbo.po_detail pd
								where
									pd.po_number = sn.PurchaseOrderNumber
									and pd.part_number = sn.PartCode
									and pd.balance > 0
							)
					group by
						sn.ShipFromCode
					,	sn.ShipToCode
					,	sn.PurchaseOrderNumber
					,	sn.PartCode
				) summary
		
				declare
					@html nvarchar(max)
			
			--- <Call>	
			set	@CallProcName = 'FXSYS.usp_TableToHTML'
			execute
				@ProcReturn = FXSYS.usp_TableToHTML
					@TableName = '#emailReport'
				,	@OrderBy = N'RowId'
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
				@emailHeader nvarchar(max) =
					case
						when db_name(db_id()) = 'FxAztec' then ''
						else 'TEST DB: '
					end + N'Procces ASN Report from Fx Supplier Portal'

			declare
				@emailBody nvarchar(max) = N'<H1>' + @emailHeader + N'</H1>' + @html
			,	@profileName sysname = 'fxAlerts'
			,	@recipients sysname = 'estimpson@fore-thought.com'
			,	@copyRecipients sysname

			exec msdb.dbo.sp_send_dbmail
				@profile_name = @profileName
			,	@recipients = @recipients
			,	@copy_recipients = @copyRecipients
			,	@subject = @emailHeader
			,	@body = @emailBody
			,	@body_format = 'HTML'
			,	@importance = 'HIGH'
			,	@exclude_query_output = 1

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

		execute FXSYS.usp_EmailError
			@Recipients = 'edialerts@aztecmfgcorp.com'
		,	@CopyRecipients = 'rjohnson@aztecmfgcorp.com;estimpson@fore-thought.com'

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
	@ProcReturn = SUPPLIEREDI.usp_Process
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Receiver_byReceiverObjectList.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Receiver_byReceiverObjectList'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Receiver_byReceiverObjectList
end
go

create procedure SUPPLIEREDI.usp_Receiver_byReceiverObjectList
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
	@ProcReturn = SUPPLIEREDI.usp_Receiver_byReceiverObjectList
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_CancelEdiShipper.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_CancelEdiShipper'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_CancelEdiShipper
end
go

create procedure SUPPLIEREDI.usp_Waupaca_CancelEdiShipper
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Cancel shipper. */
		set @TocMsg = 'Cancel shipper'
		begin
			--- <Update rows="1+">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = -1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				snh.Status = 0
				and exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

		/*	Cancel all lines on shipper. */
		set @TocMsg = 'Cancel all lines on shipper'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = -1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

set ansi_warnings off
set nocount on

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'F13C6A11-32AF-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_CancelEdiShipper
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_CancelEdiShipperLine.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_CancelEdiShipperLine'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_CancelEdiShipperLine
end
go

create procedure SUPPLIEREDI.usp_Waupaca_CancelEdiShipperLine
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
,	@RowIDList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
					,	[@RowIDList] = @RowIDList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Cancel shipper line. */
		set @TocMsg = 'Cancel shipper line'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = -1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RowIDList, ',') rows
					where
						convert(int, rows.value) = snl.RowID
				)
				and exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

		/*	Cancel shipper if all lines are cancelled. */
		set	@TocMsg = 'Cancel shipper if all lines are cancelled'
		if	(	select
					max(snl.Status)
				from
					FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
					join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
						on snh.RawDocumentGUID = snl.RawDocumentGUID
				where
					exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
					)
			) = -1 begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = -1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'
,	@RowIDList varchar(max) = '223, 226, 222, 225'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_CancelEdiShipperLine
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@RowIDList = @RowIDList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@ShowNew = 1
,	@ShowDeleted = 1
,	@ShowCompleted = 1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
go

--commit
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
end
go

create procedure SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
	@RawDocumentGuidList varchar(max)
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
						[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Return list of receiver details. */
		set @TocMsg = 'Return list of receiver details'
		begin
			select
				rh.ReceiverID
			,	rh.ReceiverNumber
			,	rh.Type
			,	rh.Status
			,	rh.ShipFrom
			,	rh.Plant
			,	rh.ConfirmedSID
			,	rh.TrackingNumber
			,	rh.ReceiveDT
			,	rh.PutawayDT
			,	rh.Note
			,	rh.SupplierASNGuid
			,	rl.PartCode
			,	rl.PONumber
			,	ro.Serial
			,	ro.QtyObject
			,	ro.Lot
			from
				dbo.ReceiverHeaders rh
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
				join dbo.ReceiverObjects ro
					on ro.ReceiverLineID = rl.ReceiverLineID
					and ro.Serial > 0
			where
				exists
				(	select
						*
					from
						SUPPLIEREDI.WaupacaShipNotices wsn
						join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
							on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
						join dbo.po_header ph
							on ph.po_number = wsnl.PurchaseOrderNumber
						left join dbo.part_vendor pv
							on pv.vendor = wsn.ShipFromCode
							and pv.part = wsnl.PartCode
						join
						(	select
								RawDocumentGUID = convert(uniqueidentifier, rows.Value)
							from
								dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						) docs on docs.RawDocumentGUID = wsnl.RawDocumentGUID
					where
						rh.ConfirmedSID = wsn.ShipperID
						and rh.ShipFrom = wsn.ShipFromCode
						and rh.Plant = ph.ship_to_destination
				)
			order by
				rl.PartCode

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

		---	<CloseTran Implicit=Yes>
		if	(2 & @@OPTIONS) = 1 begin
			commit tran
		end
		---	</CloseTran Implicit=Yes>

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

declare
	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
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
go


declare
	@RawDocumentGuidList varchar(max) = '69716FAF-47AF-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@ERROR

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@TRANCOUNT > 0 begin
	rollback
end
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_GetShipNoticeAlerts_byRawDocumentGuidList.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_GetShipNoticeAlerts_byRawDocumentGuidList'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_GetShipNoticeAlerts_byRawDocumentGuidList
end
go

create procedure SUPPLIEREDI.usp_Waupaca_GetShipNoticeAlerts_byRawDocumentGuidList
	@RawDocumentGuidList varchar(max)
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
						[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Return list of ship notice alerts. */
		set @TocMsg = 'Return list of ship notice alerts'
		begin
			select
				wsna.Type
			,	wsna.Alert
			,	wsna.RawDocumentGUID
			,	wsna.ShipperID
			,	wsna.BillOfLadingNumber
			,	wsna.ShipFromCode
			,	wsna.ShipToCode
			,	wsna.ShipDT
			,	wsna.Description
			,	wsna.Data
			from
				SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
			where
				wsna.Status = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsna.RawDocumentGUID
					)
			order by
				wsna.Type

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

		---	<CloseTran Implicit=Yes>
		if	(2 & @@OPTIONS) = 1 begin
			commit tran
		end
		---	</CloseTran Implicit=Yes>

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

declare
	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeAlerts_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
end
go

create procedure SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList varchar(max)
,	@ShowNew tinyint = 1
,	@ShowDeleted tinyint = 0
,	@ShowCompleted tinyint = 0
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on

	---	<CloseTran Implicit=No>
	if	(2 & @@OPTIONS) = 1 begin
		set implicit_transactions off
		commit
	end
	---	</CloseTran Implicit=Yes>

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
						[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Return list of ship notice lines. */
		set @TocMsg = 'Return list of ship notice lines'
		begin
			select
				wsnl.Status
			,	SupplierPartRef = wsnl.SupplierPart
			,	SupplierPart = pv.vendor_part
			,	wsnl.PurchaseOrderRef
			,	wsnl.PurchaseOrderNumber
			,	wsnl.PartCode
			,	wsnl.Quantity
			,	wsnl.RawDocumentGUID
			,	wsnl.RowID
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
					and wsn.ShipperLineStatus= wsn.Status
				left join dbo.part_vendor pv
					on pv.vendor = wsn.ShipFromCode
					and pv.part = wsnl.PartCode
				join
				(	select
						RawDocumentGUID = convert(uniqueidentifier, rows.Value)
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
				) docs on docs.RawDocumentGUID = wsnl.RawDocumentGUID
			where
				(	@ShowNew = 1
					and wsnl.Status = 0
				)
				or
				(	@ShowDeleted = 1
					and wsnl.Status < 0
				)
				or
				(	@ShowCompleted = 1
					and wsnl.Status > 0
				)
			order by
				wsnl.PartCode

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

		---	<CloseTran Implicit=Yes>
		if	(2 & @@OPTIONS) = 1 begin
			commit tran
		end
		---	</CloseTran Implicit=Yes>

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

declare
	@RawDocumentGuidList varchar(max) = '69716FAF-47AF-EA11-8121-005056A166E5'
,	@ShowNew tinyint = 1
,	@ShowDeleted tinyint = 1
,	@ShowCompleted tinyint = 0

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@ShowNew = @ShowNew
,	@ShowDeleted = @ShowDeleted
,	@ShowCompleted = @ShowCompleted
,	@TranDT = @TranDT out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_GetShipNotices.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_GetShipNotices'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_GetShipNotices
end
go

create procedure SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@ShowNew tinyint = 1
,	@ShowDeleted tinyint = 0
,	@ShowCompleted tinyint = 0
,	@TranDT datetime = null out
,	@Result integer = null out
,	@Debug int = 0
,	@DebugMsg varchar(max) = null out
as
begin

	--set xact_abort on
	set nocount on

	---	<CloseTran Implicit=No>
	if	(2 & @@OPTIONS) = 1 begin
		set implicit_transactions off
		commit
	end
	---	</CloseTran Implicit=Yes>

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
						[@TranDT] = @TranDT
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Return list of ship notice alerts. */
		set @TocMsg = 'Return list of ship notice alerts'
		begin
			select
				wsn.ShipperID
			,	wsn.Status
			,	wsn.BillOfLadingNumber
			,	wsn.ShipFromCode
			,	wsn.ShipToCode
			,	wsn.ShipDT
			,	RawDocumentGUIDList = FX.ToList(wsn.RawDocumentGUID)
			,	Alerts.InformationCount
			,	Alerts.WarningCount
			,	Alerts.ErrorCount
			from
				SUPPLIEREDI.WaupacaShipNotices as wsn
				outer apply
				(	select
						InformationCount = count(case when wsna.Type = 0 then 1 end)
					,	WarningCount = count(case when wsna.Type > 0 then 1 end)
					,	ErrorCount = count(case when wsna.Type < 0 then 1 end)
					from
						SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
					where
						wsna.ShipperID = wsn.ShipperID
						and wsna.BillOfLadingNumber = wsn.BillOfLadingNumber
						and wsna.ShipFromCode = wsn.ShipFromCode
						and wsna.ShipToCode = wsn.ShipToCode
						and wsna.ShipDT = wsn.ShipDT
				) Alerts
			where
				(	@ShowNew = 1
					and wsn.Status = 0
					and wsn.ShipperLineStatus = 0
				)
				or
				(	@ShowDeleted = 1
					and wsn.Status < 0
					and wsn.ShipperLineStatus < 0
				)
				or
				(	@ShowCompleted = 1
					and wsn.Status > 0
					and wsn.ShipperLineStatus > 0
				)
			group by
				wsn.ShipperID
			,	wsn.Status
			,	wsn.BillOfLadingNumber
			,	wsn.ShipFromCode
			,	wsn.ShipToCode
			,	wsn.ShipDT
			,	Alerts.InformationCount
			,	Alerts.WarningCount
			,	Alerts.ErrorCount
			order by
				wsn.ShipDT
			,	wsn.ShipperID

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

begin transaction Test

declare
	@ShowNew tinyint = 1
,	@ShowDeleted tinyint = 1
,	@ShowCompleted tinyint = 0

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@ShowNew = @ShowNew
,	@ShowDeleted = @ShowDeleted
,	@ShowCompleted = @ShowCompleted
,	@TranDT = @TranDT out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper
end
go

create procedure SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Create SUPPLIEREDI ship notice. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNotices'
			
			insert
				SUPPLIEREDI.ShipNotices
			(	RawDocumentGUID
			,	ShipperID
			,	BillOfLadingNumber
			,	ShipFromCode
			,	ShipToCode
			,	ShipDT
			)
			select
				wsn.RawDocumentGUID
			,	wsn.ShipperID
			,	wsn.BillOfLadingNumber
			,	wsn.ShipFromCode
			,	wsn.ShipToCode
			,	wsn.ShipDT
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
			where
				wsn.Status = 0
				and wsn.ShipperLineStatus = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			

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

		/*	Create SUPPLIEREDI ship notice lines. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice lines'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeLines'
			
			insert
				SUPPLIEREDI.ShipNoticeLines
			(	RawDocumentGUID
			,	SupplierPart
			,	PurchaseOrderRef
			,	Quantity
			,	PartCode
			,	PurchaseOrderNumber
			)
			select
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	wsnl.PurchaseOrderRef
			,	Quantity = sum(wsnl.Quantity)
			,	wsnl.PartCode
			,	wsnl.PurchaseOrderNumber
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
					and wsn.ShipperLineStatus= wsn.Status
			where
				wsn.Status = 0
				and wsnl.Status = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			group by
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	wsnl.PurchaseOrderRef
			,	wsnl.PartCode
			,	wsnl.PurchaseOrderNumber
				
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			
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

		/*	Create SUPPLIEREDI ship notice objects. */
		set @TocMsg = 'Create SUPPLIEREDI ship notice objects'
		begin
			--- <Insert rows="1+">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeObjects'
			
			insert
				SUPPLIEREDI.ShipNoticeObjects
			(	RawDocumentGUID
			,	SupplierPart
			,	SupplierSerial
			,	SupplierParentSerial
			,	SupplierPackageType
			,	SupplierLot
			,	ObjectQuantity
			,	PartCode
			)
			select
				wsnl.RawDocumentGUID
			,	wsnl.SupplierPart
			,	SupplierSerial = null
			,	SupplierParentSerial = null
			,	SupplierPackageType = null
			,	SupplierLot = wsn.BillOfLadingNumber
			,	ObjectQuantity = wsnl.Quantity
			,	wsnl.PartCode
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = wsn.RawDocumentGUID
					and wsn.ShipperLineStatus= wsn.Status
			where
				wsn.Status = 0
				and wsnl.Status = 0
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Insert>
			

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

		/*	Process shipment. */
		set @TocMsg = 'Process shipment'
		begin
			--- <Call>	
			set	@CallProcName = 'SUPPLIEREDI.usp_Process'
			execute @ProcReturn = SUPPLIEREDI.usp_Process
					@TranDT = @TranDT out
				,	@Result = @ProcResult out
				,	@Debug = @cDebug
				,	@DebugMsg = @cDebugMsg out
		
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

		/*	Set shipper line(s) to completed. */
		set @TocMsg = 'Set shipper line(s) to completed'
		begin
			--- <Update rows="1+">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = snl.RawDocumentGUID
					and wsnl.RowID = snl.RowID
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.ReceiverHeaders rh
						join dbo.ReceiverLines rl
							on rl.ReceiverID = rh.ReceiverID
						join dbo.ReceiverObjects ro
							on ro.ReceiverLineID = rl.ReceiverLineID
					where
						rh.SupplierASNGuid = snh.RawDocumentGuid
						and wsnl.PartCode = ro.PartCode
						and ro.Serial > 0
				)
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGUID
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
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

		/*	Set shipper to completed. */
		set	@TocMsg = 'Set shipper to completed'
		begin
			--- <Update rows="1">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGUID
					)
				and not exists
				(	select
						*
					from
						FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
					where
						snl.Status = 0
						and exists
						(	select
								*
							from
								dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
							where
								convert(uniqueidentifier, rows.Value) = snl.RawDocumentGUID
						)
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
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'B831EB6C-3AAB-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_ProcessEdiShipper
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Debug = 1

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_ReceiverDetail_SetAsnGuid.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_ReceiverDetail_SetAsnGuid'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_ReceiverDetail_SetAsnGuid
end
go

create procedure SUPPLIEREDI.usp_Waupaca_ReceiverDetail_SetAsnGuid
	@User varchar(10)
,	@RawDocumentGuid varchar(50)
,	@ReceiverId int
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
					,	[@RawDocumentGuid] = @RawDocumentGuid
					,	[@ReceiverId] = @ReceiverId
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Set Asn Guid on receiver header. */
		set @TocMsg = 'Set Asn Guid on receiver header'
		begin
			--- <Update rows="1">
			set	@TableName = 'dbo.ReceiverHeaders'
			
			update
				rh
			set
				rh.SupplierASNGuid = convert(uniqueidentifier, @RawDocumentGuid)
			from
				dbo.ReceiverHeaders rh
			where
				rh.ReceiverID = @ReceiverId
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>
			

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

		/*	Set shipper line(s) to completed. */
		set @TocMsg = 'Set shipper line(s) to completed'
		begin
			--- <Update rows="1+">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join SUPPLIEREDI.WaupacaShipNoticeLines wsnl
					on wsnl.RawDocumentGUID = snl.RawDocumentGUID
					and wsnl.RowID = snl.RowID
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.ReceiverHeaders rh
						join dbo.ReceiverLines rl
							on rl.ReceiverID = rh.ReceiverID
						join dbo.ReceiverObjects ro
							on ro.ReceiverLineID = rl.ReceiverLineID
					where
						rh.ReceiverID = @ReceiverId
						and wsnl.PartCode = ro.PartCode
						and ro.Serial > 0
				)
				and snh.RawDocumentGuid = @RawDocumentGuid
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

		/*	Set shipper to completed if all lines are cancelled or completed. */
		set	@TocMsg = 'Set shipper to completed if all lines are cancelled or completed'
		if	not exists
			(	select
					*
				from
					FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
					join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
						on snh.RawDocumentGUID = snl.RawDocumentGUID
				where
					snh.RawDocumentGUID = @RawDocumentGuid
					and snl.Status = 0
			) begin
			--- <Update rows="1">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 1
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				snh.RawDocumentGUID = @RawDocumentGuid
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuid varchar(50) = '69716FAF-47AF-EA11-8121-005056A166E5'
,	@ReceiverId int = 18831

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_ReceiverDetail_SetAsnGuid
	@User = @User
,	@RawDocumentGuid = @RawDocumentGuid
,	@ReceiverId = @ReceiverId
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuid
,	@ShowNew = 1
,	@ShowDeleted = 1
,	@ShowCompleted = 1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetReceiverDetails_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuid
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
go

--commit
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_RestoreEdiShipper.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_RestoreEdiShipper'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_RestoreEdiShipper
end
go

create procedure SUPPLIEREDI.usp_Waupaca_RestoreEdiShipper
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Restore shipper. */
		set @TocMsg = 'Restore shipper'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

		/*	Restore all lines on shipper. */
		set @TocMsg = 'Restore all lines on shipper'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_RestoreEdiShipper
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_RestoreEdiShipperLine.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_RestoreEdiShipperLine'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_RestoreEdiShipperLine
end
go

create procedure SUPPLIEREDI.usp_Waupaca_RestoreEdiShipperLine
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
,	@RowIDList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
					,	[@RowIDList] = @RowIDList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Restore shipper line. */
		set @TocMsg = 'Restore shipper line'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
				join FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
					on snh.RawDocumentGUID = snl.RawDocumentGUID
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RowIDList, ',') rows
					where
						convert(int, rows.value) = snl.RowID
				)
				and exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

		/*	Restore shipper. */
		set	@TocMsg = 'Restore shipper'
		begin
			--- <Update rows="*">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				exists
				(	select
						*
					from
						dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
					where
						convert(uniqueidentifier, rows.Value) = snh.RawDocumentGuid
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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'
,	@RowIDList varchar(max) = '223, 226, 222, 225'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_RestoreEdiShipperLine
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@RowIDList = @RowIDList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@ShowNew = 1
,	@ShowDeleted = 1
,	@ShowCompleted = 1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
go

--commit
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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_SaveSupplierPart.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_SaveSupplierPart'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_SaveSupplierPart
end
go

create procedure SUPPLIEREDI.usp_Waupaca_SaveSupplierPart
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
,	@PartCode varchar(25)
,	@SupplierPart varchar(25)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
					,	[@PartCode] = @PartCode
					,	[@SupplierPart] = @SupplierPart
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Update supplier part. */
		set @TocMsg = 'Update supplier part'
		begin
			--- <Update rows="1">
			set	@TableName = 'dbo.part_vendor'
			
			update
				pv
			set
				pv.vendor_part = @SupplierPart
			from
				dbo.part_vendor pv
			where
				exists
				(	select
						*
					from
						SUPPLIEREDI.WaupacaShipNotices wsn
						join dbo.destination dV
							on dV.destination = wsn.ShipFromCode
					where
						exists
						(	select
								*
							from
								dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
							where
								wsn.RawDocumentGUID = convert(uniqueidentifier, rows.Value)
						)
						and dV.vendor = pv.vendor
				)
				and pv.part = @PartCode
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount != 1 begin
				--- <Insert rows="1">
				set	@TableName = 'dbo.part_vendor'
				
				insert
					dbo.part_vendor
				(	part
				,	vendor
				,	vendor_part
				,	accum_received
				,	accum_shipped
				)
				select
					part = @PartCode
				,	vendor = dv.vendor
				,	vendor_part = @SupplierPart
				,	accum_received = 0
				,	accum_shipped = 0
				from
					SUPPLIEREDI.WaupacaShipNotices wsn
					join dbo.destination dV
						on dV.destination = wsn.ShipFromCode
				where
					exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							wsn.RawDocumentGUID = convert(uniqueidentifier, rows.Value)
					)			
				
				select
					@Error = @@Error,
					@RowCount = @@Rowcount
				
				if	@Error != 0 begin
					set	@Result = 999999
					RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
					rollback tran @ProcName
					return
				end
				if	@RowCount != 1 begin
					set	@Result = 999999
					RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
					rollback tran @ProcName
					return
				end
				--- </Insert>
				
			end
			--- </Update>
			

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

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'D35F5CD8-D5B4-EA11-8121-005056A166E5, D15F5CD8-D5B4-EA11-8121-005056A166E5'
,	@PartCode varchar(25) = '3443-RAW'
,	@SupplierPart varchar(25) = 'HC34 5796 AA (3443)'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_SaveSupplierPart
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@PartCode = @PartCode
,	@SupplierPart = @SupplierPart
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_SaveSupplierPart
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@PartCode = @PartCode
,	@SupplierPart = 'xx'
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNoticeLines_byRawDocumentGuidList
	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

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
go


/*
Create Procedure.FxAztec.SUPPLIEREDI.usp_Waupaca_UndoProcessEdiShipper.sql
*/

use FxAztec
go

if	objectproperty(object_id('SUPPLIEREDI.usp_Waupaca_UndoProcessEdiShipper'), 'IsProcedure') = 1 begin
	drop procedure SUPPLIEREDI.usp_Waupaca_UndoProcessEdiShipper
end
go

create procedure SUPPLIEREDI.usp_Waupaca_UndoProcessEdiShipper
	@User varchar(10)
,	@RawDocumentGuidList varchar(max)
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
					,	[@RawDocumentGuidList] = @RawDocumentGuidList
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		/*	Undo receipts. */
		set @TocMsg = 'Undo receipts'
		begin
			declare
				receipts cursor local for
			select
				ro.ReceiverObjectID
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join dbo.ReceiverHeaders rh
					on rh.SupplierASNGuid = wsn.RawDocumentGUID
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
				join dbo.ReceiverObjects ro
					on ro.ReceiverLineID = rl.ReceiverLineID
					and ro.Serial > 0
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			open receipts

			while
				1 = 1 begin

				declare
					@receiverObjectID int

				fetch
					receipts
				into
					@receiverObjectID

				if	@@FETCH_STATUS != 0 break

				--- <Call>	
				set	@CallProcName = 'dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject'
				execute @ProcReturn = dbo.usp_ReceivingDock_UndoReceiveObject_againstReceiverObject
						@User = @User
					,	@ReceiverObjectID = @receiverObjectID
					,	@TranDT = @TranDT out
					,	@Result = @ProcResult out
						
				set	@Error = @@Error
				if	@Error != 0 begin
					set	@Result = 900501
					RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
					rollback tran @ProcName
					return
				end
				if	@ProcReturn != 0 begin
					set	@Result = 900502
					RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
					rollback tran @ProcName
					return
				end
				if	@ProcResult != 0 begin
					set	@Result = 900502
					RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
					rollback tran @ProcName
					return
				end
				--- </Call>
			end
			close
				receipts
			deallocate
				receipts

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

		/*	Remove receiver objects. */
		set @TocMsg = 'Remove receiver objects'
		begin
			--- <Delete rows="*">
			set	@TableName = 'dbo.ReceiverObjects'
			
			delete
				ro
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join dbo.ReceiverHeaders rh
					on rh.SupplierASNGuid = wsn.RawDocumentGUID
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
				join dbo.ReceiverObjects ro
					on ro.ReceiverLineID = rl.ReceiverLineID
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
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

		/*	Remove receiver lines. */
		set @TocMsg = 'Remove receiver lines'
		begin
			--- <Delete rows="*">
			set	@TableName = 'dbo.ReceiverLines'
			
			delete
				rl
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join dbo.ReceiverHeaders rh
					on rh.SupplierASNGuid = wsn.RawDocumentGUID
				join dbo.ReceiverLines rl
					on rl.ReceiverID = rh.ReceiverID
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
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

		/*	Remove Supplier Asn guid and cancel receiver header. */
		set @TocMsg = 'Remove Supplier Asn guid and cancel receiver header'
		begin
			--- <Update rows="1+">
			set	@TableName = 'dbo.ReceiverLines'
			
			update
				rh
			set	rh.Status = -1
			,	rh.SupplierASNGuid = null
			from
				SUPPLIEREDI.WaupacaShipNotices wsn
				join dbo.ReceiverHeaders rh
					on rh.SupplierASNGuid = wsn.RawDocumentGUID
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = wsn.RawDocumentGUID
					)
			
			select
				@Error = @@Error,
				@RowCount = @@Rowcount
			
			if	@Error != 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
				rollback tran @ProcName
				return
			end
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>
					
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

		/*	Remove SUPPLIEREDI ship notice objects. */
		set @TocMsg = 'Remove SUPPLIEREDI ship notice objects'
		begin
			--- <Delete rows="*">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeObjects'
			
			delete
				sno
			from
				SUPPLIEREDI.ShipNoticeObjects sno
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = sno.RawDocumentGUID
					)			
			
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

		/*	Remove SUPPLIEREDI ship notice lines. */
		set @TocMsg = 'Remove SUPPLIEREDI ship notice lines'
		begin
			--- <Delete rows="*">
			set	@TableName = 'SUPPLIEREDI.ShipNoticeLines'
			
			delete
				snl
			from
				SUPPLIEREDI.ShipNoticeLines snl
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snl.RawDocumentGUID
					)			
			
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

		/*	Remove SUPPLIEREDI ship notices. */
		set @TocMsg = 'Remove SUPPLIEREDI ship notices'
		begin
			--- <Delete rows="*">
			set	@TableName = 'SUPPLIEREDI.ShipNotices'
			
			delete
				sn
			from
				SUPPLIEREDI.ShipNotices sn
			where
				exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = sn.RawDocumentGUID
					)			
			
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

		/*	Set shipper line(s) to new. */
		set @TocMsg = 'Set shipper line(s) to new'
		begin
			--- <Update rows="1+">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeLines'
			
			update
				snl
			set
				snl.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
			where
				snl.Status = 1
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snl.RawDocumentGUID
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
			if	@RowCount <= 0 begin
				set	@Result = 999999
				RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

		/*	Set shipper to new. */
		set	@TocMsg = 'Set shipper to new'
		begin
			--- <Update rows="1">
			set	@TableName = 'FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders'
			
			update
				snh
			set
				snh.Status = 0
			from
				FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
			where
				snh.Status = 1
				and exists
					(	select
							*
						from
							dbo.fn_SplitStringToRows(@RawDocumentGuidList, ',') rows
						where
							convert(uniqueidentifier, rows.Value) = snh.RawDocumentGUID
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
			if	@RowCount != 1 begin
				set	@Result = 999999
				RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
				rollback tran @ProcName
				return
			end
			--- </Update>

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

set ansi_warnings off
set nocount on

declare
	@User varchar(10) = 'ees'
,	@RawDocumentGuidList varchar(max) = 'F13C6A11-32AF-EA11-8121-005056A166E5'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_UndoProcessEdiShipper
	@User = @User
,	@RawDocumentGuidList = @RawDocumentGuidList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out
--,	@Debug = 1
,	@Debug = 0

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

execute
	@ProcReturn = SUPPLIEREDI.usp_Waupaca_GetShipNotices
	@TranDT = @TranDT out
,	@Result = @ProcResult out

select
	ro.Serial
,	*
from
	dbo.ReceiverHeaders rh
	join dbo.ReceiverLines rl
		on rl.ReceiverID = rh.ReceiverID
	join dbo.ReceiverObjects ro
		on ro.ReceiverLineID = rl.ReceiverLineID
where
	rh.ReceiverNumber = '18825'

select
	*
from
	dbo.BackflushHeaders bh
where
	bh.SerialProduced = '1012557'
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
go


/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNoticeAlerts.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNoticeAlerts
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNoticeAlerts'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNoticeAlerts
end
go

create view SUPPLIEREDI.WaupacaShipNoticeAlerts
as
/*	No valid matching PO. */
select
	wsn.Status
,	Type = -1
,	Alert = 'No valid matching PO.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	poMissing.Description
,	poMissing.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('PORef: ' + convert(varchar(12), wsnl.PurchaseOrderRef) + ' SPN: ' + wsnl.SupplierPart)
		,	Data = FX.ToList('(' + convert(varchar(12), wsnl.PurchaseOrderRef) + ',' + wsnl.SupplierPart + ')')
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderNumber is null
	) poMissing
where
	wsn.Status = 0
	and exists
		(	select
				*
			from
				SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderNumber is null
		)
union all
/*	Possible duplicate. */
select
	wsn.Status
,	Type = 1
,	Alert = 'Possible duplicate receipts.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	Reciepts.Description
,	Reciepts.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('RN: ' + R.ReceiverNumber + ':' + convert(varchar(12), R.Status) + coalesce(' PO#: ' + convert(varchar(12), R.PONumber) + ' PN: ' + R.PartCode + ' QTY: ' + convert(varchar(12), R.Quantity), ''))
		,	Data = Fx.ToList(R.ReceiverNumber)
 		from
			(	select
					rh.ReceiverNumber
				,	rh.Status
				,	rl.PONumber
				,	rl.PartCode
				,	Quantity = sum(ro.QtyObject)
				from
 					dbo.ReceiverHeaders rh
					left join dbo.ReceiverLines rl
						on rl.ReceiverID = rh.ReceiverID
					left join dbo.ReceiverObjects ro
						on ro.ReceiverLineID = rl.ReceiverLineID
						and ro.Serial > 0
				where
					rh.ShipFrom = wsn.ShipFromCode
					and rh.Plant = wsn.ShipToCode
					and rh.ConfirmedSID = wsn.ShipperID
				group by
					rh.ReceiverNumber
				,	rh.Status
				,	rl.PONumber
				,	rl.PartCode
			) R
 	) Reciepts
where
	wsn.Status = 0
	and exists
		(	select
				*
			from
				dbo.ReceiverHeaders rh
			where
				rh.ShipFrom = wsn.ShipFromCode
				and rh.Plant = wsn.ShipToCode
				and rh.ConfirmedSID = wsn.ShipperID
		)
union all
/*	No part-vendor record with matching vendor part. */
select
	wsn.Status
,	Type = 2
,	Alert = 'No part-vendor record with matching vendor part.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	pvMissing.Description
,	pvMissing.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('SPN: ' + wsnl.SupplierPart + ' PN:' + wsnl.PartCode)
		,	Data = Fx.ToList('(' + wsnl.PartCode  + ',' + dv.vendor + ',' + wsnl.SupplierPart + ')')
		from
			SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			join dbo.destination dV
				on dV.destination = wsn.ShipFromCode
			left join dbo.part_vendor pv
				on dV.vendor = pv.vendor
				and pv.vendor_part = wsnl.SupplierPart
		where
			wsnl.RawDocumentGUID = wsn.RawDocumentGUID
			and pv.part is null
	) pvMissing
where
	wsn.Status = 0
	and exists
		(	select
		 		*
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
				left join dbo.part_vendor pv
					join dbo.destination dV
						on dV.vendor = pv.vendor
					on dV.destination = wsn.ShipFromCode
					and pv.vendor_part = wsnl.SupplierPart
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and pv.part is null
		)
union all
/*	PO Number was inferred from ship from, ship to, and part. */
select
	wsn.Status
,	Type = 3
,	Alert = 'PO Number was inferred from ship from, ship to, and part.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	poMismatch.Description
,	poMismatch.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('PORef: ' + convert(varchar(12), wsnl.PurchaseOrderRef) + ' PO:' + convert(varchar(12), wsnl.PurchaseOrderNumber))
		,	Data = FX.ToList('(' + convert(varchar(12), wsnl.PurchaseOrderRef) + ',' + convert(varchar(12), wsnl.PurchaseOrderNumber) + ')')
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderRef <> wsnl.PurchaseOrderNumber
	) poMismatch
where
	wsn.Status = 0
	and exists
		(	select
		 		*
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderRef <> wsnl.PurchaseOrderNumber
		)
go

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
order by
	wsna.RawDocumentGUID
,	wsna.Type
,	wsna.Alert

/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNoticeLines.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNoticeLines
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNoticeLines'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNoticeLines
end
go

create view SUPPLIEREDI.WaupacaShipNoticeLines
as

select
	snl.Status
,	snh.Type
,	snh.RawDocumentGUID
,	SupplierPart = snl.PartNumber
,	PurchaseOrderRef = sno.PurchaseOrder
,	snl.Quantity
,	PartCode = phBestMatch.blanket_part
,	PurchaseOrderNumber = phBestMatch.po_number
,	snl.RowID
from
	FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
	join FxEDI.EDI4010_WAUPACA.ShipNotices sn
		on sn.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeOrders sno
		on sno.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
		on snl.RawDocumentGUID = snh.RawDocumentGUID
		and snl.PurchaseOrder = sno.PurchaseOrder
	left join dbo.po_header ph
		on ph.po_number = sno.PurchaseOrder
	outer apply
	(	select top (1)
	 		*
	 	from
	 		dbo.po_header phBestMatch
			outer apply
			(	select
	 				FuzzyPartNumber = substring(snl.PartNumber, r.RowNumber, 4)
	 			from
	 				FxEDI.FXSYS.Rows r
				where
					r.RowNumber <= datalength(snl.PartNumber) - 3
					and substring(snl.PartNumber, r.RowNumber, 4) like '[0-9][0-9][0-9][0-9]'
			) r
		where
			phBestMatch.vendor_code = ph.vendor_code
			and phBestMatch.ship_to_destination = ph.ship_to_destination
			and phBestMatch.blanket_part like '%' + r.FuzzyPartNumber + '%'
		order by
			phBestMatch.po_number
	) phBestMatch
go

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeLines as wsnl
where
	wsnl.Status = 0
/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNotices.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNotices
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNotices'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNotices
end
go

create view SUPPLIEREDI.WaupacaShipNotices
as
select
	snh.Status
,	ShipperLineStatus = snl.Status
,	snh.Type
,	snh.RawDocumentGUID
,	sno.ShipperID
,	BillOfLadingNumber = sn.Trailer
,	ShipFromCode = sn.ShipFromCode
,	ShipToCode = ph.ship_to_destination
,	ShipDT = snh.DocumentDT
from
	FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
	join FxEDI.EDI4010_WAUPACA.ShipNotices sn
		on sn.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeOrders sno
		on sno.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
		on snl.RawDocumentGUID = snh.RawDocumentGUID
		and snl.PurchaseOrder = sno.PurchaseOrder
	join dbo.po_header ph
		on ph.po_number = sno.PurchaseOrder
group by
	snh.Status
,	snl.Status
,	snh.Type
,	snh.RawDocumentGUID
,	sno.ShipperID
,	sn.Trailer
,	sn.ShipFromCode
,	ph.ship_to_destination
,	snh.DocumentDT
go

select
	wsn.Status
,	wsn.ShipperLineStatus
,	wsn.Type
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
from
	SUPPLIEREDI.WaupacaShipNotices as wsn
where
	wsn.Status = 0

/*
Create Synonym.FxEDI.FXSYS.Rows.sql
*/

use FxEDI
go

--	drop table FXSYS.Rows
--	select objectpropertyex(object_id('FXSYS.Rows'), 'BaseType')
if	objectpropertyex(object_id('FXSYS.Rows'), 'BaseType') = 'U' begin
	drop synonym FXSYS.Rows
end
go

create synonym FXSYS.Rows for FxSYS.dbo.Rows
go


/*
Create Procedure.FxSYS.dbo.usp_EmailError.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.usp_EmailError'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_EmailError
end
go

create procedure dbo.usp_EmailError
	@Recipients varchar(max) = ''
,	@CopyRecipients varchar(max)= 'estimpson@fore-thought.com'
as
begin
	set nocount on

	--- <Body>
	declare
		@html nvarchar(max)
	,	@emailTableName sysname = N'#errorInfo'

	select
		[Error] = convert(varchar(50), error_number())
	,	[Severity] =  convert(varchar(5), error_severity())
	,	[State] = convert(varchar(5), error_state())
	,	[Procedure] = isnull(error_procedure(), '-')
	,	[Line] = convert(varchar(5), error_line())
	into
		#errorInfo

	declare @html1 nvarchar(max);
	
	execute dbo.usp_TableToHTML
			@tableName = @emailTableName
		,	@html = @html out
		,	@orderBy = N'[Error]'
		,	@includeRowNumber = 0
		,	@camelCaseHeaders = 1
	
	declare
		@emailHeader nvarchar(max) = 'Error in procedure'

	declare
		@emailBody nvarchar(max) = N'<H1>' + @emailHeader + N'<H1>' + @html
	
	exec msdb.dbo.sp_send_dbmail
			@profile_name = N'FxAlerts'
		,	@recipients = @Recipients
		,	@copy_recipients = @CopyRecipients
		,	@subject = @emailHeader
		,	@body = @emailBody
		,	@body_format = 'HTML'
		,	@importance = 'HIGH'
	
	--- </Body>
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
	@ProcReturn = dbo.usp_EmailError

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
go


/*
Create Procedure.FxSYS.dbo.usp_TableToHTML.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.usp_TableToHTML'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_TableToHTML
end
go

create procedure dbo.usp_TableToHTML
	@tableName sysname = 'dbo.part_packaging'
,	@html nvarchar(max) output
,	@orderBy nvarchar(max) = ''
,	@includeRowNumber bit = 1
,	@camelCaseHeaders bit = 1
as
set ansi_warnings on 

declare
	@getColumnListSyntax nvarchar(max)

select
	@getColumnListSyntax = N'
set	@columnList =
		(	select
				A2.B.value(''.[1]/@name'', ''varchar(128)'')
			from
				(	select
					' +
		case	when @includeRowNumber = 1 then
					'	[Row] = 1
					,'
				else ''
		end +
					'	*
					from
						' + @tableName + '
					for xml AUTO, TYPE, xmlschema
				) as A1(X)
				cross apply X.nodes(
					''declare namespace xsd="http://www.w3.org/2001/XMLSchema";
					/xsd:schema/xsd:element/xsd:complexType/xsd:attribute'') as A2(B)
			for xml path(''th''), type
		)
'

declare
	@columnList xml

execute
	sp_executesql
	@getColumnListSyntax
,	N'@columnList xml output'
,	@columnList = @columnList output

declare
	@dataTableHTML nvarchar(max)
,	@dataSelectSyntax nvarchar(max)

select
	@dataSelectSyntax =
'
select
	@dataTableHTML = convert
	(	varchar(max)
	,	(	select
'

declare
	columnList cursor local for
select
	columnList.columnName.value('.[1]', 'varchar(128)')
from
	@columnList.nodes('/th') as columnList(columnName)
where
	columnList.columnName.value('.[1]', 'varchar(128)') != 'Row'
	or @includeRowNumber = 0

open
	columnList
	
declare
	@firstColumn int

select
	@firstColumn = 1

while
	1 = 1 begin
	
	declare
		@columnName sysname
	
	fetch
		columnList
	into
		@columnName
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	if	@firstColumn = 1 begin
		set	@dataSelectSyntax = @dataSelectSyntax +
'				[TRRow] = Row_Number() over (order by [' +
			case	when @orderBy > '' then @orderBy
					else @columnName
			end + ']) % 2
' +
			case	when @includeRowNumber = 1 then
'			,	[td] = Row_Number() over (order by [' +
						case	when @orderBy > '' then @orderBy
								else @columnName
						end + '])'
					else ''
			end
		set	@firstColumn = 0
	end
	
	set	@dataSelectSyntax = @dataSelectSyntax +
	'
			,	[td] = coalesce(convert(nvarchar(max), [' + @columnName + ']), ''(null)'')'
end

close
	columnList
deallocate
	columnList

set	@dataSelectSyntax = @dataSelectSyntax +
'
			from
				' + @tableName +
		case	when @orderBy > '' then '
			order by
				' + @orderBy
				else ''
		end + '
			for xml raw(''tr''), elements
		)
	)
'

set	@dataSelectSyntax = replace(@dataSelectSyntax, '_x0020_', space(1))
set	@dataSelectSyntax = replace(@dataSelectSyntax, '_x003D_', '=')

exec sp_executesql
	@dataSelectSyntax
,	N'@dataTableHTML nvarchar(max) output'
,	@dataTableHTML = @dataTableHTML output

set	@dataTableHTML = coalesce(@dataTableHTML, N'')

select
	@html =
		N'<table border="1">' +
		N'<tr>' +
		case	when @camelCaseHeaders = 1 then dbo.fn_CamelCase(convert(nvarchar(max), @columnList))
				else convert(nvarchar(max), @columnList)
		end + N'</tr>' +
		@dataTableHTML + N'</table>'

set	@html = replace(@html, '_x0020_', space(1))
set	@html = replace(@html, '_x003D_', '=')
set	@html = replace(@html, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#C6CFFF>')
set	@html = replace(@html, '<TRRow>0</TRRow>', '')

--print
--	@html
go


/*
Create ScalarFunction.FxSYS.dbo.fn_CamelCase.sql
*/

use FxSYS
go


if objectproperty(object_id('dbo.fn_CamelCase'), 'IsScalarFunction') = 1 begin
	drop function dbo.fn_CamelCase
end
go


create function dbo.fn_CamelCase
(	@inputString nvarchar(max)
)
returns nvarchar(max)
as begin
	--- <Body>
	/*	Find all underscores in the input string. */
	while 1 = 1 begin
		declare @underscoreIndex bigint

		set @underscoreIndex = patindex('%[_]%', @inputString)

		if not (@underscoreIndex > 0) begin
			break
		end

		set @inputString
			= left(@inputString, @underscoreIndex - 1) + space(1)
			  + upper(substring(@inputString, @underscoreIndex + 1, 1))
			  + substring(@inputString, @underscoreIndex + 2, len(@inputString))
	end

	/*	Find all word separators in input string. */
	declare @offset bigint

	select @offset = 1

	while 1 = 1 begin
		declare @separatorIndex bigint

		set @separatorIndex = patindex('%[>.]%', substring(@inputString, @offset, len(@inputString)))

		if not (@separatorIndex > 0) begin
			break
		end

		set @inputString
			= left(@inputString, @separatorIndex + @offset - 1)
			  + upper(substring(@inputString, @separatorIndex + @offset, 1))
			  + substring(@inputString, @separatorIndex + @offset + 1, len(@inputString))
		set @offset = @offset + @separatorIndex
	end

	--- </Body>

	---	<Return>
	return @inputString
end
go

select dbo.fn_CamelCase('x_y')
go

