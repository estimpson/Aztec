use fxEDI
go

select
	dr.DictionaryVersion
,	left(dr.Dictionary, 3)
,	min(dr.RowID)
,	max(dr.RowID)
from
	EDI_DICT.DictionaryRaw dr
group by
	dr.DictionaryVersion
,	left(dr.Dictionary, 3)
order by
	3


/*
Create schema Schema.FxEDI_DICT.EDI_DICT.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('EDI_DICT') is null begin
	exec sys.sp_executesql N'create schema EDI_DICT authorization dbo'
end
go


/*
Create Table.FxEDI_DICT.EDI_DICT.DictionaryTransactions.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionaryTransactions
if	objectproperty(object_id('EDI_DICT.DictionaryTransactions'), 'IsTable') is null begin

	create table EDI_DICT.DictionaryTransactions
	(	DictionaryVersion varchar(25)
	,	TransactionType varchar(25)
	,	TransactionDescription varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	DictionaryVersion
		,	TransactionType
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionaryTransactions_uRowModified on EDI_4010.DictionaryTransactions
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionaryTransactions_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionaryTransactions_uRowModified
end
go

create trigger EDI_DICT.tr_DictionaryTransactions_uRowModified on EDI_DICT.DictionaryTransactions after update
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
			EDI_DICT.DictionaryTransactions dt
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
	EDI_DICT.DictionaryTransactions
(	DictionaryVersion
,	TransactionType
,	TransactionDescription
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	TransactionType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	TransactionDescription = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'TRN%'
go


/*
Create Table.FxEDI_DICT.EDI_DICT.DictionaryTransactionSegments.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionaryTransactionSegments
if	objectproperty(object_id('EDI_DICT.DictionaryTransactionSegments'), 'IsTable') is null begin

	create table EDI_DICT.DictionaryTransactionSegments
	(	DictionaryVersion varchar(25)
	,	TransactionType varchar(25)
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
		(	DictionaryVersion
		,	TransactionType
		,	SegmentOrdinal
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionaryTransactionSegments_uRowModified on EDI_DICT.DictionaryTransactionSegments
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionaryTransactionSegments_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionaryTransactionSegments_uRowModified
end
go

create trigger EDI_DICT.tr_DictionaryTransactionSegments_uRowModified on EDI_DICT.DictionaryTransactionSegments after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionaryTransactionSegments'
		
		update
			dts
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionaryTransactionSegments dts
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
	EDI_DICT.DictionaryTransactionSegments
...

update
	...
from
	EDI_DICT.DictionaryTransactionSegments
...

delete
	...
from
	EDI_DICT.DictionaryTransactionSegments
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
	EDI_DICT.DictionaryTransactionSegments
(	DictionaryVersion
,	TransactionType
,	SegmentOrdinal
,	SegmentCode
,	Usage
,	OccurrencesMin
,	OccurrencesMax
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	TransactionType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	SegmentOrdinal = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	SegmentCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	Usage = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	OccurrencesMin = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	OccurrencesMax = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 7)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'SE1%'
go

/*
Create Table.FxEDI_DICT.EDI_DICT.DictionarySegmentCodes.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionarySegmentCodes
if	objectproperty(object_id('EDI_DICT.DictionarySegmentCodes'), 'IsTable') is null begin

	create table EDI_DICT.DictionarySegmentCodes
	(	DictionaryVersion varchar(25)
	,	Code varchar(25)
	,	Description varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	DictionaryVersion
		,	Code
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionarySegmentCodes_uRowModified on EDI_DICT.DictionarySegmentCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionarySegmentCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionarySegmentCodes_uRowModified
end
go

create trigger EDI_DICT.tr_DictionarySegmentCodes_uRowModified on EDI_DICT.DictionarySegmentCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionarySegmentCodes'
		
		update
			dsc
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionarySegmentCodes dsc
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
	EDI_DICT.DictionarySegmentCodes
...

update
	...
from
	EDI_DICT.DictionarySegmentCodes
...

delete
	...
from
	EDI_DICT.DictionarySegmentCodes
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
	EDI_DICT.DictionarySegmentCodes
(	DictionaryVersion
,	Code
,	Description
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	Code = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	Description = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'SE2%'
go


/*
Create Table.FxEDI_DICT.EDI_DICT.DictionarySegmentContents.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionarySegmentContents
if	objectproperty(object_id('EDI_DICT.DictionarySegmentContents'), 'IsTable') is null begin

	create table EDI_DICT.DictionarySegmentContents
	(	DictionaryVersion varchar(25)
	,	ContentType char(1)
	,	Segment varchar(25)
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
		(	DictionaryVersion
		,	ContentType
		,	Segment
		,	ElementOrdinal
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionarySegmentContents_uRowModified on EDI_DICT.DictionarySegmentContents
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionarySegmentContents_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionarySegmentContents_uRowModified
end
go

create trigger EDI_DICT.tr_DictionarySegmentContents_uRowModified on EDI_DICT.DictionarySegmentContents after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionarySegmentContents'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionarySegmentContents dec
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
	EDI_DICT.DictionarySegmentContents
...

update
	...
from
	EDI_DICT.DictionarySegmentContents
...

delete
	...
from
	EDI_DICT.DictionarySegmentContents
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
	EDI_DICT.DictionarySegmentContents
(	DictionaryVersion
,	ContentType
,	Segment
,	ElementOrdinal
,	ElementCode
,	ElementUsage
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	ContentType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	Segment = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	ElementOrdinal = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	ElementCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	ElementUsage = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'EL1%'
go


/*
Create Table.FxEDI_DICT.EDI_DICT.DictionaryElements.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionaryElements
if	objectproperty(object_id('EDI_DICT.DictionaryElements'), 'IsTable') is null begin

	create table EDI_DICT.DictionaryElements
	(	DictionaryVersion varchar(25)
	,	ElementCode varchar(25)
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
		(	DictionaryVersion
		,	ElementCode
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionaryElements_uRowModified on EDI_DICT.DictionaryElements
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionaryElements_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionaryElements_uRowModified
end
go

create trigger EDI_DICT.tr_DictionaryElements_uRowModified on EDI_DICT.DictionaryElements after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionaryElements'
		
		update
			de
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionaryElements de
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
	EDI_DICT.DictionaryElements
...

update
	...
from
	EDI_DICT.DictionaryElements
...

delete
	...
from
	EDI_DICT.DictionaryElements
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
	EDI_DICT.DictionaryElements
(	DictionaryVersion
,	ElementCode
,	ElementName
,	ElementDataType
,	ElementLengthMin
,	ElementLengthMax
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	ElementCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	ElementName = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	ElementDataType = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	ElementLengthMin = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 5)
,	ElementLengthMax = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 6)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'EL2%'
go

/*
Create Table.FxEDI_DICT.EDI_DICT.DictionaryElementValueCodes.sql
*/

