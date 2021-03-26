SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [custom].[usp_Magna_AddSurchargeInvoiceItems]
	@Shipper int
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
						[@Shipper] = @Shipper
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

	set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. custom.usp_Test
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
		/*	Create surcharge items. */
		set @TocMsg = 'Create surcharge items'
		begin
			--- <Insert rows="*">
			set	@TableName = 'dbo.shipper_detail'
		
			insert
				dbo.shipper_detail
			(	shipper
			,	part
			,	qty_required
			,	qty_packed
			,	qty_original
			,	accum_shipped
			,	order_no
			,	customer_po
			,	type
			,	price
			,	account_code
			,	salesman
			,	tare_weight
			,	gross_weight
			,	date_shipped
			,	note
			,	operator
			,	alternative_qty
			,	alternative_unit
			,	taxable
			,	customer_part
			,	part_name
			,	part_original
			,	total_cost
			,	alternate_price
			)
			select
				sd.shipper
			,	part = sd.customer_part + ' SURCH'
			,	qty_required = sd.qty_packed
			,	qty_packed = sd.qty_packed
			,	qty_original = sd.qty_packed
			,	accum_shipped = sd.qty_packed
			,	order_no = 0
			,	customer_po = ''
			,	sd.type
			,	price = pc.length_x
			,	account_code = ''
			,	salesman = ''
			,	tare_weight = 0
			,	gross_weight = 0
			,	sd.date_shipped
			,	note = 'SURCHARGE'
			,	sd.operator
			,	alternative_qty = sd.qty_packed
			,	alternative_unit = ''
			,	sd.taxable
			,	customer_part = sd.customer_part + ' SURCH'
			,	part_name = ''
			,	part_original = sd.customer_part + ' SURCH'
			,	total_cost = 0
			,	alternate_price = pc.length_x
			from
				dbo.shipper s
					join dbo.shipper_detail sd
						on sd.shipper = s.id
					join dbo.destination d
						on d.destination = s.destination
						and d.customer = 'MAGNA'
					join dbo.part_characteristics pc
						on pc.part = sd.part_original
						and pc.length_x > 0
			where
				s.id = @shipper
				and not exists
					(	select
							*
						from
							dbo.shipper_detail sd2
						where
							sd2.shipper = s.id
							and sd2.part = sd.customer_part + ' SURCH'
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
	@Shipper int = 89808

begin transaction Test

delete
	sd
from
	dbo.shipper_detail sd
where
	sd.shipper = @Shipper
	and sd.part_original like '%SURCH'

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_Magna_AddSurchargeInvoiceItems
	@Shipper = @Shipper
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.shipper_detail sd
where
	sd.shipper = @Shipper
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
