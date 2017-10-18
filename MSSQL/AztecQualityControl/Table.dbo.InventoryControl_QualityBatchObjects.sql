
/*
Create table Fx.dbo.InventoryControl_QualityBatchObjects
*/

--use Fx
--go

--drop table dbo.InventoryControl_QualityBatchObjects
if	objectproperty(object_id('dbo.InventoryControl_QualityBatchObjects'), 'IsTable') is null begin

	create table dbo.InventoryControl_QualityBatchObjects
	(	QualityBatchNumber varchar(50) references dbo.InventoryControl_QualityBatchHeaders(QualityBatchNumber)
	,	Line float
	,	Serial int
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	Part varchar(25) not null
	,	OriginalQuantity numeric(20,6) not null
	,	Unit char(2) not null
	,	OriginalStatus varchar(30) not null
	,	NewStatus varchar(30) null
	,	ScrapQuantity numeric(20,6) null
	,	Notes varchar(max) null
	,	RowID int identity(1,1) primary key nonclustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique clustered
		(	QualityBatchNumber
		,	Line
		)
	,	unique nonclustered
		(	QualityBatchNumber
		,	Serial
		)
	)
end
go

/*
Create trigger dbo.tr_InventoryControl_QualityBatchObjects_uRowModified on dbo.InventoryControl_QualityBatchObjects
*/

--use Fx
--go

if	objectproperty(object_id('dbo.tr_InventoryControl_QualityBatchObjects_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger dbo.tr_InventoryControl_QualityBatchObjects_uRowModified
end
go

create trigger dbo.tr_InventoryControl_QualityBatchObjects_uRowModified on dbo.InventoryControl_QualityBatchObjects after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
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
	--- <Update rows="*">
	set	@TableName = 'dbo.InventoryControl_QualityBatchObjects'
	
	update
		icqbo
	set	RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.InventoryControl_QualityBatchObjects icqbo
		join inserted i
			on i.RowID = icqbo.RowID
	
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
	dbo.InventoryControl_QualityBatchObjects
...

update
	...
from
	dbo.InventoryControl_QualityBatchObjects
...

delete
	...
from
	dbo.InventoryControl_QualityBatchObjects
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

select
	icqbo.QualityBatchNumber
,	icqbo.Line
,	icqbo.Serial
,	icqbo.Status
,	icqbo.Type
,	icqbo.Part
,	icqbo.OriginalQuantity
,	ScrappedQuantity = (select sum(at.std_quantity) from dbo.audit_trail at where at.serial = icqbo.Serial and at.date_stamp between icqbh.SortBeginDT and coalesce(icqbh.SortEndDT, getdate()) and at.type = 'Q' and to_loc in ('S'))
,	RemainingQuantity = coalesce(o.std_quantity, 0)
,	icqbo.Unit
,	icqbo.OriginalStatus
,	CurrentStatus = o.user_defined_status
,	icqbo.NewStatus
,	icqbo.ScrapQuantity
,	icqbo.Notes
,	icqbo.RowID
,	BoxLabelFormat = pi.label_format
,	Change = convert(char(1000), '')
,	IsSelected = 0
,	MarkAll = 0
from
	dbo.InventoryControl_QualityBatchObjects icqbo
	join dbo.InventoryControl_QualityBatchHeaders icqbh
		on icqbh.QualityBatchNumber = icqbo.QualityBatchNumber
	left join dbo.object o
		on o.serial = icqbo.Serial
	left join dbo.part_inventory pi
		on pi.part = icqbo.Part
where
	icqbo.QualityBatchNumber = :QualityBatchNumber
order by
	icqbo.QualityBatchNumber
,	icqbo.Line
