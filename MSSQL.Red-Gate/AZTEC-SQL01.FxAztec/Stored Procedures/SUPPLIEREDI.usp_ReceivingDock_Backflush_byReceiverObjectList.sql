SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SUPPLIEREDI].[usp_ReceivingDock_Backflush_byReceiverObjectList]
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
			USP_Name = 'SUPPLIEREDI.usp_ReceivingDock_Backflush_byReceiverObjectList'
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
			USP_Name = 'SUPPLIEREDI.usp_ReceivingDock_Backflush_byReceiverObjectList'
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

		/*	Loop through backflush headers for receiver object list. */
		set @TocMsg = 'Loop through backflush headers for receiver object list'
		begin
			declare
				backflushHeaders cursor fast_forward read_only local for
			select
				bh.BackflushNumber
			,	ro.ReceiverObjectID
			from
				dbo.BackflushHeaders bh
					join dbo.ReceiverObjects ro
						join #receiverObjectList rol
							on rol.ReceiverObjectID = ro.ReceiverObjectID
						on ro.Serial = bh.SerialProduced

			where
				bh.Status = 0

			open
				backflushHeaders

			while 1 = 1 begin
				declare
					@backflushNumber varchar(50)

				fetch
					backflushHeaders
				into
					@backflushNumber
				,	@ReceiverObjectID

				if	@@fetch_status != 0 begin
					break
				end

				--- <Call>	
				set	@CallProcName = 'dbo.usp_ReceivingDock_Backflush'
				
				execute @ProcReturn = dbo.usp_ReceivingDock_Backflush
						@Operator = @User
					,	@BackflushNumber = @backflushNumber
					,	@ReceiverObjectID = @ReceiverObjectID
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
			end

			close
				backflushHeaders
			deallocate
				backflushHeaders
				
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
	@FinishedPart varchar(25) = 'ALC0598-HC02'
,	@ParentHeirarchID hierarchyid

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SUPPLIEREDI.usp_ReceivingDock_Backflush_byReceiverObjectList
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
