SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SUPPLIEREDI].[usp_Purchasing_AddReceipt_byReceiverObjectList]
	@User varchar(5)
,	@ReceiverObjectID int = null -- Specify this or a list using #receiverObjectList
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
			--USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
			USP_Name = 'SUPPLIEREDI.usp_Purchasing_AddReceipt_byReceiverObjectList'
		,	BeginDT = getdate()
		,	InArguments = convert
				(	varchar(max)
				,	(	select
							[@User] = @User
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
			--USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
			USP_Name = 'SUPPLIEREDI.usp_Purchasing_AddReceipt_byReceiverObjectList'
		,	BeginDT = getdate()
		,	InArguments = convert
				(	varchar(max)
				,	(	select
							[@User] = @User
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
				ro.ReceiverObjectID = @ReceiverObjectID
		end

		/*	Get all PO releases relevant to received objects. */
		set @TocMsg = 'Get all PO releases relevant to received objects'
		begin
			declare
				@POReleases table
			(	Vendor varchar(10)
			,	PONumber int
			,	POType char(1)
			,	PartCode varchar(25)
			,	DueDT datetime
			,	RowID int
			,	POLineNo int
			,	QtyDue numeric(20,6)
			,	Unit char(2)
			,	PriorAccum numeric(20,6)
			,	TotalReceiptQty numeric(20,6)
			,	QtyReceived numeric(20,6)
			,	QtyOverReceived numeric(20,6)
			)

			insert
				@POReleases
			(	Vendor
			,	PONumber
			,	POType
			,	PartCode
			,	DueDT
			,	RowID
			,	POLineNo
			,	QtyDue
			,	Unit
			,	PriorAccum
			,	TotalReceiptQty
			)
			select
				Vendor = ro.Vendor
			,	PONumber = pd.po_number
			,	POType = ro.POType
			,	PartCode = pd.part_number
			,	DueDT = pd.date_due
			,	RowID = pd.row_id
			,	POLineNo = count(*) over (partition by pd.po_number, pd.part_number order by pd.date_due, pd.row_id)
			,	QtyDue = pd.standard_qty
			,	Unit = coalesce(pd.unit_of_measure, pInv.standard_unit)
			,	PriorAccum = sum(pd.standard_qty) over (partition by pd.po_number, pd.part_number order by pd.date_due, pd.row_id)
			,	TotalReceiptQty = ro.TotalReceiptQty
			from
				dbo.po_detail pd
				left join dbo.part_inventory pInv
					on pInv.part = pd.part_number
				join
					(	select
							ro.PONumber
						,	ro.PartCode
						,	Vendor = ph.vendor_code
						,	POType = ph.type
						,	POLineNo = case when ph.type != 'B' then ro.POLineNo end
						,	POLineDueDate = case when ph.type != 'B' then ro.POLineDueDate end
						,	TotalReceiptQty = sum(ro.QtyObject)
						from
							#receiverObjectList rol
							join dbo.ReceiverObjects ro
								on ro.ReceiverObjectID = rol.ReceiverObjectID
							join dbo.po_header ph
								on ph.po_number = ro.PONumber
						group by
							ro.PONumber
						,	ro.PartCode
						,	ph.vendor_code	
						,	ph.type
						,	case when ph.type != 'B' then ro.POLineNo end
						,	case when ph.type != 'B' then ro.POLineDueDate end
					) ro
					on PONumber = pd.po_number
					and ro.PartCode = pd.part_number
					and
					(	POType = 'B'
						or
						(	ro.POLineDueDate = pd.date_due
							and ro.POLineNo = pd.row_id
						)
					)

			if	@@rowcount = 0 begin
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

		/*	Calculate (over)receipt amount. */
		set @TocMsg = 'Calculate receipt amount'
		begin
			update
				pr
			set	pr.QtyReceived =
					case
						when pr.PriorAccum > pr.TotalReceiptQty then 0
						else
							case
								when pr.TotalReceiptQty > pr.PriorAccum + pr.QtyDue then pr.QtyDue
								else pr.TotalReceiptQty - pr.PriorAccum
							end
					end
			from
				@POReleases pr

			update
				pr
			set pr.QtyOverReceived =
					case
						when
							pr.PriorAccum + pr.QtyDue < pr.TotalReceiptQty
							and pr.POLineNo =
								(	select
										max(pr2.POLineNo)
									from
										@POReleases pr2
									where
										pr2.PONumber = pr.PONumber
										and pr2.PartCode = pr.PartCode
								) then pr.TotalReceiptQty - (pr.PriorAccum + pr.QtyDue)
					end
			from
				@POReleases pr
				
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

		/*	Write changes to PO detail. */
		set @TocMsg = 'Write changes to PO detail'
		begin
			update
				pd
			set
				received = pd.received + dbo.udf_GetQtyFromStdQty(pr.PartCode, pr.QtyReceived + pr.QtyOverReceived, pr.Unit)
			,	balance = pd.balance - dbo.udf_GetQtyFromStdQty(pr.PartCode, pr.QtyReceived, pr.Unit)
			,	standard_qty = pd.standard_qty - pr.QtyReceived
			,	last_recvd_date = @TranDT
			,	last_recvd_amount = pr.QtyReceived + pr.QtyOverReceived
			from
				dbo.po_detail pd
				join @POReleases pr
					on pr.PONumber = pd.po_number
					and pr.PartCode = pd.part_number
					and pr.DueDT = pd.date_due
					and pr.RowID = pd.row_id
					and pr.QtyReceived + pr.QtyOverReceived > 0
				
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
		
		/*	Write receipt history. */
		set @TocMsg = 'Write receipt history'
		begin
			insert
				dbo.po_detail_history
			(	po_number, vendor_code, part_number, description, unit_of_measure
			, 	date_due, requisition_number, status, type, last_recvd_date
			,	last_recvd_amount, cross_reference_part, account_code, notes, quantity
			,	received, balance, active_release_cum, received_cum, price
			,	row_id, invoice_status, invoice_date, invoice_qty, invoice_unit_price
			,	release_no, ship_to_destination, terms, week_no, plant
			,	invoice_number, standard_qty, sales_order, dropship_oe_row_id, ship_type
			,	dropship_shipper, price_unit, ship_via, release_type, alternate_price)
			select
				pd.po_number, pd.vendor_code, pd.part_number, pd.description, pd.unit_of_measure
			,	pd.date_due, pd.requisition_number, pd.status, pd.type, pd.last_recvd_date
			,	pd.last_recvd_amount, pd.cross_reference_part, pd.account_code, pd.notes, pd.quantity
			,	pd.received, pd.balance, pd.active_release_cum, pd.received_cum, pd.price
			,	pd.row_id, pd.invoice_status, pd.invoice_date, pd.invoice_qty, pd.invoice_unit_price
			,	pd.release_no, pd.ship_to_destination, pd.terms, pd.week_no, pd.plant
			,	pd.invoice_number, pd.standard_qty, pd.sales_order, pd.dropship_oe_row_id, pd.ship_type
			,	pd.dropship_shipper, pd.price_unit, pd.ship_via, pd.release_type, pd.alternate_price
			from
				dbo.po_detail pd
				join @POReleases pr
					on pr.PONumber = pd.po_number
					and pr.PartCode = pd.part_number
					and pr.DueDT = pd.date_due
					and pr.RowID = pd.row_id
					and pr.QtyReceived + pr.QtyOverReceived > 0
				
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
		
		/*	Delete completed blanket releases. */
		set @TocMsg = 'Delete completed blanket releases'
		begin
			delete
				pd
			from
				dbo.po_detail pd
				join @POReleases pr
					on pr.PONumber = pd.po_number
					and pr.PartCode = pd.part_number
					and pr.DueDT = pd.date_due
					and pr.RowID = pd.row_id
			where
				pr.POType = 'B'
				and pd.balance <= 0
				
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
		
		/*	Update part-vendor relationship. */
		set @TocMsg = 'Update part-vendor relationship'
		begin
			update
				pv
			set
				accum_received = coalesce(accum_received, 0) + pr.TotalReceiptQty
			from
				dbo.part_vendor pv
				join @POReleases pr
					on pr.PartCode = pv.part
					and pr.Vendor = pv.vendor
			
			if	exists
					(	select
							*
						from
							@POReleases pr
						where
							not exists
								(	select
										*
									from
										dbo.part_vendor pv
									where
										pv.part = pr.PartCode
										and pv.vendor = pr.Vendor
								)
					) begin

				insert
					dbo.part_vendor
				(	part
				,	vendor
				,	vendor_part
				,	accum_received
				,	part_name
				,	note
				)
				select distinct
					part = pr.PartCode
				,	vendor = ph.vendor_code
				,	vendor_part = coalesce(ph.blanket_vendor_part, '')
				,	accum_received = pr.TotalReceiptQty
				,	part_name = coalesce(p.name, 'Non-recurring')
				,	note = 'Auto-created during receipt'
				from
					@POReleases pr
					join dbo.po_header ph
						on ph.po_number = pr.PONumber
					join dbo.part p
						on p.part = pr.PartCode
				where
					not exists
						(	select
								*
							from
								dbo.part_vendor pv
							where
								pv.part = pr.PartCode
								and pv.vendor = pr.Vendor
						)
					
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
	@FinishedPart varchar(25) = 'ALC0598-HC02'
,	@ParentHeirarchID hierarchyid

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_Purchasing_AddReceipt_byReceiverObjectList
	@FinishedPart = @FinishedPart
,	@ParentHeirarchID = @ParentHeirarchID
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

GO
GRANT EXECUTE ON  [SUPPLIEREDI].[usp_Purchasing_AddReceipt_byReceiverObjectList] TO [SupplierPortal]
GO
