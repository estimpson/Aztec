CREATE TABLE [SPORTAL].[SupplierShipments]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__SupplierS__Shipp__25EAB371] DEFAULT ('0'),
[Status] [int] NOT NULL CONSTRAINT [DF__SupplierS__Statu__26DED7AA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__SupplierSh__Type__27D2FBE3] DEFAULT ((0)),
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DepartureDT] [datetime] NULL,
[CarrierCode] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TrackingNumber] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__SupplierS__RowCr__28C7201C] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowCr__29BB4455] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__SupplierS__RowMo__2AAF688E] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowMo__2BA38CC7] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SPORTAL].[tr_SupplierShipments_iAssignCode] on [SPORTAL].[SupplierShipments] for insert
as
set nocount on
set ansi_warnings off
declare
	@Result int

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=No>
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--- <Body>
declare
	newRows cursor for
select
	i.RowID
from
	inserted i
where
	i.ShipperNumber = '0'

open
	newRows

while
	1 = 1 begin
	
	declare
		@newRowID int
	
	fetch
		newRows
	into
		@newRowID
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	declare
		@NextNumber varchar(50)

	--- <Call>	
	set	@CallProcName = 'FT.usp_NextNumberInSequnce'
	execute
		@ProcReturn = FT.usp_NextNumberInSequnce
		@KeyName = 'SPORTAL.SupplierShipments.ShipperNumber'
	,	@NextNumber = @NextNumber out
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

	--- <Update rows="1">
	set	@TableName = 'SPORTAL.SupplierShipments'

	update
		l
	set
		ShipperNumber = @NextNumber
	from
		SPORTAL.SupplierShipments l
	where
		l.RowID = @newRowID

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
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
	--- </Body>
end

close
	newRows
deallocate
	newRows
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SPORTAL].[tr_SupplierShipments_uRowModified] on [SPORTAL].[SupplierShipments] after update
as
declare
	@TranDT datetime
,	@Result int

set xact_abort off
set nocount on
set ansi_warnings off
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SPORTAL.usp_Test
--- </Error Handling>

begin try
	--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount
	set	@TranDT = coalesce(@TranDT, GetDate())
	save tran @ProcName
	--- </Tran>

	---	<ArgumentValidation>

	---	</ArgumentValidation>
	
	--- <Body>
	if	not update(RowModifiedDT) begin
		--- <Update rows="*">
		set	@TableName = 'SPORTAL.SupplierShipments'
		
		update
			ss
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SPORTAL.SupplierShipments ss
			join inserted i
				on i.RowID = ss.RowID
		
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
		
		--- </Body>
	end
end try
begin catch
	declare
		@errorName int
	,	@errorSeverity int
	,	@errorState int
	,	@errorLine int
	,	@errorProcedures sysname
	,	@errorMessage nvarchar(2048)
	,	@xact_state int
	
	select
		@errorName = error_number()
	,	@errorSeverity = error_severity()
	,	@errorState = error_state ()
	,	@errorLine = error_line()
	,	@errorProcedures = error_procedure()
	,	@errorMessage = error_message()
	,	@xact_state = xact_state()

	if	xact_state() = -1 begin
		print 'Error number: ' + convert(varchar, @errorName)
		print 'Error severity: ' + convert(varchar, @errorSeverity)
		print 'Error state: ' + convert(varchar, @errorState)
		print 'Error line: ' + convert(varchar, @errorLine)
		print 'Error procedure: ' + @errorProcedures
		print 'Error message: ' + @errorMessage
		print 'xact_state: ' + convert(varchar, @xact_state)
		
		rollback transaction
	end
	else begin
		/*	Capture any errors in SP Logging. */
		rollback tran @ProcName
	end
end catch

---	<Return>
set	@Result = 0
return
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

begin transaction Test
go

insert
	SPORTAL.SupplierShipments
...

update
	...
from
	SPORTAL.SupplierShipments
...

delete
	...
from
	SPORTAL.SupplierShipments
...
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
ALTER TABLE [SPORTAL].[SupplierShipments] ADD CONSTRAINT [PK__Supplier__FFEE74517A56656C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierShipments] ADD CONSTRAINT [UQ__Supplier__ED0F8CBF51D8DB16] UNIQUE NONCLUSTERED  ([ShipperNumber]) ON [PRIMARY]
GO
GRANT DELETE ON  [SPORTAL].[SupplierShipments] TO [SupplierPortal]
GO
GRANT INSERT ON  [SPORTAL].[SupplierShipments] TO [SupplierPortal]
GO
GRANT SELECT ON  [SPORTAL].[SupplierShipments] TO [SupplierPortal]
GO
GRANT UPDATE ON  [SPORTAL].[SupplierShipments] TO [SupplierPortal]
GO
