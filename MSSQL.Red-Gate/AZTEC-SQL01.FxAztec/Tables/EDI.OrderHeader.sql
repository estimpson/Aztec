CREATE TABLE [EDI].[OrderHeader]
(
[ProcessGUID] [uniqueidentifier] NOT NULL,
[DocumentGUID] [uniqueidentifier] NOT NULL,
[OrderHeaderGUID] [uniqueidentifier] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__OrderHead__Statu__71A0A0A1] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__OrderHeade__Type__7294C4DA] DEFAULT ((0)),
[SalesOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PurchaseOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PurchaseOrderLine] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EngineeringLevel] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DrawingNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FinishNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseDate] [date] NULL,
[SupplierPart] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UnitOfMeasurement] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SoldByCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipByContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipByTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsignedToTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaterialIssuerTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToAddress1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToAddress2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToStateProvince] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToPostalCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToCountry] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToLocationQualifier] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToLocationIdentifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToCountrySubdivisionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpeditorContactName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpeditorTelephone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpeditorRequestReferenceNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks11Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks12Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks13Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks14Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks15Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks16Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackingMarks17Z] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackagingCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StandardPack] [numeric] (20, 6) NULL,
[ModelYear] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DockCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineFeedCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReserveLineFeedCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WarehouseStorage] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastShippedQty] [numeric] (20, 6) NULL,
[LastShippedDate] [date] NULL,
[LastShippedID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastShippedAccum] [numeric] (20, 6) NULL,
[LastShippedBeginDate] [date] NULL,
[LastShippedEndDate] [date] NULL,
[HorizonAccum] [numeric] (20, 6) NULL,
[HorizonStartDate] [date] NULL,
[HorizonEndDate] [date] NULL,
[RawAuthorizationAccum] [numeric] (20, 6) NULL,
[RawAuthorizationStartDate] [date] NULL,
[RawAuthorizationEndDate] [date] NULL,
[FabAuthorizationAccum] [numeric] (20, 6) NULL,
[FabAuthorizationStartDate] [date] NULL,
[FabAuthorizationEndDate] [date] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NOT NULL CONSTRAINT [DF__OrderHead__RowCr__7388E913] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__OrderHead__RowCr__747D0D4C] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NOT NULL CONSTRAINT [DF__OrderHead__RowMo__75713185] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__OrderHead__RowMo__766555BE] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_OrderHeader_uRowModified] on [EDI].[OrderHeader] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		set	@TableName = 'EDI.OrderHeader'
		
		update
			ssoh
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.OrderHeader ssoh			join inserted i
				on i.RowID = ssoh.RowID
		
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
	EDI.OrderHeader
...

update
	...
from
	EDI.OrderHeader
...

delete
	...
from
	EDI.OrderHeader
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
ALTER TABLE [EDI].[OrderHeader] ADD CONSTRAINT [PK__OrderHea__FFEE7451B3E938F9] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[OrderHeader] ADD CONSTRAINT [UQ__OrderHea__1C40F0E7FEFA53A3] UNIQUE NONCLUSTERED  ([OrderHeaderGUID]) ON [PRIMARY]
GO
