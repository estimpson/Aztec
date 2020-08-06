SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FT].[usp_Alert_NonReconciledShippers]
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
		@CallProcName sysname
	,	@TableName sysname
	,	@ProcName sysname
	,	@ProcReturn integer
	,	@ProcResult integer
	,	@Error integer
	,	@RowCount integer

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
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
		/*	Generate alerts. */
		set @TocMsg = 'Generate alerts'
		begin
			select
				alerts.ShipperID
			,	alerts.ErrorMessage
			,	RowID = row_number() over (order by alerts.ShipperID)
			into
				#alerts
			from
				(	select
						ShipperID = s.id
					,	ErrorMessage = 'Qty Packed Mismatch: ' + sd.part + ' | ' + coalesce(convert(varchar, sd.qty_packed), '(null)') + ' | ' +  coalesce(convert(varchar, line_box.qty_staged), '(null') 
					from
						dbo.shipper s
						join dbo.shipper_detail sd
							on sd.shipper = s.id
						outer apply
							(	select
									qty_staged = sum(o.quantity)
								,	stdqty_staged = sum(o.std_quantity)
								,	boxes_staged = count(*)
								from
									dbo.object o
								where
									o.shipper = s.id
									and o.part = sd.part
							) line_box
					where
						coalesce(s.type, 'N') = 'N'
						and s.status in
							('O', 'S')
						and coalesce(sd.qty_packed, 0) != coalesce(line_box.qty_staged, 0)
					union all
					select
						ShipperID = s.id
					,	ErrorMessage = 'StdQty Packed Mismatch: ' + sd.part + ' | ' + coalesce(convert(varchar, sd.alternative_qty), '(null)') + ' | ' +  coalesce(convert(varchar, line_box.stdqty_staged), '(null') 
					from
						dbo.shipper s
						join dbo.shipper_detail sd
							on sd.shipper = s.id
						outer apply
							(	select
									qty_staged = sum(o.quantity)
								,	stdqty_staged = sum(o.std_quantity)
								,	boxes_staged = count(*)
								from
									dbo.object o
								where
									o.shipper = s.id
									and o.part = sd.part
							) line_box
					where
						coalesce(s.type, 'N') = 'N'
						and s.status in
							('O', 'S')
						and coalesce(sd.boxes_staged, 0) != coalesce(line_box.boxes_staged, 0)
					union all
					select
						ShipperID = s.id
					,	ErrorMessage = 'Box Count Mismatch: ' + sd.part + ' | ' + coalesce(convert(varchar, sd.boxes_staged), '(null)') + ' | ' +  coalesce(convert(varchar, line_box.boxes_staged), '(null') 
					from
						dbo.shipper s
						join dbo.shipper_detail sd
							on sd.shipper = s.id
						outer apply
							(	select
									qty_staged = sum(o.quantity)
								,	stdqty_staged = sum(o.std_quantity)
								,	boxes_staged = count(*)
								from
									dbo.object o
								where
									o.shipper = s.id
									and o.part = sd.part
							) line_box
					where
						coalesce(s.type, 'N') = 'N'
						and s.status in
							('O', 'S')
						and coalesce(sd.alternative_qty, 0) != coalesce(line_box.stdqty_staged, 0)
					/*	Not currently interested in tracking this */
					--union all
					--select
					--	ShipperID = s.id
					--,	ErrorMessage = 'Object Count Mismatch: ' + coalesce(convert(varchar, s.staged_objs), '(null)') + ' | ' +  coalesce(convert(varchar, shipper_box.boxes_staged), '(null') 
					--from
					--	dbo.shipper s
					--	outer apply
					--		(	select
					--				boxes_staged = count(*)
					--			from
					--				dbo.object o
					--			where
					--				o.shipper = s.id
					--				and o.type is null
					--		) shipper_box
					--where
					--	coalesce(s.type, 'N') = 'N'
					--	and s.status in
					--		('O', 'S')
					--	and coalesce(s.staged_objs, 0) != coalesce(shipper_box.boxes_staged, 0)
					union all
					select
						ShipperID = s.id
					,	ErrorMessage = 'Pallet Count Mismatch: ' + coalesce(convert(varchar, s.staged_pallets), '(null)') + ' | ' +  coalesce(convert(varchar, pallet.pallet_staged), '(null') 
					from
						dbo.shipper s
						outer apply
							(	select
									pallet_staged = count(*)
								from
									dbo.object o
								where
									o.shipper = s.id
									and o.part = 'PALLET'
							) pallet
					where
						coalesce(s.type, 'N') = 'N'
						and s.status in
							('O', 'S')
						and coalesce(s.staged_pallets, 0) != coalesce(pallet.pallet_staged, 0)
				) alerts
			order by
				alerts.ShipperID

			if	@@ROWCOUNT > 0 begin

				declare
					@html varchar(max)

				exec FXSYS.usp_TableToHTML
					@tableName = '#alerts'
				,	@html = @html out
				,	@orderBy = N'RowID'
				,	@includeRowNumber = 0
				,	@camelCaseHeaders = 1
				

				declare @mailitem_id int;

				exec msdb.dbo.sp_send_dbmail
					@profile_name = 'fxAlerts'
				,	@recipients = 'estimpson@fore-thought.com'
				,	@subject = N'Shipment Staging/Reconcile Alerts'
				,	@body = @html
				,	@body_format = 'html'
				
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
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = FT.usp_Alert_NonReconciledShippers
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
