
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
			from
				SUPPLIEREDI.ShipNotices sn with (tablockx)
				join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
					on snl.RawDocumentGUID = sn.RawDocumentGUID
				join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
					on sno.RawDocumentGUID = sn.RawDocumentGUID
					and sno.SupplierPart = snl.SupplierPart
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
			(	Type
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
				Type =
					case
						when v.code is null then 1  -- (select dbo.udf_TypeValue ('ReceiverHeaders', 'Purchase Order'))
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
				left join dbo.destination d
					join dbo.vendor v
						on v.code = d.vendor
					on d.destination = sn.ShipToCode

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
				' from ' + summary.ShipFromCode + ' to ' + summary.ShipToCode + ' with invalid PO ' + summary.PurchaseOrderNumber + ' and/or part ' + summary.PartCode + ' combination or no releases. '
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