--use FxEDI
--go

--drop table EDI_DICT.DictionaryElementValueCodes
if	objectproperty(object_id('EDI_DICT.DictionaryElementValueCodes'), 'IsTable') is null begin

	create table EDI_DICT.DictionaryElementValueCodes
	(	DictionaryVersion varchar(25)
	,	ElementCode char(4)
	,	ValueCode varchar(25)
	,	Description varchar(max)
	,	DictionaryRowID int
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	DictionaryVersion
		,	ElementCode
		,	ValueCode
		)
	)
end
go

/*
Create trigger EDI_DICT.tr_DictionaryElementValueCodes_uRowModified on EDI_DICT.DictionaryElementValueCodes
*/

--use FxEDI
--go

if	objectproperty(object_id('EDI_DICT.tr_DictionaryElementValueCodes_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI_DICT.tr_DictionaryElementValueCodes_uRowModified
end
go

create trigger EDI_DICT.tr_DictionaryElementValueCodes_uRowModified on EDI_DICT.DictionaryElementValueCodes after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_DICT.usp_Test
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
		set	@TableName = 'EDI_DICT.DictionaryElementValueCodes'
		
		update
			dec
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_DICT.DictionaryElementValueCodes dec
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
	EDI_DICT.DictionaryElementValueCodes
...

update
	...
from
	EDI_DICT.DictionaryElementValueCodes
...

delete
	...
from
	EDI_DICT.DictionaryElementValueCodes
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
	EDI_DICT.DictionaryElementValueCodes
(	DictionaryVersion
,	ElementCode
,	ValueCode
,	Description
,	DictionaryRowID
)
select
	dr.DictionaryVersion
,	ElementCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 2)
,	ValueCode = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 3)
,	Description = fxAztec.dbo.fn_SplitStringToArray(dr.Dictionary, char(1), 4)
,	dr.RowID
from
	EDI_DICT.DictionaryRaw dr
where
	dr.Dictionary like 'COD%'
go
