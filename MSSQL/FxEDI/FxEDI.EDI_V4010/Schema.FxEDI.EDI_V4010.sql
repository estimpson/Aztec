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
	dr.DictionaryVersion = 'V4010'
group by
	dr.DictionaryVersion
,	left(dr.Dictionary, 3)
order by
	3


/*
Create schema Schema.FxEDI.EDI_V4010.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('EDI_V4010') is null begin
	exec sys.sp_executesql N'create schema EDI_V4010 authorization dbo'
end
go

/*
Create Table.FxEDI.EDI_V4010.DictionaryTransactions.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionaryTransactions
if	objectproperty(object_id('EDI_V4010.DictionaryTransactions'), 'IsTable') is null begin

	create table EDI_V4010.DictionaryTransactions
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
Create trigger EDI_V4010.tr_DictionaryTransactions_uRowModified on EDI_4010.DictionaryTransactions
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionaryTransactions_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionaryTransactions_uRowModified
end
go

create trigger EDI_V4010.tr_DictionaryTransactions_uRowModified on EDI_V4010.DictionaryTransactions after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_4010.usp_Test
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
		set	@TableName = 'EDI_4010.DictionaryTransactions'
		
		update
			dt
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionaryTransactions dt
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
	EDI_4010.DictionaryTransactions
...

update
	...
from
	EDI_4010.DictionaryTransactions
...

delete
	...
from
	EDI_4010.DictionaryTransactions
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
	EDI_V4010.DictionaryTransactions
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'TRN%'


/*
Create Table.FxEDI.EDI_V4010.DictionaryTransactionSegments.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionaryTransactionSegments
if	objectproperty(object_id('EDI_V4010.DictionaryTransactionSegments'), 'IsTable') is null begin

	create table EDI_V4010.DictionaryTransactionSegments
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
Create trigger EDI_V4010.tr_DictionaryTransactionSegments_uRowModified on EDI_V4010.DictionaryTransactionSegments
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionaryTransactionSegments_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionaryTransactionSegments_uRowModified
end
go

create trigger EDI_V4010.tr_DictionaryTransactionSegments_uRowModified on EDI_V4010.DictionaryTransactionSegments after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V4010.usp_Test
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
		set	@TableName = 'EDI_V4010.DictionaryTransactionSegments'
		
		update
			dts
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionaryTransactionSegments dts
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
	EDI_V4010.DictionaryTransactionSegments
...

update
	...
from
	EDI_V4010.DictionaryTransactionSegments
...

delete
	...
from
	EDI_V4010.DictionaryTransactionSegments
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
	EDI_V4010.DictionaryTransactionSegments
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'SE1%'


/*
Create Table.FxEDI.EDI_V4010.DictionarySegmentCodes.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionarySegmentCodes
if	objectproperty(object_id('EDI_V4010.DictionarySegmentCodes'), 'IsTable') is null begin

	create table EDI_V4010.DictionarySegmentCodes
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
Create trigger EDI_V4010.tr_DictionarySegmentCodes_uRowModified on EDI_V4010.DictionarySegmentCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionarySegmentCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionarySegmentCodes_uRowModified
end
go

create trigger EDI_V4010.tr_DictionarySegmentCodes_uRowModified on EDI_V4010.DictionarySegmentCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V4010.usp_Test
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
		set	@TableName = 'EDI_V4010.DictionarySegmentCodes'
		
		update
			dsc
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionarySegmentCodes dsc
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
	EDI_V4010.DictionarySegmentCodes
...

update
	...
from
	EDI_V4010.DictionarySegmentCodes
...

delete
	...
from
	EDI_V4010.DictionarySegmentCodes
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
	EDI_V4010.DictionarySegmentCodes
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'SE2%'


/*
Create Table.FxEDI.EDI_V4010.DictionaryElementContents.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionaryElementContents
if	objectproperty(object_id('EDI_V4010.DictionaryElementContents'), 'IsTable') is null begin

	create table EDI_V4010.DictionaryElementContents
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
Create trigger EDI_V4010.tr_DictionaryElementContents_uRowModified on EDI_V4010.DictionaryElementContents
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionaryElementContents_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionaryElementContents_uRowModified
end
go

create trigger EDI_V4010.tr_DictionaryElementContents_uRowModified on EDI_V4010.DictionaryElementContents after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V4010.usp_Test
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
		set	@TableName = 'EDI_V4010.DictionaryElementContents'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionaryElementContents dec
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
	EDI_V4010.DictionaryElementContents
...

update
	...
from
	EDI_V4010.DictionaryElementContents
...

delete
	...
from
	EDI_V4010.DictionaryElementContents
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
	EDI_V4010.DictionaryElementContents
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'EL1%'


/*
Create Table.FxEDI.EDI_V4010.DictionaryElements.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionaryElements
if	objectproperty(object_id('EDI_V4010.DictionaryElements'), 'IsTable') is null begin

	create table EDI_V4010.DictionaryElements
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
Create trigger EDI_V4010.tr_DictionaryElements_uRowModified on EDI_V4010.DictionaryElements
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionaryElements_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionaryElements_uRowModified
end
go

create trigger EDI_V4010.tr_DictionaryElements_uRowModified on EDI_V4010.DictionaryElements after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V4010.usp_Test
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
		set	@TableName = 'EDI_V4010.DictionaryElements'
		
		update
			de
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionaryElements de
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
	EDI_V4010.DictionaryElements
...

update
	...
from
	EDI_V4010.DictionaryElements
...

delete
	...
from
	EDI_V4010.DictionaryElements
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
	EDI_V4010.DictionaryElements
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'EL2%'


/*
Create Table.FxEDI.EDI_V4010.DictionaryElementCodes.sql
*/

--use FxEDI
--go

--drop table EDI_V4010.DictionaryElementCodes
if	objectproperty(object_id('EDI_V4010.DictionaryElementCodes'), 'IsTable') is null begin

	create table EDI_V4010.DictionaryElementCodes
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
Create trigger EDI_V4010.tr_DictionaryElementCodes_uRowModified on EDI_V4010.DictionaryElementCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_V4010.tr_DictionaryElementCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_V4010.tr_DictionaryElementCodes_uRowModified
end
go

create trigger EDI_V4010.tr_DictionaryElementCodes_uRowModified on EDI_V4010.DictionaryElementCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_V4010.usp_Test
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
		set	@TableName = 'EDI_V4010.DictionaryElementCodes'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_V4010.DictionaryElementCodes dec
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
	EDI_V4010.DictionaryElementCodes
...

update
	...
from
	EDI_V4010.DictionaryElementCodes
...

delete
	...
from
	EDI_V4010.DictionaryElementCodes
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
	EDI_V4010.DictionaryElementCodes
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
	dr.DictionaryVersion = 'V4010'
	and dr.Dictionary like 'COD%'
go
