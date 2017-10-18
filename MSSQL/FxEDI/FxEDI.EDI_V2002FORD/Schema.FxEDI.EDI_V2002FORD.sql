use fxEDI
go

select
	dr.DictionaryVersion
,	left(dr.Dictionary, 3)
,	min(dr.RowID)
,	max(dr.RowID)
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
group by
	dr.DictionaryVersion
,	left(dr.Dictionary, 3)
order by
	3


/*
Create schema Schema.FxEDI.EDI_V2002FORD.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('EDI_V2002FORD') is null begin
	exec sys.sp_executesql N'create schema EDI_V2002FORD authorization dbo'
end
go

/*
Create Table.FxEDI.EDI_V2002FORD.DictionaryTransactions.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionaryTransactions
if	objectproperty(object_id('EDI_V2002FORD.DictionaryTransactions'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionaryTransactions
	(	TransactionType varchar(25)
	,	TransactionDescription varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	TransactionType
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionaryTransactions_uRowModified on EDI_2002FORD.DictionaryTransactions
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionaryTransactions_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionaryTransactions_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionaryTransactions_uRowModified on EDI_V2002FORD.DictionaryTransactions after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_2002FORD.usp_Test
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
		set	@TableName = 'EDI_2002FORD.DictionaryTransactions'
		
		update
			dt
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionaryTransactions dt
			join inserted i
				on i.RowID = dt.RowID
		
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
	EDI_2002FORD.DictionaryTransactions
...

update
	...
from
	EDI_2002FORD.DictionaryTransactions
...

delete
	...
from
	EDI_2002FORD.DictionaryTransactions
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

insert
	EDI_V2002FORD.DictionaryTransactions
(	TransactionType
,	TransactionDescription
,	DictionaryRowID
)
select
	TransactionType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	TransactionDescription = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'TRN%'


/*
Create Table.FxEDI.EDI_V2002FORD.DictionaryTransactionSegments.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionaryTransactionSegments
if	objectproperty(object_id('EDI_V2002FORD.DictionaryTransactionSegments'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionaryTransactionSegments
	(	TransactionType varchar(25)
	,	SegmentOrdinal int
	,	SegmentCode varchar(25)
	,	Usage char(1)
	,	OccurrencesMin int
	,	OccurrencesMax int
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	TransactionType
		,	SegmentOrdinal
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionaryTransactionSegments_uRowModified on EDI_V2002FORD.DictionaryTransactionSegments
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionaryTransactionSegments_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionaryTransactionSegments_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionaryTransactionSegments_uRowModified on EDI_V2002FORD.DictionaryTransactionSegments after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V2002FORD.usp_Test
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
		set	@TableName = 'EDI_V2002FORD.DictionaryTransactionSegments'
		
		update
			dts
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionaryTransactionSegments dts
			join inserted i
				on i.RowID = dts.RowID
		
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
	EDI_V2002FORD.DictionaryTransactionSegments
...

update
	...
from
	EDI_V2002FORD.DictionaryTransactionSegments
...

delete
	...
from
	EDI_V2002FORD.DictionaryTransactionSegments
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

insert
	EDI_V2002FORD.DictionaryTransactionSegments
(	TransactionType
,	SegmentOrdinal
,	SegmentCode
,	Usage
,	OccurrencesMin
,	OccurrencesMax
,	DictionaryRowID
)
select
	TransactionType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	SegmentOrdinal = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	SegmentCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	Usage = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	OccurrencesMin = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	OccurrencesMax = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 7)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'SE1%'


/*
Create Table.FxEDI.EDI_V2002FORD.DictionarySegmentCodes.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionarySegmentCodes
if	objectproperty(object_id('EDI_V2002FORD.DictionarySegmentCodes'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionarySegmentCodes
	(	Code varchar(25)
	,	Description varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	Code
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionarySegmentCodes_uRowModified on EDI_V2002FORD.DictionarySegmentCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionarySegmentCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionarySegmentCodes_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionarySegmentCodes_uRowModified on EDI_V2002FORD.DictionarySegmentCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V2002FORD.usp_Test
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
		set	@TableName = 'EDI_V2002FORD.DictionarySegmentCodes'
		
		update
			dsc
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionarySegmentCodes dsc
			join inserted i
				on i.RowID = dsc.RowID
		
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
	EDI_V2002FORD.DictionarySegmentCodes
...

update
	...
from
	EDI_V2002FORD.DictionarySegmentCodes
...

delete
	...
from
	EDI_V2002FORD.DictionarySegmentCodes
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

insert
	EDI_V2002FORD.DictionarySegmentCodes
(	Code
,	Description
,	DictionaryRowID
)
select
	Code = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	Description = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'SE2%'


/*
Create Table.FxEDI.EDI_V2002FORD.DictionaryElementContents.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionaryElementContents
if	objectproperty(object_id('EDI_V2002FORD.DictionaryElementContents'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionaryElementContents
	(	ElementType char(1)
	,	Element varchar(25)
	,	ElementOrdinal int
	,	ElementCode varchar(25)
	,	ElementUsage char(1)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	ElementType
		,	Element
		,	ElementOrdinal
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionaryElementContents_uRowModified on EDI_V2002FORD.DictionaryElementContents
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionaryElementContents_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionaryElementContents_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionaryElementContents_uRowModified on EDI_V2002FORD.DictionaryElementContents after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V2002FORD.usp_Test
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
		set	@TableName = 'EDI_V2002FORD.DictionaryElementContents'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionaryElementContents dec
			join inserted i
				on i.RowID = dec.RowID
		
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
	EDI_V2002FORD.DictionaryElementContents
...

update
	...
from
	EDI_V2002FORD.DictionaryElementContents
...

delete
	...
from
	EDI_V2002FORD.DictionaryElementContents
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

insert
	EDI_V2002FORD.DictionaryElementContents
(	ElementType
,	Element
,	ElementOrdinal
,	ElementCode
,	ElementUsage
,	DictionaryRowID
)
select
	ElementType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	Element = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	ElementOrdinal = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	ElementCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	ElementUsage = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'EL1%'


/*
Create Table.FxEDI.EDI_V2002FORD.DictionaryElements.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionaryElements
if	objectproperty(object_id('EDI_V2002FORD.DictionaryElements'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionaryElements
	(	Element varchar(25)
	,	ElementName varchar(max)
	,	ElementDataType varchar(3)
	,	ElementLengthMin int
	,	ElementLengthMax int
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	Element
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionaryElements_uRowModified on EDI_V2002FORD.DictionaryElements
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionaryElements_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionaryElements_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionaryElements_uRowModified on EDI_V2002FORD.DictionaryElements after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V2002FORD.usp_Test
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
		set	@TableName = 'EDI_V2002FORD.DictionaryElements'
		
		update
			de
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionaryElements de
			join inserted i
				on i.RowID = de.RowID
		
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
	EDI_V2002FORD.DictionaryElements
...

update
	...
from
	EDI_V2002FORD.DictionaryElements
...

delete
	...
from
	EDI_V2002FORD.DictionaryElements
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

insert
	EDI_V2002FORD.DictionaryElements
(	Element
,	ElementName
,	ElementDataType
,	ElementLengthMin
,	ElementLengthMax
,	DictionaryRowID
)
select
	Element = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	ElementName = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	ElementDataType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	ElementLengthMin = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	ElementLengthMax = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'EL2%'


/*
Create Table.FxEDI.EDI_V2002FORD.DictionaryElementCodes.sql
*/

