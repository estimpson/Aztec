
/*
Create Table.FxAztec.EDI_iConnect.ShipNoticeAcknowledgements.sql
*/

use FxAztec
go

--drop table EDI_iConnect.ShipNoticeAcknowledgements
if	objectproperty(object_id('EDI_iConnect.ShipNoticeAcknowledgements'), 'IsTable') is null begin

	create table EDI_iConnect.ShipNoticeAcknowledgements
	(	RawDocumentGUID uniqueidentifier not null
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	DocumentImportDT datetime null
	,	ASN_Number varchar(30) null
	,	ShipDate datetime null
	,	SupplierCode varchar(30) null
	,	AcknowledgementStatus int null
	,	ValidationOutput varchar(max) null
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	RawDocumentGUID
		)
	)
end
go

create nonclustered index ix_ShipNoticeAcknowledgements_1 on EDI_iConnect.ShipNoticeAcknowledgements (Status)
go

/*
Create trigger EDI_iConnect.tr_ShipNoticeAcknowledgements_uRowModified on EDI_iConnect.ShipNoticeAcknowledgements
*/

--use FxAztec
--go

if	objectproperty(object_id('EDI_iConnect.tr_ShipNoticeAcknowledgements_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_iConnect.tr_ShipNoticeAcknowledgements_uRowModified
end
go

create trigger EDI_iConnect.tr_ShipNoticeAcknowledgements_uRowModified on EDI_iConnect.ShipNoticeAcknowledgements after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_iConnect.usp_Test
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
		set	@TableName = 'EDI_iConnect.ShipNoticeAcknowledgements'
		
		update
			sna
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_iConnect.ShipNoticeAcknowledgements sna
			join inserted i
				on i.RowID = sna.RowID
		
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
	EDI_iConnect.ShipNoticeAcknowledgements
...

update
	...
from
	EDI_iConnect.ShipNoticeAcknowledgements
...

delete
	...
from
	EDI_iConnect.ShipNoticeAcknowledgements
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
go