--use FxEDI
--go

--drop table EDI_V2002FORD.DictionaryElementCodes
if	objectproperty(object_id('EDI_V2002FORD.DictionaryElementCodes'), 'IsTable') is null begin

	create table EDI_V2002FORD.DictionaryElementCodes
	(	Number char(4)
	,	Code varchar(25)
	,	Description varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	Number
		,	Code
		)
	)
end
go

/*
Create trigger EDI_V2002FORD.tr_DictionaryElementCodes_uRowModified on EDI_V2002FORD.DictionaryElementCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V2002FORD.tr_DictionaryElementCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V2002FORD.tr_DictionaryElementCodes_uRowModified
end
go

create trigger EDI_V2002FORD.tr_DictionaryElementCodes_uRowModified on EDI_V2002FORD.DictionaryElementCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V2002FORD.usp_Test
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
		set	@TableName = 'EDI_V2002FORD.DictionaryElementCodes'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V2002FORD.DictionaryElementCodes dec
			join inserted i
				on i.RowID = dec.RowID
		
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
	EDI_V2002FORD.DictionaryElementCodes
...

update
	...
from
	EDI_V2002FORD.DictionaryElementCodes
...

delete
	...
from
	EDI_V2002FORD.DictionaryElementCodes
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

insert
	EDI_V2002FORD.DictionaryElementCodes
(	Number
,	Code
,	Description
,	DictionaryRowID
)
select
	Number = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	Code = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	Description = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	dr.RowID
from
	EDI.DictionaryRaw dr
where
	dr.DictionaryVersion = 'V2002FORD'
	and dr.Dictionary like 'COD%'
go
