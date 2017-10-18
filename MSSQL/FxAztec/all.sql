
/*
Create Procedure.FxAztec.EDI.usp_XMLShipNotice_CreateOutboundFile.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.usp_XMLShipNotice_CreateOutboundFile'), 'IsProcedure') = 1 begin
	drop procedure EDI.usp_XMLShipNotice_CreateOutboundFile
end
go

create procedure EDI.usp_XMLShipNotice_CreateOutboundFile
	@XMLData xml
,	@ShipperID int
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings on
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDISupplier.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
declare
	@fileStreamID table
(	FileStreamID uniqueidentifier
)

set ansi_warnings on
		
declare
	@outboundPath sysname =	'\RawEDIData\CustomerEDI\Outbound\Staging'
			
insert
	FxEDI.dbo.RawEDIData
(	file_stream
,	name
,	path_locator
)
output
	inserted.stream_id into @fileStreamID
values
(	convert(varbinary(max), @xmlData)
,	FxEDI.EDI.udf_GetNextRawEDIData_OutboundXML_FileName (@outboundPath)
,	FxEDI.FxFS.udf_GetFilePathLocator(@outboundPath)
)

set ansi_warnings off

insert
	dbo.CustomerEDI_GenerationLog
(	FileStreamID
,	Type
,	ShipperID
,	FileGenerationDT
,	OriginalFileName
,	CurrentFilePath
)
select
	FileStreamID = red.stream_id
,	Type = 1
,	ShipperID = @ShipperID
,	FileGenerationDT = red.last_write_time
,	OriginalFileName = red.name
,	CurrentFilePath = red.file_stream.GetFileNamespacePath()
from
	FxEDI.dbo.RawEDIData red
	join @fileStreamID fsi
		on fsi.FileStreamID = red.stream_id
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>
go


/*
Create Procedure.FxAztec.EDI.usp_XMLShipNotice_GetShipNoticeXML.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.usp_XMLShipNotice_GetShipNoticeXML'), 'IsProcedure') = 1 begin
	drop procedure EDI.usp_XMLShipNotice_GetShipNoticeXML
end
go

create procedure EDI.usp_XMLShipNotice_GetShipNoticeXML
	@ShipperID int = 1063866
,	@XMLShipNotice_FunctionName sysname = 'EDIShipNoticeXML_AmericanAxle.udf_ShipNotice_Root'
,	@PurposeCode char(2) = '00'
,	@Complete bit = 0
,	@XMLShipNotice xml = null out
,	@TranDT datetime = null out
,	@Result integer = null out
as
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

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Get the data. */
declare
	@Statement nvarchar(max) = '
select
	@XMLOutput = convert(nvarchar(max), ' + @XMLShipNotice_FunctionName + '(' + convert(varchar, @ShipperID) + ', ''' + @PurposeCode + ''', ' + convert(char(1), @Complete) + '))
'
,	@XMLOutput nvarchar(max)

execute
	sys.sp_executesql
	@stmt = @Statement
,	@parameters = N'@XMLOutput nvarchar(max) output'
,	@XMLOutput = @XMLOutput out

set	@XMLShipNotice = convert(xml, @XMLOutput)
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
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

declare
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_XMLShipNotice_GetShipNoticeXML
	@Param1 = @Param1
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

/*
Create Procedure.FxAztec.EDI.usp_CustomerEDI_SendShipNotices.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.usp_CustomerEDI_SendShipNotices'), 'IsProcedure') = 1 begin
	drop procedure EDI.usp_CustomerEDI_SendShipNotices
end
go

create procedure EDI.usp_CustomerEDI_SendShipNotices
	@ShipperList varchar(max) = null
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings on
set ansi_nulls on

set @Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname
,	@TableName sysname
,	@ProcName sysname
,	@ProcReturn integer
,	@ProcResult integer
,	@Error integer
,	@RowCount integer

set @ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare	@TranCount smallint

set @TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set @TranDT = coalesce(@TranDT, getdate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Get the list of Ship Notices to send.*/
declare	@PendingShipNotices table
(	ShipperID int
,	FunctionName sysname
)

if	@ShipperList > '' begin
	insert
		@PendingShipNotices
	select
		s.id
	,	xsnadrf.FunctionName
	from
		dbo.shipper s
		join dbo.edi_setups es
			on es.destination = s.destination
		join EDI.XMLShipNotice_ASNDataRootFunction xsnadrf
			on xsnadrf.ASNOverlayGroup = es.asn_overlay_group
	where
		s.id in
			(	select
					convert(int, ltrim(rtrim(fsstr.Value)))
				from
					dbo.fn_SplitStringToRows(@ShipperList, ',') fsstr
				where
					ltrim(rtrim(fsstr.Value)) like '%[0-9]%'
					and ltrim(rtrim(fsstr.Value)) not like '%[^0-9]%'
			)
end
else begin
	insert
		@PendingShipNotices
	select
		s.id
	,	xsnadrf.FunctionName
	from
		dbo.shipper s
		join dbo.edi_setups es
			on es.destination = s.destination
		join EDI.XMLShipNotice_ASNDataRootFunction xsnadrf
			on xsnadrf.ASNOverlayGroup = es.asn_overlay_group
	where
		coalesce(s.type, 'N') = 'N'
		and s.status = 'C'
		and s.date_shipped > getdate() - 8
end

declare
	PendingShipNotices cursor local for
select
	*
from
	@PendingShipNotices psn

open
	PendingShipNotices

while
	1 = 1 begin

	declare
		@ShipperID int
	,	@XMLShipNotice_FunctionName sysname
	,	@XMLShipNotice xml

	fetch
		PendingShipNotices
	into
		@ShipperID
	,	@XMLShipNotice_FunctionName

	if	@@FETCH_STATUS != 0 begin
		break
	end

	select
		ShipperID = @ShipperID
	,	XMLShipNotice_FunctionName = @XMLShipNotice_FunctionName

	--- <Call>	
	set	@CallProcName = 'EDI.usp_XMLShipNotice_GetShipNoticeXML'
	execute
		@ProcReturn = EDI.usp_XMLShipNotice_GetShipNoticeXML
		@ShipperID = @ShipperID
	,	@XMLShipNotice_FunctionName = @XMLShipNotice_FunctionName
	,	@PurposeCode = '00'
	,	@Complete = 1
	,	@XMLShipNotice = @XMLShipNotice out
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set @Error = @@Error
	if @Error != 0 begin
		set @Result = 900501
		raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return
	end
	if @ProcReturn != 0 begin
		set @Result = 900502
		raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return
	end
	if @ProcResult != 0 begin
		set @Result = 900502
		raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return
	end
	--- </Call>

	select
		XMLData = @XMLShipNotice
	,	ShipperID = @ShipperID

	/*	Generate file for each Ship Notice.*/
	--- <Call>	
	set @CallProcName = 'EDI.usp_XMLShipNotice_CreateOutboundFile'
	execute
		@ProcReturn = EDI.usp_XMLShipNotice_CreateOutboundFile
		@XMLData = @XMLShipNotice
	,	@ShipperID = @ShipperID
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set @Error = @@Error
	if @Error != 0 begin
		set @Result = 900501
		raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if @ProcReturn != 0 begin
		set @Result = 900502
		raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if @ProcResult != 0 begin
		set @Result = 900502
		raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
	
	end

---	<CloseTran AutoCommit=Yes>
commit tran @ProcName
---	</CloseTran AutoCommit=Yes>

/*	Send EDI. */
--- <Call>	
set @CallProcName = 'FxEDI.FTP.usp_SendCustomerEDI'
execute
	@ProcReturn = FxEDI.FTP.usp_SendCustomerEDI
	@SendFileFromFolderRoot = '\RawEDIData\CustomerEDI\OutBound'
,	@SendFileNamePattern = '%[0-9][0-9][0-9][0-9][0-9].xml'
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set @Error = @@Error
if	@Error != 0 begin
	set @Result = 900501
	raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	return
end
if	@ProcReturn != 0 begin
	set @Result = 900502
	raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	return
end
if	@ProcResult != 0 begin
	set @Result = 900502
	raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	return
end
--- </Call>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
set @TranCount = @@TranCount
if @TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set @TranDT = coalesce(@TranDT, getdate())
--- </Tran>

/*	Mark shippers as EDI Sent. */
--- <Update rows="*">
set @TableName = 'dbo.shipper'

update
	s
set	
	s.status = 'Z'
from
	dbo.shipper s
	join @PendingShipNotices psn
		on psn.ShipperID = s.id

select
	@Error = @@Error
,	@RowCount = @@Rowcount

if	@Error != 0 begin
	set @Result = 999999
	raiserror ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

--	<Return>
set @Result = 0
return
	@Result
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

declare
	@ShipperList varchar(max) = '76053, 76023'

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_CustomerEDI_SendShipNotices
	@ShipperList = @ShipperList
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

select
	*
from
	FxEDI.FTP.LogDetails fld
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


/*
Create ScalarFunction.FxAztec.EDI.udf_FormatDT(SYNONYM).sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.udf_FormatDT'), 'IsScalarFunction') = 1 begin
	drop function EDI.udf_FormatDT
end
go

if	objectpropertyex(object_id('EDI.udf_FormatDT'), 'BaseType') = 'FN' begin
	drop synonym EDI.udf_FormatDT
end
go

create synonym EDI.udf_FormatDT for FxUtilities.dbo.FormatDT
go

/*
Create Table.FxAztec.EDI.XMLShipNotice_ASNDataRootFunction.sql
*/

use FxAztec
go

--drop table EDI.XMLShipNotice_ASNDataRootFunction
if	objectproperty(object_id('EDI.XMLShipNotice_ASNDataRootFunction'), 'IsTable') is null begin

	create table EDI.XMLShipNotice_ASNDataRootFunction
	(	ASNOverlayGroup varchar(50) not null
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	FunctionName sysname not null
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	ASNOverlayGroup
		)
	)
end
go

/*
Create trigger EDI.tr_XMLShipNotice_ASNDataRootFunction_uRowModified on EDI.XMLShipNotice_ASNDataRootFunction
*/

--use FxAztec
--go

if	objectproperty(object_id('EDI.tr_XMLShipNotice_ASNDataRootFunction_uRowModified'), 'IsTrigger') = 1 begin
	drop trigger EDI.tr_XMLShipNotice_ASNDataRootFunction_uRowModified
end
go

create trigger EDI.tr_XMLShipNotice_ASNDataRootFunction_uRowModified on EDI.XMLShipNotice_ASNDataRootFunction after update
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
		set	@TableName = 'EDI.XMLShipNotice_ASNDataRootFunction'
		
		update
			xsnarf
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.XMLShipNotice_ASNDataRootFunction xsnarf
			join inserted i
				on i.RowID = xsnarf.RowID
		
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
	EDI.XMLShipNotice_ASNDataRootFunction
...

update
	...
from
	EDI.XMLShipNotice_ASNDataRootFunction
...

delete
	...
from
	EDI.XMLShipNotice_ASNDataRootFunction
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
	*
from
	EDI.XMLShipNotice_ASNDataRootFunction xsnadrf
/*
Create ScalarFunction.FxAztec.EDI_XML.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.CE
end
go

create function EDI_XML.CE
(	@dictionaryVersion varchar(25)
,	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@elementCode = right('0000' + ltrim(rtrim(@elementCode)), 4)

	set	@xmlOutput =
	/*	CE */
		(	select
				code = de.ElementCode
			,	name = de.ElementName
			/*	DE(s)*/
			,	@de
			from
				fxEDI.EDI_DICT.DictionaryElements de
			where
				de.DictionaryVersion = coalesce
					(	(	select
					 			deR.DictionaryVersion
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deR
							where
								deR.DictionaryVersion = @dictionaryVersion
								and deR.ElementCode = @elementCode
					 	)
					,	(	select
					 			max(deP.DictionaryVersion)
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deP
							where
								deP.DictionaryVersion < @dictionaryVersion
								and deP.ElementCode = @elementCode
					 	)
					,	(	select
					 			min(deP.DictionaryVersion)
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deP
							where
								deP.DictionaryVersion > @dictionaryVersion
								and deP.ElementCode = @elementCode
					 	)
					)
				and de.ElementCode = @elementCode
			for xml raw ('CE'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.DictionaryVersion = '004010'
	and de.ElementCode = 'C001'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElementValueCodes devc
where
	devc.DictionaryVersion = '004010'
	and devc.ElementCode = '0355'
	and devc.ValueCode = 'LB'

select
	EDI_XML.CE('004010', 'C001', EDI_XML.DE('004010', '0355', 'LB'))

select
	EDI_XML.CE('004010', 'C001', null)

select
	EDI_XML.DE('004010', '0355', 'LB')

select
	code = de.ElementCode
,	name = de.ElementName
/*	DE(s)*/
,	null
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.DictionaryVersion = coalesce
		(	(	select
					deR.DictionaryVersion
				from
					fxEDI.EDI_DICT.DictionaryElements deR
				where
					deR.DictionaryVersion = '004010'
					and deR.ElementCode = 'C001'
			)
		,	(	select
					max(deP.DictionaryVersion)
				from
					fxEDI.EDI_DICT.DictionaryElements deP
				where
					deP.DictionaryVersion < '004010'
					and deP.ElementCode = 'C001'
			)
		,	(	select
					min(deP.DictionaryVersion)
				from
					fxEDI.EDI_DICT.DictionaryElements deP
				where
					deP.DictionaryVersion > '004010'
					and deP.ElementCode = 'C001'
			)
		)
	and de.ElementCode = 'C001'
/*
Create ScalarFunction.FxAztec.EDI_XML.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.DE
end
go

create function EDI_XML.DE
(	@dictionaryVersion varchar(25)
,	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@elementCode = right('0000' + ltrim(rtrim(@elementCode)), 4)

	set	@xmlOutput =
	/*	DE */
		(	select
				Tag = 1
			,	Parent = null
			,	[DE!1!code] = rtrim(@elementCode)
			,	[DE!1!name] = coalesce(de.ElementName, '')
			,	[DE!1!type] = case when de.ElementDataType = 'ID' and devc.Description is null then 'AN' else coalesce(de.ElementDataType, '') end
			,	[DE!1!desc] = devc.Description
			,	[DE!1] = @value
			from
				(	select
						'' dummy
				) dummy
				left join fxEDI.EDI_DICT.DictionaryElements de
					on de.DictionaryVersion = coalesce
						(	(	select
						 			deR.DictionaryVersion
						 		from
						 			fxEDI.EDI_DICT.DictionaryElements deR
								where
									deR.DictionaryVersion = @dictionaryVersion
									and deR.ElementCode = @elementCode
						 	)
						,	(	select
						 			max(deP.DictionaryVersion)
						 		from
						 			fxEDI.EDI_DICT.DictionaryElements deP
								where
									deP.DictionaryVersion < @dictionaryVersion
									and deP.ElementCode = @elementCode
						 	)
						,	(	select
						 			min(deP.DictionaryVersion)
						 		from
						 			fxEDI.EDI_DICT.DictionaryElements deP
								where
									deP.DictionaryVersion > @dictionaryVersion
									and deP.ElementCode = @elementCode
						 	)
						)
					and de.ElementCode = @elementCode
				left join fxEDI.EDI_DICT.DictionaryElementValueCodes devc
					on devc.DictionaryVersion = @dictionaryVersion
					and devc.ElementCode = @elementCode
					and devc.ValueCode = @value
					and de.ElementDataType = 'ID'
			for xml explicit, type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.DictionaryVersion = '002002FORD'
	and de.ElementCode = '0353'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElementValueCodes devc
where
	devc.DictionaryVersion = '002002FORD'
	and devc.ElementCode = '0353'
	and devc.ValueCode = '00'

select
	EDI_XML.DE('002002FORD', '353', '00')
/*
Create ScalarFunction.FxAztec.EDI_XML.FormatDate.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.FormatDate'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.FormatDate
end
go

create function EDI_XML.FormatDate
(	@dictionaryVersion varchar(25)
,	@date date
)
returns varchar(12)
as
begin
--- <Body>
	declare
		@dateString varchar(12)
	,	@dateFormat varchar(12)

	select
		@dateFormat = ddf.FormatString
	from
		FxEDI.EDI_DICT.DictionaryDTFormat ddf
	where
		ddf.DictionaryVersion = coalesce
			(	(	select
						ddfR.DictionaryVersion
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfR
					where
						ddfR.DictionaryVersion = @dictionaryVersion
						and ddfR.Type = 1
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 1
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 1
				)
			)
		and ddf.Type = 1

	set @dateString = EDI.udf_FormatDT(@dateFormat, @date)
--- </Body>

---	<Return>
	return
		@dateString
end
go

select
	EDI_XML.FormatDate('002040', getdate())

/*
Create ScalarFunction.FxAztec.EDI_XML.FormatTime.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.FormatTime'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.FormatTime
end
go

create function EDI_XML.FormatTime
(	@dictionaryVersion varchar(25)
,	@time time
)
returns varchar(12)
as
begin
--- <Body>
	declare
		@timeString varchar(12)
	,	@timeFormat varchar(12)

	select
		@timeFormat = ddf.FormatString
	from
		FxEDI.EDI_DICT.DictionaryDTFormat ddf
	where
		ddf.DictionaryVersion = coalesce
			(	(	select
						ddfR.DictionaryVersion
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfR
					where
						ddfR.DictionaryVersion = @dictionaryVersion
						and ddfR.Type = 2
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 2
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 2
				)
			)
		and ddf.Type = 2

	set @timeString = EDI.udf_FormatDT(@timeFormat, @time)
--- </Body>

---	<Return>
	return
		@timeString
end
go

select
	EDI_XML.FormatTime('002040', getdate())

/*
Create ScalarFunction.FxAztec.EDI_XML.LOOP_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.LOOP_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.LOOP_INFO
end
go

create function EDI_XML.LOOP_INFO
(	@loopCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
	/*	CE */
		(	select
				name = @loopCode + ' Loop'
			for xml raw ('LOOP-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.LOOP_INFO ('HL')
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_BIG.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_BIG'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_BIG
end
go

create function EDI_XML.SEG_BIG
(	@dictionaryVersion varchar(25)
,	@invoiceDate date
,	@invoiceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'BIG')
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion, @invoiceDate))
			,	EDI_XML.DE(@dictionaryVersion, '0076', @invoiceNumber)
			for xml raw ('SEG-BIG'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_BIG('002002FORD', getdate(), '01350')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_BSN
end
go

create function EDI_XML.SEG_BSN
(	@dictionaryVersion varchar(25)
,	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'BSN')
			,	EDI_XML.DE(@dictionaryVersion, '0353', @purposeCode)
			,	EDI_XML.DE(@dictionaryVersion, '0396', @shipperID)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@shipDate))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@shipTime))
			for xml raw ('SEG-BSN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_BSN('002002FORD', '00', 75964, '2016-04-29', '10:11')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_CLD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_CLD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_CLD
end
go

create function EDI_XML.SEG_CLD
(	@dictionaryVersion varchar(25)
,	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'CLD')
			,	EDI_XML.DE(@dictionaryVersion, '0622', @loads)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @units)
			,	EDI_XML.DE(@dictionaryVersion, '0103', @packageCode)
			for xml raw ('SEG-CLD'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_CLD('002002FORD', 5, 100, 'CTN90')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_CTT
end
go

create function EDI_XML.SEG_CTT
(	@dictionaryVersion varchar(25)
,	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'CTT')
			,	EDI_XML.DE(@dictionaryVersion, '0354', @lineCount)
			,	case when @hashTotal is not null then EDI_XML.DE(@dictionaryVersion, '0347', @hashTotal) end
			for xml raw ('SEG-CTT'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_CTT('002002FORD', 12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_DTM
end
go

create function EDI_XML.SEG_DTM
(	@dictionaryVersion varchar(25)
,	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'DTM')
			,	EDI_XML.DE(@dictionaryVersion, '0374', @dateCode)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@dateTime))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@dateTime))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_DTM('002002FORD', '011', '2016-04-28 10:18')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_ETD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_ETD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_ETD
end
go

create function EDI_XML.SEG_ETD
(	@dictionaryVersion varchar(25)
,	@transportationReasonCode varchar(3)
,	@transportationResponsibilityCode varchar(3)
,	@referenceNumberQualifier varchar(3)
,	@referenceNumber varchar(30)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'ETD')
			,	EDI_XML.DE(@dictionaryVersion, '0626', @transportationReasonCode)
			,	EDI_XML.DE(@dictionaryVersion, '0627', @transportationResponsibilityCode)
			,	EDI_XML.DE(@dictionaryVersion, '0128', @referenceNumberQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0127', @referenceNumber)
			for xml raw ('SEG-ETD'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_ETD('002040', 'ZZ', 'A', 'AE', 'AETCNumber')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_HL
end
go

create function EDI_XML.SEG_HL
(	@dictionaryVersion varchar(25)
,	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'HL')
			,	EDI_XML.DE(@dictionaryVersion, '0628', @idNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0734', @parentIDNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0735', @levelCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_HL('002002FORD', 1, null, 'S')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_INFO
end
go

create function EDI_XML.SEG_INFO
(	@dictionaryVersion varchar(25)
,	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
	/*	CE */
		(	select
				code = dsc.Code
			,	name = dsc.Description
			from
				FxEDI.EDI_DICT.DictionarySegmentCodes dsc
			where
				dsc.DictionaryVersion = @dictionaryVersion
				and dsc.Code = @segmentCode
			for xml raw ('SEG-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_INFO ('002002FORD', 'BSN')
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_IT1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_IT1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_IT1
end
go

create function EDI_XML.SEG_IT1
(	@dictionaryVersion varchar(25)
,	@assignedIdentification varchar(20)
,	@quantityInvoiced int
,	@unit char(2)
,	@unitPrice numeric(9,4)
,	@unitPriceBasis char(2)
,	@companyPartNumber varchar(40)
,	@packagingDrawing varchar(40)
,	@mutuallyDefinedIdentifier varchar(40)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'IT1')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @assignedIdentification)
			,	EDI_XML.DE(@dictionaryVersion, '0358', @quantityInvoiced)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @unit)
			,	EDI_XML.DE(@dictionaryVersion, '0212', @unitPrice)
			,	EDI_XML.DE(@dictionaryVersion, '0639', @unitPriceBasis)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'PN')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @companyPartNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'PK')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @packagingDrawing)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'ZZ')
			,	EDI_XML.DE(@dictionaryVersion, '0234', @mutuallyDefinedIdentifier)
			for xml raw ('SEG-IT1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_IT1('004010', 'M390', 36, 'EA', 10.42061, 'QT', '123210P05000', '1', 'N1')
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_LIN
end
go

create function EDI_XML.SEG_LIN
(	@dictionaryVersion varchar(25)
,	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'LIN')
			,	EDI_XML.DE(@dictionaryVersion, '0235', @productQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0234', @productNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_LIN('002002FORD', 'BP', 'FL1W 4C000 FB')

select
	*
from
	fxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'LIN'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0234'
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_MEA.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_MEA'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_MEA
end
go

create function EDI_XML.SEG_MEA
(	@dictionaryVersion varchar(25)
,	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'MEA')
			,	EDI_XML.DE(@dictionaryVersion, '0737', @measurementReference)
			,	EDI_XML.DE(@dictionaryVersion, '0738', @measurementQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0739', @measurementValue)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @measurementUnit)
			for xml raw ('SEG-MEA'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_MEA('002002FORD', 'PD', 'G', 5774, 'LB')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_N1
end
go

create function EDI_XML.SEG_N1
(	@dictionaryVersion varchar(25)
,	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N1')
			,	EDI_XML.DE(@dictionaryVersion, '0098', @entityIdentifierCode)
			,	EDI_XML.DE(@dictionaryVersion, '0093', null)
			,	EDI_XML.DE(@dictionaryVersion, '0066', @identificationQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0067', @identificationCode)
			for xml raw ('SEG-N1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_N1('002002FORD', 'ST', '92', 'TC05A')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_PRF
end
go

create function EDI_XML.SEG_PRF
(	@dictionaryVersion varchar(25)
,	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'PRF')
			,	EDI_XML.DE(@dictionaryVersion, '0324', @poNumber)
			for xml raw ('SEG-PRF'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_PRF('002002FORD', 'ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_REF
end
go

create function EDI_XML.SEG_REF
(	@dictionaryVersion varchar(25)
,	@refenceQualifier varchar(3)
,	@refenceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'REF')
			,	EDI_XML.DE(@dictionaryVersion, '0128', @refenceQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0127', @refenceNumber)
			for xml raw ('SEG-REF'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_REF('002002FORD', 'BM', '797120')

select
	EDI_XML.SEG_REF('002002FORD', 'PK', '75964')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_SN1
end
go

create function EDI_XML.SEG_SN1
(	@dictionaryVersion varchar(25)
,	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'SN1')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @identification)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @units)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @unitMeasure)
			,	case when @accum > 0 then EDI_XML.DE(@dictionaryVersion, '0646', @accum) end
			for xml raw ('SEG-SN1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_SN1('002002FORD', null, 500, 'EA', 17200)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0350', '0355')
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TD1
end
go

create function EDI_XML.SEG_TD1
(	@dictionaryVersion varchar(25)
,	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD1')
			,	EDI_XML.DE(@dictionaryVersion, '0103', @packageCode)
			,	EDI_XML.DE(@dictionaryVersion, '0080', @ladingQuantity)
			for xml raw ('SEG-TD1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_TD1('002002FORD', 'CTN90', 39)

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TD3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TD3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TD3
end
go

create function EDI_XML.SEG_TD3
(	@dictionaryVersion varchar(25)
,	@equipmentCode varchar(3)
,	@equipmentInitial varchar(12)
,	@equipmentNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD3')
			,	EDI_XML.DE(@dictionaryVersion, '0040', @equipmentCode)
			,	EDI_XML.DE(@dictionaryVersion, '0206', @equipmentInitial)
			,	EDI_XML.DE(@dictionaryVersion, '0207', @equipmentNumber)
			for xml raw ('SEG-TD3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_TD3('002002FORD', 'TL', 'LGSI', '386206')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TD5.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TD5'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TD5
end
go

create function EDI_XML.SEG_TD5
(	@dictionaryVersion varchar(25)
,	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD5')
			,	EDI_XML.DE(@dictionaryVersion, '0133', @routingSequenceCode)
			,	EDI_XML.DE(@dictionaryVersion, '0066', @identificaitonQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0067', @identificaitonCode)
			,	EDI_XML.DE(@dictionaryVersion, '0091', @transMethodCode)
			,	case
					when @locationQualifier is not null then EDI_XML.DE(@dictionaryVersion, '0309', @locationQualifier)
				end
			,	case
					when @locationQualifier is not null then EDI_XML.DE(@dictionaryVersion, '0310', @locationIdentifier)
				end
			for xml raw ('SEG-TD5'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_TD5('002002FORD', 'B', 2, 'RYDD', 'M', null, null)

select
	EDI_XML.SEG_TD5('002002FORD', 'B', 2, 'PSKL', 'C', 'PP', 'PC07A')

/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TDS.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TDS'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TDS
end
go

create function EDI_XML.SEG_TDS
(	@dictionaryVersion varchar(25)
,	@totalMonetaryValue numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TDS')
			,	EDI_XML.DE(@dictionaryVersion, '0610', @totalMonetaryValue)
			for xml raw ('SEG-TDS'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_TDS('002002FORD', 375.141)

/*
Create ScalarFunction.FxAztec.EDI_XML.TRN_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.TRN_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.TRN_INFO
end
go

create function EDI_XML.TRN_INFO
(	@dictionaryVersion varchar(25)
,	@transactionType varchar(25)
,	@tradingPartner varchar(50)
,	@iConnectID varchar(50)
,	@documentNumber varchar(50)
,	@completeFlag bit = 1
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set
		@xmlOutput =
			(	select
					name = dt.TransactionDescription
				,	trading_partner = @TradingPartner
				,	ICN = @iConnectID
				,	version = @DictionaryVersion
				,	type = @TransactionType
				,	doc_number = @DocumentNumber
				,	folder = case when @completeFlag = 0 then '3' else '4' end
				from
					FxEDI.EDI_DICT.DictionaryTransactions dt
				where
					dt.DictionaryVersion = @DictionaryVersion
					and dt.TransactionType = @TransactionType
				for xml raw ('TRN-INFO'), type
			)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.TRN_INFO('002040', '856', 'AP04A-K856C', '2233', '75979', 1)
/*
Create schema Schema.FxAztec.EDI_XML.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML') is null begin
	exec sys.sp_executesql N'create schema EDI_XML authorization dbo'
end
go


/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.SEG_ITA092.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.SEG_ITA092'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.SEG_ITA092
end
go

create function EDI_XML_Chrysler_ASN.SEG_ITA092
(	@chargeAmount numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('ITA')
			,	EDI_XML_V2040.DE('0248', 'C')
			,	EDI_XML_V2040.DE('0331', '06')
			,	EDI_XML_V2040.DE('0341', '092')
			,	EDI_XML_V2040.DE('0360', @chargeAmount)
			,	EDI_XML_V2040.DE('0352', 'CLAUSE')
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.SEG_ITA092(pi())
go


/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.SEG_LIN
end
go

create function EDI_XML_Chrysler_ASN.SEG_LIN
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
,	@engineeringChangeQualifier varchar(3)
,	@engineeringChangeNumber varchar(25)
,	@returnableContainerQualifier varchar(3)
,	@returnableContainerNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('LIN')
			,	EDI_XML_V2040.DE('0235', @productQualifier)
			,	EDI_XML_V2040.DE('0234', @productNumber)
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0235', @engineeringChangeQualifier) end
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0234', @engineeringChangeNumber) end
			,	EDI_XML_V2040.DE('0235', @returnableContainerQualifier)
			,	EDI_XML_V2040.DE('0234', @returnableContainerNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.SEG_LIN('BP', '53034136AB', 'EC', 'C', 'RC', 'EXP0363032')

select
	EDI_XML_Chrysler_ASN.SEG_LIN('BP', '53034136AB', 'EC', '', 'RC', 'EXP0363032')
go


/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.udf_Root
end
go

create function EDI_XML_Chrysler_ASN.udf_Root
(	@ShipperID int
,	@Purpose char(2)
,	@PartialComplete int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	declare
		@itemLoops int
	,	@totalQuantity int

	select
		@itemLoops = 2 * count(*) + count(case when al.PalletCount > 0 then 1 end * case when al.PalletType like '%~%' then 2 else 1 end)
	,	@totalQuantity = sum(al.QtyPacked + al.BoxCount + al.PalletCount * case when al.PalletType like '%~%' then 2 else 1 end)
	from
		EDI_XML_Chrysler_ASN.ASNLines(@ShipperID) al
	
	set
		@xmlOutput =
			(	select
					EDI_XML.TRN_INFO('002040', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
				,	EDI_XML_V2040.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
				,	EDI_XML_V2040.SEG_DTM('011', ah.ShipDateTime, ah.TimeZoneCode)
				,	(	select
				 			EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V2040.SEG_HL(1, null, 'S', 1)
						,	EDI_XML_V2040.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
						,	EDI_XML_V2040.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
						,	EDI_XML_V2040.SEG_TD1(ah.PackageType, ah.BOLQuantity)
						,	EDI_XML_V2040.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, ah.LocationQualifier, ah.PoolCode)
						,	EDI_XML_V2040.SEG_TD3('TL', ah.EquipInitial, ah.TruckNumber)
						,	EDI_XML_V2040.SEG_REF('MB', ah.BOLNumber)
						,	EDI_XML_V2040.SEG_REF('BM', ah.BOLNumber)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2040.SEG_N1('SU', 92, ah.SupplierCode)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2040.SEG_N1('SF', 92, ah.SupplierCode)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2040.SEG_N1('BT', 92, ah.ShipTo)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2040.SEG_N1('ST', 92, ah.ShipTo)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2040.SEG_N1('MA', 92, ah.ShipTo)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	case
								when ah.AETC > '' then
									EDI_XML_V2040.SEG_ETD('ZZ', ah.AETCResponsibility, 'AE', ah.AETC)
							end
				 		for xml raw ('LOOP-HL'), type
				 	)
				,	EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines(@ShipperID)
				,	EDI_XML_V2040.SEG_CTT(1 + @ItemLoops, @TotalQuantity)
				from
					EDI_XML_Chrysler_ASN.ASNHeaders ah
				where
					ah.ShipperID = @ShipperID
				for xml raw ('TRN-856'), type
			)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.udf_Root(76031, '00', 1)

select
	EDI_XML_Chrysler_ASN.udf_Root(75448, '00', 0)

/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines
end
go

create function EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines
(	@ShipperID int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml = ''
	
	declare
		@ASNLines table
	(	PackingSlip varchar(25)
	,	CustomerPart varchar(35)
	,	ECL varchar(25)
	,	BoxType varchar(25)
	,	BoxCount int
	,	PalletType varchar(25)
	,	PalletCount int
	,	QtyPacked int
	,	AccumShipped int
	,	PONumber varchar(20)
	,	DockCode varchar(10)
	,	ShipTo varchar(20)
	,	ACIndicator char(1)
	,	ACHandler char(2)
	,	ACClause char(3)
	,	ACCharge numeric(20,6)
	)

	insert
		@ASNLines
	(	PackingSlip
	,	CustomerPart
	,	ECL
	,	BoxType
	,	BoxCount
	,	PalletType
	,	PalletCount
	,	QtyPacked
	,	AccumShipped
	,	PONumber
	,	DockCode
	,	ShipTo
	,	ACIndicator
	,	ACHandler
	,	ACClause
	,	ACCharge
	)
	select
		al.PackingSlip
	,	al.CustomerPart
	,	al.ECL
	,	al.BoxType
	,	al.BoxCount
	,	al.PalletType
	,	al.PalletCount
	,	al.QtyPacked
	,	al.AccumShipped
	,	al.PONumber
	,	al.DockCode
	,	al.ShipTo
	,	al.ACIndicator
	,	al.ACHandler
	,	al.ACClause
	,	al.ACCharge
	from
		EDI_XML_Chrysler_ASN.ASNLines(@ShipperID) al
	
	declare
		orderLines cursor local for
	select
		al.PackingSlip
	,	al.CustomerPart
	,	al.ECL
	,	al.BoxType
	,	al.BoxCount
	,	al.PalletType
	,	al.PalletCount
	,	al.QtyPacked
	,	al.AccumShipped
	,	al.PONumber
	,	al.DockCode
	,	al.ShipTo
	,	al.ACIndicator
	,	al.ACHandler
	,	al.ACClause
	,	al.ACCharge
	from
		@ASNLines al

	open
		orderLines

	declare
		@hl int = 1

	while
		1 =	1 begin

		declare
			@packingSlip varchar(25)
		,	@customerPart varchar(35)
		,	@ecl varchar(25)
		,	@boxType varchar(25)
		,	@boxCount int
		,	@palletType varchar(25)
		,	@palletCount int
		,	@qtyPacked int
		,	@accumShipped int
		,	@poNumber varchar(20)
		,	@dockCode varchar(10)
		,	@shipTo varchar(20)
		,	@acIndicator char(1)
		,	@acHandler char(2)
		,	@acClause char(3)
		,	@acCharge numeric(20,6)

		fetch
			orderLines
		into
			@packingSlip
		,	@customerPart
		,	@ecl
		,	@boxType
		,	@boxCount
		,	@palletType
		,	@palletCount
		,	@qtyPacked
		,	@accumShipped
		,	@poNumber
		,	@dockCode
		,	@shipTo
		,	@acIndicator
		,	@acHandler
		,	@acClause
		,	@acCharge

		if	@@FETCH_STATUS != 0 begin
			break
		end

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
					,	EDI_XML_Chrysler_ASN.SEG_LIN('BP', @customerPart, 'EC', @ecl, 'RC', @boxType)
					,	EDI_XML_V2040.SEG_SN1(null, @qtyPacked, 'EA', @accumShipped)
					,	EDI_XML_V2040.SEG_PRF(@poNumber)
					,	EDI_XML_V2040.SEG_REF('BM', @ShipperID)
					,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
					,	case when @acClause = '092' and @acCharge > 0 then EDI_XML_Chrysler_ASN.SEG_ITA092(@acCharge) end
					for xml raw ('LOOP-HL'), type
				)
			)

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
					,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@boxType, '~', 1))
					,	EDI_XML_V2040.SEG_SN1(null, @boxCount, 'EA', @boxCount)
					,	EDI_XML_V2040.SEG_PRF(1)
					,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
					for xml raw ('LOOP-HL'), type
				)
			)

		if	@palletCount > 0 begin
			if	(	select
			  			count(*)
			  		from
			  			dbo.fn_SplitStringToRows(@palletType, '~')
			  	) > 1 begin

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@palletType, '~', 1))
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@palletType, '~', 2))
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)
			end
			else begin

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', @palletType)
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)

			end
		end
	end
	close
		orderLines
	deallocate
		orderLines
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines(76031)
return
go


/*
Create schema Schema.FxAztec.EDI_XML_Chrysler_ASN.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Chrysler_ASN') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Chrysler_ASN authorization dbo'
end
go

/*
select top 30
	*
from
	dbo.shipper s
where
	s.status = 'Z'
	and s.destination in
		(	select
				es.destination
			from
				dbo.edi_setups es
			where
				es.asn_overlay_group = 'CH1'
		)
order by
	s.date_shipped desc

select
	*
from
	fxEDI.EDI.EDIDocuments ed
where
	ed.DocNumber in ('76031', '75448')
*/

begin transaction
go

declare
	@shipper int = 76031
	--@shipper int = 75448

set ANSI_Padding on
--ASN Header

declare
	@TradingPartner	char(12),
	@ShipperID char(30),
	@ShipperID2 char(16),
	@PartialComplete char(1),
	@PurposeCode char(2),
	@ASNDate char(6),
	@ASNTime char(4),
	@ShippedDate char(6),
	@ShippedTime char(4),
	@GrossWeightLbs char(10),
	@NetWeightLbs char(10),
	@PackagingCode char(5),
	@PackCount char(4),
	@SCAC char(4),
	@TransMode char(2),
	@PPCode char(7),
	@EquipDesc char(2),
	@EquipInit char(4),
	@TrailerNumber char(10),
	@REFBMQual char(2),
	@REFPKQual char(2),
	@REFCNQual char(2),
	@REFBMValue char(16),
	@REFPKValue char(30),
	@REFCNValue char(30),
	@FOB char(2),
	@ProNumber char(16),
	@SealNumber char(8),
	@SupplierName char(78),
	@SupplierCode char(17),
	@ShipToName char(78),
	@ShipToID char(17),
	@TimeZone char(2),
	@AETCResponsibility char(1),
	@AETC char(8),
	@PoolCode char(7),
	@EquipInitial char(4)
	
	select
		@TradingPartner	= es.trading_partner_code ,
		@ShipperID =  s.id,
		@ShipperID2 =  s.id,
		@PartialComplete = '' ,
		@PurposeCode = '00',
		@ASNDate = convert(char, getdate(), 12) ,
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ShippedDate = convert(char, s.date_shipped, 12)  ,
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@TimeZone = [dbo].[udfGetDSTIndication](date_shipped),
		@GrossWeightLbs = convert(char,convert(int,s.gross_weight)),
		@NetWeightLbs = convert(char,convert(int,s.net_weight)),
		@PackagingCode = 'CTN25' ,
		@PackCount = s.staged_objs,
		@SCAC = s.ship_via,
		@TransMode = s.trans_mode ,
		@TrailerNumber = s.truck_number,
		@REFBMQual = 'BM' ,
		@REFPKQual = 'PK',
		@REFCNQual = 'CN',
		@REFBMValue = coalesce(bill_of_lading_number, id),
		@REFPKValue = id,
		@REFCNValue = pro_number,
		@FOB = case when freight_type =  'Collect' then 'CC' when freight_type in  ('Consignee Billing', 'Third Party Billing') then 'TP' when freight_type  in ('Prepaid-Billed', 'PREPAY AND ADD') then 'PA' when freight_type = 'Prepaid' then 'PP' else 'CC' end ,
		@SupplierName = 'TSM Corp' ,
		@SupplierCode =  es.supplier_code ,
		@ShipToName =  d.name,
		@ShipToID = COALESCE(nullif(es.parent_destination,''),es.destination),
		@AETCResponsibility = case when upper(left(aetc_number,2)) = 'CE' then 'A' when upper(left(aetc_number,2)) = 'SR' then 'S' when upper(left(aetc_number,2)) = 'CR' then 'Z' else '' end,
		@AETC =coalesce(s.aetc_number,''),
		@PoolCode = case when s.trans_mode in ('A', 'AC','AE','E','U') then '' else coalesce(pool_code,'') end,
		@EquipDesc = coalesce( es.equipment_description, 'TL' ),
		@EquipInitial = coalesce( bol.equipment_initial, s.ship_via ),
		@SealNumber = coalesce(s.seal_number,''),
		@Pronumber = coalesce(s.pro_number,'')
		
	from
		Shipper s
	join
		dbo.edi_setups es on s.destination = es.destination
	join
		dbo.destination d on es.destination = d.destination
	left join
		dbo.bill_of_lading bol on s.bill_of_lading_number = bol_number
	where
		s.id = @shipper
	

Create	table	#ASNFlatFileHeader (
				LineId	int identity (1,1),
				LineData char(80))

INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('//STX12//856'+  @TradingPartner + @ShipperID+ @PartialComplete )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('01'+  @PurposeCode + @ShipperID2 + @ASNDate + @ASNTime + @ShippedDate + @ShippedTime+@TimeZone+@GrossWeightLbs+@NetWeightLbs )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('02' + @PackagingCode + @PackCount )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('03' + @SCAC  + @TransMode + @PoolCode + space(35)+ @EquipDesc + @EquipInitial + @TrailerNumber)
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('04' + @REFBMValue + @ProNumber  + @REFBMValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' + @SealNumber )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @SupplierCode + @SupplierCode + @ShipToID + @ShipToID + space(8) + @AETCResponsibility)
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('08' + @AETC )

 --ASN Detail

declare	@ShipperDetail table (
	Part varchar(25),
	PackingSlip varchar(25),
	ShipperID int,
	CustomerPart varchar(35),
	CustomerPO varchar(35),
	ContainerTypeIndicator varchar(35),
	ContainerTypeCount int,
	PalletPackageType varchar(35),
	PalletPackageTypeCount int,
	SDQty int,
	SDAccum int,
	EngLevel varchar(25),
	OHDockCode varchar(25),
	BOL varchar(10),
	ASNOverlayGroup varchar(10),
	Destination varchar(15),  
	Clause092C varchar(2),
	Clause092H varchar(2),
	Clause092 varchar(3),
	Clause092Charge numeric(10,2) primary key (Part, PackingSlip)
	)
insert @ShipperDetail
			( Part ,
			PackingSlip ,
			ShipperID,
			CustomerPart ,
			CustomerPO ,
			ContainerTypeIndicator ,
			ContainerTypeCount,
			PalletPackageType,
			PalletPackageTypeCount,
			SDQty ,
			SDAccum ,
			EngLevel ,
			OHDockCode ,
			BOL ,
			ASNOverlayGroup,
			Destination,
			Clause092C ,
			Clause092H ,
			Clause092 ,
			Clause092Charge
          
        )	
select
	fn_SI.Part,
	fn_SI.PackingSlip,
	shipper,
	bo.CustomerPart,
	bo.CustomerPO,
	fn_SI.PackageType,
	fn_SI.Boxes,
	fn_SI.PalletPackageType,
	fn_SI.Pallets,
	fn_SI.QtyPacked,
	bo.AccumShipped,
	coalesce(bo.ECL,''),
	coalesce(bo.DockCode,''),
	fn_SI.ShipperID,
	es.asn_overlay_group,
	bo.EDIShipToCode,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then 'C' else '' end,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then '06' else '' end,
	case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then '092' else '' end,
	((case when bo.Returnable = 'Y' and fn_SI.PackingSlip like '%E%' and bo.Clause092UnitCost>0  then bo.Clause092UnitCost else 0.00 end)*fn_SI.QtyPacked)
	
from
	chryslerEDI.fn_ShipperInventory(@shipper) fn_SI
join
	dbo.shipper_detail sd on fn_SI.Part = sd.part_original and sd.shipper = @shipper
join
	chryslerEDI.BlanketOrders bo on sd.order_no = bo.BlanketOrderNo
join
	shipper s on sd.shipper = s.id
join
	edi_setups es on s.destination = es.destination

--Select		*	from		@shipperDetail order by packingslip
	
--Delcare Variables for ASN Details		
declare	
	@CustomerPartBP char(2),
	@CustomerPartRC char(2),
	@CustomerPart char(30) ,
	@CustomerECL char(3),
	@ContainerType char(30),
	@Part varchar(25),
	@QtyPacked char(12),
	@UM char(2),
	@AccumShipped char(11),
	@CustomerPO char(13),
	@BOL char(16),
	@PackSlip char(16),
	@Destination char(17), 
	@ASNOverlayGroup varchar(10),
	@DockCode	char(8),
	@ACIndicator char(1),
	@ACHandling char(2),
	@ACClause char(4),
	@ACCharge char(11),
	@ContainerCount char(12),
	@PackageType char(30)
	
Create	table	#FlatFileLines (
				LineId	int identity(200,1),
				LineData char(80)
				 )

declare
	PartPOLine cursor local for
select
			'BP',
			'RC',
			ASNOverlayGroup,
			Part ,
	        PackingSlip ,
	        CustomerPart ,
	        CustomerPO ,
	        ContainerTypeIndicator ,
	        SDQty ,
	        'EA',
	        SDAccum ,
	        EngLevel ,
	        OHDockCode ,
	        BOL ,
	        Destination ,
	        Clause092C ,
	        Clause092H ,
	        Clause092 ,
	        case when isnumeric(Clause092Charge) = 1 then convert(varchar,Clause092Charge) else '' end
From
	@ShipperDetail SD
	order by
		PackingSlip,
		CustomerPart

open
	PartPOLine
while
	1 = 1 begin
	
	fetch
		PartPOLine
	into
		@CustomerPartBP ,
		@CustomerPartRC,
		@ASNOverlayGroup,
		@Part ,
		@PackSlip,
		@CustomerPart ,
		@CustomerPO,
		@ContainerType,
		@QtyPacked,
		@UM,
		@AccumShipped,
		@CustomerECL ,
		@DockCode,		
		@BOL,
		@Destination, 		
		@ACIndicator,
		@ACHandling ,
		@ACClause,
		@ACCharge 
			
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	print @ASNOverlayGroup
	
	INSERT	#FlatFileLines (LineData)
		SELECT	('09'+  @CustomerPartBP + @CustomerPart + @CustomerECL + @ContainerType + @QtyPacked  )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('10'+  @UM + @AccumShipped + @CustomerPO + @BOL + @PackSlip   )
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('12'+  @Destination + @Destination + @DockCode    )
		
		if @ASNOverlayGroup = 'CHT'
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('13'+ space(78)     )
		
		Else
		INSERT	#FlatFileLines (LineData)
		SELECT	('13'+  @ACIndicator + @ACHandling + @ACClause + case when @ACCharge = '0.00' then space(11) else @ACCharge end     )
	
			
				declare Pack cursor local for
				select
				ContainerTypeIndicator,
				sum(ContainerTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip = rtrim(@PackSlip)
				group by
					ContainerTypeIndicator
				union all
				Select
				PalletPackageType,
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType not like '%~%' and 
					PalletPackageType not like '%PALLET%'
				group by
					PalletPackageType
				union all
				Select
				substring(PalletPackageType,1, patindex('%[~]%', PalletPackageType)-1),
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType  like '%~%'
				group by
					substring(PalletPackageType,1, patindex('%[~]%', PalletPackageType)-1)
				union all
				Select
				substring(PalletPackageType, patindex('%[~]%', PalletPackageType)+1, 25),
				sum(PalletPackageTypeCount)
				From
					@ShipperDetail
				where					
					--part = @Part and
					ShipperID = @shipper and
					PackingSlip =  rtrim(@PackSlip) and
					PalletPackageTypeCount >0 and
					PalletPackageType  like '%~%'	
				group by
					substring(PalletPackageType, patindex('%[~]%', PalletPackageType)+1, 25)			
									
					open	Pack

					while	1 = 1 
					begin
					fetch	pack	into
					@PackageType,
					@ContainerCount					
					
					if	@@FETCH_STATUS != 0 begin
					break
					end
					
				
					if rtrim(@CustomerPart) = (select max(customerpart) from @ShipperDetail where PackingSlip = rtrim(@PackSlip))
					Begin
					INSERT	#FlatFileLines (LineData)
					SELECT	('09'+  @CustomerPartRC + @PackageType + space(3) + space(30) + @ContainerCount  )
					
					INSERT	#FlatFileLines (LineData)
					SELECT	('10'+  @UM + @ContainerCount   )
					end
	
					end
				close pack
				deallocate pack
				
		
						
end
close
	PartPOLine	
 
deallocate
	PartPOLine
	


create	table
	#ASNResultSet (FFdata  char(80), LineID int)

insert #ASNResultSet
        ( FFdata, LineID )

select
	Convert(char(80), LineData), LineID
from	
	#ASNFlatFileHeader
insert
	#ASNResultSet (FFdata, LineID)
select
	Convert(char(77), LineData) + Convert(char(3), LineID),LineID
from	
	#FlatFileLines
	
select	FFdata
from		#ASNResultSet
order by LineID ASC


	      
set ANSI_Padding OFF	
go

rollback
go

set ANSI_Padding on

select
	*
from
	fxEDI.EDI.EDIDocuments ed
where
	ed.DocNumber = '76031'update
	es
set	es.IConnectID = '136'
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'CH1%'

/*
Create function TableFunction.FxAztec.EDI_XML_Chrysler_ASN.ASNLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.ASNLines'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.ASNLines
end
go

create function EDI_XML_Chrysler_ASN.ASNLines
(	@shipperID int
)
returns @ASNLines table
(	PackingSlip varchar(25)
,	CustomerPart varchar(35)
,	ECL varchar(25)
,	BoxType varchar(25)
,	BoxCount int
,	PalletType varchar(25)
,	PalletCount int
,	QtyPacked int
,	AccumShipped int
,	PONumber varchar(20)
,	DockCode varchar(10)
,	ShipTo varchar(20)
,	ACIndicator char(1)
,	ACHandler char(2)
,	ACClause char(3)
,	ACCharge numeric(20,6)
)
as
begin
--- <Body>
	insert
		@ASNLines
	select
		PackingSlip = si.PackingSlip
	,	CustomrPart = bo.CustomerPart
	,	ECL = right(rtrim(bo.CustomerPart), 2)
	,	BoxType = si.PackageType
	,	BoxCount = si.Boxes
	,	PalletType = si.PalletPackageType
	,	PalletCount = si.Pallets
	,	QtyPacked = convert(int, si.QtyPacked)
	,	AccumShipped = convert(int, bo.AccumShipped)
	,	PONumber = bo.CustomerPO
	,	DockCode = bo.DockCode
	,	ShipTo = bo.EDIShipToCode
	,	ACIndicator = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then 'C'
		end
	,	ACHandler = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then '06'
		end
	,	ACClause = case when bo.Returnable = 'Y'
				  and si.PackingSlip like '%E%'
				  and bo.Clause092UnitCost > 0 then '092'
		end
	,	ACCharge = case when bo.Returnable = 'Y'
					and si.PackingSlip like '%E%'
					and bo.Clause092UnitCost > 0 then bo.Clause092UnitCost
		end * si.QtyPacked
	from
		ChryslerEDI.fn_ShipperInventory(@shipperID) si
		join dbo.shipper_detail sd
			on si.Part = sd.part_original
			   and sd.shipper = @shipperID
		join ChryslerEDI.BlanketOrders bo
			on sd.order_no = bo.BlanketOrderNo
		join shipper s
			on sd.shipper = s.id
		join edi_setups es
			on s.destination = es.destination
--- </Body>

---	<Return>
	return
end
go

declare
	@shipperID int = 75448

select
	*
from
	EDI_XML_Chrysler_ASN.ASNLines (@shipperID)

/*
Create View.FxAztec.EDI_XML_Chrysler_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Chrysler_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Chrysler_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Chrysler_ASN.ASNHeaders
end
go

create view EDI_XML_Chrysler_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = es.trading_partner_code
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, s.date_shipped)
,	ShipTime = convert(time, s.date_shipped)
,	TimeZoneCode = 'ED'
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType = 'CTN25'
,	BOLQuantity = s.staged_objs
,	Carrier = s.ship_via
,	BOLCarrier = coalesce(s.bol_carrier, s.ship_via)
,	TransMode = s.trans_mode
,	EquipInitial = coalesce(bol.equipment_initial, s.ship_via)
,	LocationQualifier =
		case
			when s.trans_mode = 'E' then null
			when s.trans_mode in ('A', 'AE') then 'OR'
			when es.pool_code != '' then 'PP'
		end
,	PoolCode =
		case
			when s.trans_mode not in ('A', 'AC', 'AE', 'E', 'U') then es.pool_code
		end
,	EquipmentType = es.equipment_description
,	TruckNumber = s.truck_number
,	PRONumber = s.pro_number
,	BOLNumber =
		case
			when es.parent_destination = 'milkrun' then substring(es.material_issuer, datepart(dw, s.date_shipped)*2-1, 2) + right('0'+convert(varchar, datepart(month, s.date_shipped)),2) + right('0'+convert(varchar, datepart(day, s.date_shipped)),2)
			else convert(varchar, s.bill_of_lading_number)
		end
,	ShipTo = coalesce(nullif(es.parent_destination, ''), es.destination)
,	SupplierCode = es.supplier_code
,	AETCResponsibility = case
		when left(s.aetc_number, 2) = 'CE' then 'A'
		when left(s.aetc_number, 2) = 'SR' then 'S'
		when left(s.aetc_number, 2) = 'CR' then 'Z'
	end
,	AETC = s.aetc_number
--,	*
from
	dbo.shipper s
	left join dbo.bill_of_lading bol
		on bol.bol_number = s.bill_of_lading_number
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'CH%'
	join dbo.destination d
		on d.destination = s.destination
where
	coalesce(s.type, 'N') in ('N', 'M')
	--and s.id = 75964
go

select
	*
from
	EDI_XML_Chrysler_ASN.ASNHeaders ah
where
	ah.ShipperID in (76031)
	--and
	--	(	select
	--			count(*)
	--		from
	--			dbo.shipper_detail sd
	--		where
	--			sd.shipper = ah.ShipperID
	--	) > 1

select
	*
from
	EDI_XML_Chrysler_ASN.ASNHeaders ah
where
	ah.AETC > ''
/*
Create ScalarFunction.FxAztec.EDI_XML_Ford_ASN.SEG_REF_ObjectSerials.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.SEG_REF_ObjectSerials'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.SEG_REF_ObjectSerials
end
go

create function EDI_XML_Ford_ASN.SEG_REF_ObjectSerials
(	@ShipperID int
,	@CustomerPart varchar(30)
,	@BoxType varchar(20)
,	@BoxQty int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml = ''
	
	select
		@xmlOutput = convert(xml, convert(varchar(max), @xmlOutput) + convert(varchar(max), EDI_XML_V2002FORD.SEG_REF('LS', 'S' + convert(varchar, ao.BoxSerial))))
	from
		EDI_XML_Ford_ASN.ASNObjects ao
	where
		ao.ShipperID = @ShipperID
		and ao.CustomerPart = @CustomerPart
		and coalesce(ao.BoxType, '!') = coalesce(@BoxType, '!')
		and ao.BoxQty = @BoxQty
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Ford_ASN.SEG_REF_ObjectSerials(75964, '7C34 5598 HD', null, 100)
return
go

select
	ao.BoxSerial
from
	EDI_XML_Ford_ASN.ASNObjects ao
where
	ao.ShipperID = 75964
	and ao.CustomerPart = '7C34 5598 HD'
/*
Create ScalarFunction.FxAztec.EDI_XML_Ford_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.udf_Root
end
go

create function EDI_XML_Ford_ASN.udf_Root
(	@ShipperID int
,	@Purpose char(2)
,	@PartialComplete int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml
	
	declare
		@asnLines table
	(	ShipperID int
	,	CustomerPart varchar(30)
	,	QtyPacked int
	,	UnitPacked char(2)
	,	AccumQty int
	,	CustomerPO varchar(25)
	,	GrossWeight int
	,	NetWeight int
	,	BoxType varchar(20)
	,	BoxQty int
	,	BoxCount int
	,	RowNumber int
	)

	insert
		@asnLines
	select
		*
	from
		EDI_XML_Ford_ASN.ASNLines(@ShipperID)
	order by
		ASNLines.RowNumber

	declare
		@ItemLoops int

	set	@ItemLoops =
		(	select
				max(al.RowNumber)
			from
				@asnLines al
		)

	declare
		@asnReturnables table
	(	ReturnableCode varchar(20)
	,	ReturnableCount int
	,	RowNumber int
	)

	insert
		@asnReturnables
	select
		*
	from
		EDI_XML_FORD_ASN.ASNReturnables(@ShipperID) ar
	order by
		ar.RowNumber

	declare
		@ReturnableLoops int

	set	@ReturnableLoops =
		(	select
				max(ar.RowNumber)
			from
				@asnReturnables ar
		)

	declare
		@TotalQuantity int

	set	@TotalQuantity =
		(	select
				sum(al.QtyPacked)
			from
				@asnLines al
		) +
		coalesce
		(	(	select
					sum(ar.ReturnableCount)
				from
					@asnReturnables ar
			)
		,	0
		)

	set
		@xmlOutput =
			(	select
					EDI_XML.TRN_INFO('002002FORD', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
				,	EDI_XML_V2002FORD.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
				,	EDI_XML_V2002FORD.SEG_DTM('011', ah.ShipDateTime)
				,	(	select
				 			EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V2002FORD.SEG_HL(1, null, 'S')
						,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
						,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
						,	EDI_XML_V2002FORD.SEG_TD1(ah.PackageType, ah.BOLQuantity)
						,	EDI_XML_V2002FORD.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, ah.LocationQualifier, ah.PoolCode)
						,	EDI_XML_V2002FORD.SEG_TD3('TL', ah.BOLCarrier, ah.TruckNumber)
						,	case
								when ah.PRONumber > '' then EDI_XML_V2002FORD.SEG_REF('CN', ah.PRONumber)
							end
						,	EDI_XML_V2002FORD.SEG_REF('BM', ah.BOLNumber)
						,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2002FORD.SEG_N1('ST', 92, ah.ShipTo)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2002FORD.SEG_N1('SF', 92, ah.SupplierCode)
						 		for xml raw ('LOOP-N1'), type
						 	)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V2002FORD.SEG_N1('SU', 92, ah.SupplierCode)
						 		for xml raw ('LOOP-N1'), type
						 	)
				 		for xml raw ('LOOP-HL'), type
				 	)
				,	(	select
				 			EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V2002FORD.SEG_HL(1+al.RowNumber, 1, 'I')
						,	EDI_XML_V2002FORD.SEG_LIN('BP', al.CustomerPart)
						,	EDI_XML_V2002FORD.SEG_SN1(null, al.QtyPacked, 'EA', al.AccumQty)
						,	case when al.CustomerPO > '' then EDI_XML_V2002FORD.SEG_PRF(al.CustomerPO) end
						,	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', al.GrossWeight, 'LB')
						,	EDI_XML_V2002FORD.SEG_MEA('PD', 'N', al.NetWeight, 'LB')
						,	EDI_XML_V2002FORD.SEG_REF('PK', ah.ShipperID)
						,	(	select
									EDI_XML.LOOP_INFO('CLD')
								,	EDI_XML_V2002FORD.SEG_CLD(al.BoxCount, al.BoxQty, al.BoxType)
								,	EDI_XML_Ford_ASN.SEG_REF_ObjectSerials(@ShipperID, al.CustomerPart, al.BoxType, al.BoxQty)
								for xml raw ('LOOP-CLD'), type
						 	)
						from
							@asnLines al
						order by
							al.RowNumber
				 		for xml raw ('LOOP-HL'), type
				 	)
				,	(	select
				 			EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V2002FORD.SEG_HL(1+@ItemLoops+ar.RowNumber, 1, 'I')
						,	EDI_XML_V2002FORD.SEG_LIN('RC', ar.ReturnableCode)
						,	EDI_XML_V2002FORD.SEG_SN1(null, ar.ReturnableCount, 'EA', null)
						from
							@asnReturnables ar
						order by
							ar.RowNumber
				 		for xml raw ('LOOP-HL'), type
				 	)
				,	EDI_XML_V2002FORD.SEG_CTT(1 + @ItemLoops + @ReturnableLoops, @TotalQuantity)
				from
					EDI_XML_Ford_ASN.ASNHeaders ah
				where
					ah.ShipperID = @ShipperID
				for xml raw ('TRN-856'), type
			)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Ford_ASN.udf_Root(75964, '00', 0)

select
	*
from
	EDI_XML_Ford_ASN.ASNHeaders ah
where
	ah.ShipperID = 75964

select
	*
from
	EDI_XML_Ford_ASN.ASNLines(75964) al

/*
Create schema Schema.FxAztec.EDI_XML_Ford_ASN.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Ford_ASN') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Ford_ASN authorization dbo'
end
go

use FxAztec
go

update
	es
set	es.IConnectID = '381'
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'FD%'

/*
Create function TableFunction.FxAztec.EDI_XML_Ford_ASN.ASNLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNLines'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.ASNLines
end
go

create function EDI_XML_Ford_ASN.ASNLines
(	@shipperID int
)
returns @ASNLines table
(	ShipperID int
,	CustomerPart varchar(30)
,	QtyPacked int
,	UnitPacked char(2)
,	AccumQty int
,	CustomerPO varchar(25)
,	GrossWeight int
,	NetWeight int
,	BoxType varchar(20)
,	BoxQty int
,	BoxCount int
,	RowNumber int
)
as
begin
--- <Body>
	declare
		@at table
	(	Part varchar(25)
	,	BoxType varchar(20)
	,	BoxQty int
	,	BoxCount int
	)

	insert
		@at
	(	Part
	,	BoxType
	,	BoxQty
	,	BoxCount
	)
	select
		Part = at.part
	,	BoxType = coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	,	BoxQty = convert(int, round(at.std_quantity,0))
	,	BoxCount = count(*)
	from
		dbo.audit_trail at
		join dbo.package_materials pm
			on pm.code = at.package_type
	where
		at.shipper = convert(varchar, @shipperID)
		and at.type = 'S'
	group by
		at.part
	,	coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	,	at.std_quantity

	insert
		@ASNLines
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	BoxType
	,	BoxQty
	,	BoxCount
	,	RowNumber
	)
	select
		ShipperID = s.id
	,	CustomerPart = sd.customer_part
	,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
	,	UnitPacked = sd.alternative_unit
	,	AccumQty =
			case
				when es.prev_cum_in_asn = 'Y'
					then convert(int, round(sd.accum_shipped - sd.alternative_qty, 0))
				else convert(int, round(sd.accum_shipped, 0))
			end
	,	CustomerPO = sd.customer_po
	,	GrossWeight = convert(int, round(sd.gross_weight, 0))
	,	NetWeight = convert(int, round(sd.net_weight, 0))
	,	BoxType = at.BoxType
	,	BoxQty = at.BoxQty
	,	BoxCount = at.BoxCount
	,	RowNumber = row_number() over (partition by s.id order by sd.customer_part, at.BoxCount)
	--,	*
	from
		dbo.shipper s
		join dbo.edi_setups es
			on s.destination = es.destination
			and es.asn_overlay_group like 'FD%'
		join dbo.destination d
			on d.destination = s.destination
		join dbo.shipper_detail sd
			join dbo.order_header oh
				on oh.order_no = sd.order_no
				and oh.blanket_part = sd.part
			on sd.shipper = s.id
		join @at at
			on at.Part = sd.part
	where
		coalesce(s.type, 'N') in ('N', 'M')
		and s.id = @shipperID
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	EDI_XML_Ford_ASN.ASNLines(75964)
/*
Create function TableFunction.FxAztec.EDI_XML_FORD_ASN.ASNReturnables.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_FORD_ASN.ASNReturnables'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_FORD_ASN.ASNReturnables
end
go

create function EDI_XML_FORD_ASN.ASNReturnables
(	@ShipperID int
)
returns @Returnables table
(	ReturnableCode varchar(20)
,	ReturnableCount int
,	RowNumber int
)
as
begin
--- <Body>
	insert
		@Returnables
	(	ReturnableCode
	,	ReturnableCount
	,	RowNumber
	)
	select
		returnables.ReturnableCode
	,	returnables.ReturnableCount
	,	RowNumber = row_number() over (order by returnables.ReturnableCode)
	from
		(	select
				ReturnableCode = at.package_type
			,	ReturnableCount = count(at.package_type)
			from
				dbo.audit_trail at
				join dbo.package_materials pm
					on pm.code = at.package_type
					and pm.returnable = 'Y'
			where
				at.shipper = convert(varchar, @ShipperID)
				and at.part != '3366'
				and at.package_type not like '%PB12L12%'
			group by
				at.package_type
			union
			select
				' ' + bom.part + ' '
			,	ceiling(shipper_detail.qty_packed * bom.quantity)
			from
				shipper_detail
				join dbo.bill_of_material bom
					on bom.parent_part = shipper_detail.part_original
			where
				shipper = @ShipperID
				and part_original = '3366'
				and bom.part = 'PB12L12'
		) returnables
	order by
		returnables.ReturnableCode
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	EDI_XML_FORD_ASN.ASNReturnables(75964)

/*
Create View.FxAztec.EDI_XML_Ford_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Ford_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Ford_ASN.ASNHeaders
end
go

create view EDI_XML_Ford_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = es.trading_partner_code
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, s.date_shipped)
,	ShipTime = convert(time, s.date_shipped)
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType =
		case
			when s.staged_pallets > 0 then 'PLT90'
			else 'CTN90'
		end
,	BOLQuantity =
		case
			when s.staged_pallets > 0 then s.staged_pallets
			else s.staged_objs
		end
,	Carrier = s.ship_via
,	BOLCarrier = coalesce(s.bol_carrier, s.ship_via)
,	TransMode = s.trans_mode
,	LocationQualifier =
		case
			when s.trans_mode = 'E' then null
			when s.trans_mode in ('A', 'AE') then 'OR'
			when es.pool_code != '' then 'PP'
		end
,	PoolCode =
		case
			when s.trans_mode = 'E' then null
			when s.trans_mode in ('A', 'AE') then 'DTW'
			else es.pool_code
		end
,	EquipmentType = es.equipment_description
,	TruckNumber = s.truck_number
,	PRONumber = s.pro_number
,	BOLNumber =
		case
			when es.parent_destination = 'milkrun' then substring(es.material_issuer, datepart(dw, s.date_shipped)*2-1, 2) + right('0'+convert(varchar, datepart(month, s.date_shipped)),2) + right('0'+convert(varchar, datepart(day, s.date_shipped)),2)
			else convert(varchar, s.bill_of_lading_number)
		end
,	ShipTo = left(s.destination, 5)
,	SupplierCode = es.supplier_code
--,	*
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'FD%'
	join dbo.destination d
		on d.destination = s.destination
where
	coalesce(s.type, 'N') in ('N', 'M')
	--and s.id = 75964
go

select
	*
from
	EDI_XML_Ford_ASN.ASNHeaders ah
where
	ah.ShipperID in (75979, 75964, 75945, 75990)
	and
		(	select
				count(*)
			from
				dbo.shipper_detail sd
			where
				sd.shipper = ah.ShipperID
		) > 1

/*
Create View.FxAztec.EDI_XML_Ford_ASN.ASNObjects.sql
*/

use FxAztec
go

--drop table EDI_XML_Ford_ASN.ASNObjects
if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNObjects'), 'IsView') = 1 begin
	drop view EDI_XML_Ford_ASN.ASNObjects
end
go

create view EDI_XML_Ford_ASN.ASNObjects
as
select
	ShipperID = s.id
,	CustomerPart = sd.customer_part
,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
,	BoxQty =  convert(int, round(at.std_quantity, 0))
,	BoxType = coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
,	BoxSerial = at.serial
--,	*
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'FD%'
	join dbo.destination d
		on d.destination = s.destination
	join dbo.shipper_detail sd
		join dbo.order_header oh
			on oh.order_no = sd.order_no
			and oh.blanket_part = sd.part
		on sd.shipper = s.id
	join dbo.audit_trail at
		join dbo.package_materials pm on pm.code = at.package_type
		on at.type = 'S'
		and at.part = sd.part_original
		and at.shipper = convert(varchar, s.id)
where
	coalesce(s.type, 'N') in ('N', 'M')
	--and s.id = 75964
go

select
	*
from
	EDI_XML_Ford_ASN.ASNObjects ao
where
	ao.ShipperID in (75979, 75964, 75945, 75990)
	and
		(	select
				count(*)
			from
				dbo.shipper_detail sd
			where
				sd.shipper = ao.ShipperID
		) > 1
order by
	ao.CustomerPart
,	ao.BoxSerial
go

use FxAztec
go

begin transaction
go

set ANSI_Padding on

declare
	@shipper int =
	(	select top 1
			s.id
		from
			dbo.shipper s
		where
			s.destination = 'CH'
			--and
			--	(	select
			--			count(*)
			--		from
			--			dbo.shipper_detail sd
			--		where
			--			sd.shipper = s.id
			--	) > 1
			and s.status = 'Z'
		order by
			s.date_shipped desc
	)

select
	*
from
	EDI.EDIdocuments ei
where
	ei.DocNumber = convert(varchar, @shipper)

select
	*
from
	dbo.shipper s
where
	s.id = @shipper

--[dbo].[MazdaASN] 67110

set ANSI_Padding on
--ASN Header

declare
	@TradingPartner	char(12),
	@ShipperID char(30),
	@ShipperID2 char(6),
	@PartialComplete char(1),
	@PurposeCode char(2),
	@ASNDate char(6),
	@ASNTime char(4),
	@ShippedDate char(6),
	@ShippedTime char(4),
	@EstimatedArrivalDate char(6),
	@EstimatedArrivalTime char(4),
	@GrossWeightLbs char(12),
	@GrossWeightQualifier char(3),
	@NetWeightLbs char(10),
	@WeightUM char(2),
	@PackagingCode char(5),
	@PackCount char(8),
	@SCAC char(4),
	@TransMode char(2),
	@PPCode char(7),
	@EquipDesc char(2),
	@EquipInit char(4),
	@TrailerNumber char(7),
	@REFBMQual char(2),
	@REFPKQual char(2),
	@REFCNQual char(2),
	@REFBMValue char(30),
	@REFPKValue char(30),
	@REFCNValue char(30),
	@FOB char(2),
	@ProNumber char(16),
	@SealNumber char(8),
	@SupplierName char(78),
	@SupplierCode char(5),
	@ShipToName char(78),
	@ShipToID char(5),
	@TimeZone char(2),
	@AETCResponsibility char(1),
	@AETC char(8),
	@PoolCode char(7),
	@EquipInitial char(4)
	
	select
		@TradingPartner	= es.trading_partner_code ,
		@ShipperID =  s.id,
		@ShipperID2 =  right((replicate('0', 6) +convert(varchar(20), s.id)),6),
		@PartialComplete = '' ,
		@PurposeCode = '00',
		@ASNDate = convert(char, getdate(), 12) ,
		@ASNTime = left(replace(convert(char, getdate(), 108), ':', ''),4),
		@ShippedDate = convert(char, s.date_shipped, 12)  ,
		@ShippedTime =  left(replace(convert(char, date_shipped, 108), ':', ''),4),
		@EstimatedArrivalDate = convert(char, dateadd(dd,1,s.date_shipped), 12)  ,
		@EstimatedArrivalTime =  left(replace(convert(char, dateadd(dd,1,date_shipped), 108), ':', ''),4),
		--@TimeZone = [dbo].[udfGetDSTIndication](date_shipped),
		@GrossWeightLbs = convert(char,convert(int,s.gross_weight)),
		@GrossWeightQualifier = 'G',
		@NetWeightLbs = convert(char,convert(int,s.net_weight)),
		@WeightUM = 'LB',
		@PackagingCode = 'CTN25' ,
		@PackCount = s.staged_objs,
		@SCAC = s.ship_via,
		@TransMode = s.trans_mode ,
		@TrailerNumber = s.truck_number,
		@REFBMQual = 'BM' ,
		@REFPKQual = 'PK',
		@REFCNQual = 'CN',
		@REFBMValue = coalesce(bill_of_lading_number, id),
		@REFPKValue = id,
		@REFCNValue = pro_number,
		@FOB = case when freight_type =  'Collect' then 'CC' when freight_type in  ('Consignee Billing', 'Third Party Billing') then 'TP' when freight_type  in ('Prepaid-Billed', 'PREPAY AND ADD') then 'PA' when freight_type = 'Prepaid' then 'PP' else 'CC' end ,
		@SupplierName = 'Aztec Manufacturing' ,
		@SupplierCode =  es.supplier_code ,
		@ShipToName =  d.name,
		@ShipToID = COALESCE(nullif(es.parent_destination,''),es.destination),
		@AETCResponsibility = case when upper(left(aetc_number,2)) = 'CE' then 'A' when upper(left(aetc_number,2)) = 'SR' then 'S' when upper(left(aetc_number,2)) = 'CR' then 'Z' else '' end,
		@AETC =coalesce(s.aetc_number,''),
		@PoolCode = case when s.trans_mode in ('A', 'AC','AE','E','U') then '' else coalesce(pool_code,'') end,
		@EquipDesc = coalesce( es.equipment_description, 'TL' ),
		@EquipInitial = coalesce( bol.equipment_initial, s.ship_via ),
		@SealNumber = coalesce(s.seal_number,''),
		@Pronumber = coalesce(s.pro_number,'')
		
	from
		Shipper s
	join
		dbo.edi_setups es on s.destination = es.destination
	join
		dbo.destination d on es.destination = d.destination
	left join
		dbo.bill_of_lading bol on s.bill_of_lading_number = bol_number
	where
		s.id = @shipper
	

Create	table	#ASNFlatFileHeader (
				LineId	int identity (1,1),
				LineData char(80))
print @ShipperID2
print @ASNDate
print @ASNTime
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('//STX12//856'+  @TradingPartner + @ShipperID+ @PartialComplete )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('01'+  @PurposeCode + @ShipperID2 + @ASNDate + @ASNTime + @EstimatedArrivalDate + @EstimatedArrivalTime +@ShippedDate + @ShippedTime )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('02' + @GrossWeightQualifier + @GrossWeightLbs + @WeightUM )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('03' +  @PackagingCode +  @PackCount  )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('04' + @SCAC  + @TransMode )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('05' +  @EquipDesc + @EquipInitial + @TrailerNumber )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' +  @REFPKQual + @ShipperID )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('06' +  @REFBMQual +  @REFBMValue )
INSERT	#ASNFlatFileHeader (LineData)
	SELECT	('07' + @SupplierCode + @ShipToID +  @SupplierCode )


 --ASN Detail

declare	@ShipperDetail table (
	Part varchar(25),
	ShipperID int,
	CustomerPart varchar(35),
	DeliveryOrderNo varchar(50),
	OrderNo int,
	SDQty int,
	SDAccum int,
	DORAccum int
	 primary key (CustomerPart, DeliveryOrderNo)
	)
insert @ShipperDetail
			( Part ,
			ShipperID,
			CustomerPart ,
			DeliveryOrderNo ,
			SDQty, 
			SDAccum,
			OrderNo         
        )	
select
	coalesce(sd.Part_original, sd.part),
	s.id,
	sd.Customer_Part,
	coalesce(nullif(sd.release_no,''),sd.customer_po,''),
	--MazdaDO.DeliveryOrderNumber (This will be re-written if it is found that the customer needs to split DOR numbers),
	--Sum(MazdaDO.Quantity)(This will be re-written if it is found that the customer needs to split DOR numbers,
	sd.qty_packed,
	sd.accum_shipped,
	order_no
	
from shipper_detail sd
/*left join
		EDI.MazdaDeliveryOrderNumbers MazdaDO on MazdaDO.OrderNo = sd.order_no and sd.shipper = @shipper and MazdaDO.ShipperID = @shipper*/
join
	shipper s on sd.shipper = s.id and s.id = @shipper

	
	/*update sd1
	set		sd1.DORAccum = (select (max(SDAccum) - sum(SDQty)) + sd1.SDQty from @ShipperDetail sd2 where sd2.ShipperID = sd1.ShipperID and sd2.DeliveryOrderNo <= sd1.DeliveryOrderNo and sd1.orderNo = sd2.orderNo)
	from		@ShipperDetail  sd1
	*/
declare	@ShipperSerialAccum table (
	Id int identity(1,1),
	Part varchar(25),
	ShipperID int,
	SerialNumber int, 
	SerialQty int,
	SerialQtyAccum int,
	primary key (SerialNumber)
	)
insert @ShipperSerialAccum
			(	Part ,
				ShipperID,
				SerialNumber,
				SerialQty,
				SerialQtyAccum
        )	
select
	sd.Part_original,
	s.id,
	at.serial,
	at.quantity,
	0
	
from
	audit_trail at
join
	dbo.shipper_detail sd on at.shipper = convert(varchar(15), sd.shipper)and sd.part_original = at.part and sd.shipper = @shipper
join
	shipper s on sd.shipper = s.id
order by
	sd.part_original,
	at.quantity asc

update saccum
set		SerialQtyAccum = ( select sum(SerialQty) from @ShipperSerialAccum sAccum2 where sAccum2.id<= saccum.id and sAccum2.part = sAccum.part)
from		@ShipperSerialAccum saccum


	
--Delcare Variables for ASN Details		
declare	
	@CustomerPartBP char(2),
	@CustomerPartRC char(2),
	@CustomerPart char(30) ,
	@CustomerECL char(3),
	@ContainerType char(30),
	@Part varchar(25),
	@QtyPacked char(9),
	@UM char(2),
	@AccumShipped char(11),
	@CustomerPO char(13),
	@DeliveryOrderNo char(30),
	@BOL char(16),
	@PackSlip char(16),
	@Destination char(17), 
	@ASNOverlayGroup varchar(10),
	@DockCode	char(8),
	@ACIndicator char(1),
	@ACHandling char(2),
	@ACClause char(4),
	@ACCharge char(11),
	@ContainerCount char(12),
	@PackageType char(30),
	@REFDetailPKQualifier char(2),
	@REFDetailPK char(30),
	@REFDetailBMQualifier char(2),
	@REFDetailDOQualifier char(2),
	@REFDetailBM char(30),
	@SerialNumber char(30),
	@SerialQty char(9)
	
	select @UM ='PC'
	select	@REFDetailPKQualifier = @REFPKQual
	select	@REFDetailPK = @REFPKValue
	select	@REFDetailBMQualifier = @REFBMQual
	select	@REFDetailDOQualifier = 'DO'
	select	@REFDetailBM = @REFBMValue
	
Create	table	#FlatFileLines (
				LineId	int identity(200,1),
				LineData char(80)
				 )

declare
	PartPOLine cursor local for
select
			'BP',
			'RC',
			Part ,
			ShipperID ,
	        CustomerPart ,
	        DeliveryOrderNo ,
	        SDQty ,
	        SDAccum
	        
From
	@ShipperDetail SD
	order by
		ShipperID,
		CustomerPart,
		DeliveryOrderNo

open
	PartPOLine
while
	1 = 1 begin
	
	fetch
		PartPOLine
	into
		@CustomerPartBP ,
		@CustomerPartRC,
		@Part ,
		@PackSlip,
		@CustomerPart ,
		@DeliveryOrderNo,
		@QtyPacked,
		@AccumShipped
			
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
		
		INSERT	#FlatFileLines (LineData)
		SELECT	('08'+  @CustomerPart +  @QtyPacked + @UM + @AccumShipped   )
		
	--	INSERT	#FlatFileLines (LineData)
	--	SELECT	('09'+ @REFDetailPKQualifier +  @REFDetailPK   )
		
	--	INSERT	#FlatFileLines (LineData)
	--	SELECT	('09'+ @REFDetailBMQualifier +  @REFDetailBM   )
		
	INSERT	#FlatFileLines (LineData)
	SELECT	('09'+ @REFDetailDOQualifier +  @DeliveryOrderNo  )
		
		
		--Create Serial Loop
		
		declare
	PartSerials cursor local for
select
			SerialNumber,
			'CTN90',
			SerialQty
	        
from @ShipperSerialAccum
where	ShipperID = @shipper and
			Part =  @Part
	

open
	PartSerials
while
	1 = 1 begin
	
	fetch
		PartSerials
	into
		@SerialNumber ,
		@ContainerType,
		@SerialQty
					
	if	@@FETCH_STATUS != 0 begin
		break
	end
		
			INSERT	#FlatFileLines (LineData)
			SELECT	('10'+ '1     ' +  @SerialQty + 'CTN90'  + @SerialNumber )
		
	end	
	
	close
	PartSerials	
 
deallocate
	PartSerials
		--End Serial Loop
	
		
			
end
close
	PartPOLine	
 
deallocate
	PartPOLine
	


create	table
	#ASNResultSet (FFdata  char(80), LineID int)

insert #ASNResultSet
        ( FFdata, LineID )

select
	Convert(char(80), LineData), LineID
from	
	#ASNFlatFileHeader
insert
	#ASNResultSet (FFdata, LineID)
select
	Convert(char(77), LineData) + Convert(char(3), LineID),LineID
from	
	#FlatFileLines
	
select	FFdata
from		#ASNResultSet
order by LineID ASC


	      
set ANSI_Padding OFF	
go

rollback
go
/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_ASN.LOOP_HL_OrderLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_ASN.LOOP_HL_OrderLines'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_ASN.LOOP_HL_OrderLines
end
go

create function EDI_XML_Toyota_ASN.LOOP_HL_OrderLines
(	@ShipperID int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml = ''
	
	declare
		@ASNLines table
	(	ShipperID int
	,	ReturnableContainer varchar(20)
	,	SupplierCode varchar(20)
	,	CustomerPart varchar(30)
	,	ManifestNumber varchar(22)
	,	Quantity int
	)

	insert
		@ASNLines
	(	ShipperID
	,	ReturnableContainer
	,	SupplierCode
	,	CustomerPart
	,	ManifestNumber
	,	Quantity
	)
	select
		ShipperID = al.ShipperID
	,	ReturnableContainer = al.ReturnableContainer
	,	SupplierCode = al.SupplierCode
	,	CustomerPart = al.CustomerPart
	,	ManifestNumber = al.ManifestNumber
	,	Quantity = al.Quantity
	from
		EDI_XML_Toyota_ASN.ASNLines al
	where
		al.ShipperID = @ShipperID
	
	declare
		manifestHeaders cursor local for
	select distinct
		al.ReturnableContainer
	,	al.SupplierCode
	,	al.ManifestNumber
	from
		@ASNLines al

	open
		manifestHeaders

	declare
		@hl int = 1

	while
		1 =	1 begin

		declare
			@parentHL int

		declare
			@kanbanNumber varchar(20)
		,	@supplierCode varchar(20)
		,	@manifestNumber varchar(22)

		fetch
			manifestHeaders
		into
			@kanbanNumber
		,	@supplierCode
		,	@manifestNumber

		if	@@FETCH_STATUS != 0 begin
			break
		end

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V4010.SEG_HL(@hl, 1, 'O', 1)
					,	EDI_XML_V4010.SEG_PRF(@manifestNumber)
					,	EDI_XML_V4010.SEG_REF('MH', @ShipperID)
					,	(	select
					 			EDI_XML.LOOP_INFO('N1')
							,	EDI_XML_V4010.SEG_N1('SU', '92', @supplierCode)
					 		for xml raw ('LOOP-N1'), type
					 	)
					for xml raw ('LOOP-HL'), type
				)
			)

		declare
			manifestDetails cursor local for
		select
			al.CustomerPart
		,	al.Quantity
		from
			EDI_XML_Toyota_ASN.ASNLines al
		where
			al.ShipperID = @ShipperID
			and al.ManifestNumber = @manifestNumber

		open
			manifestDetails

		set	@parentHL = @hl			

		while
			1 = 1 begin

			declare
				@customerPart varchar(30)
			,	@quantity int

			fetch
				manifestDetails
			into
				@customerPart
			,	@quantity

			if	@@FETCH_STATUS != 0 begin
				break
			end

			set @hl = @hl + 1

			set	@xmlOutput = convert(varchar(max), @xmlOutput)
				+ convert
				(	varchar(max)
				,	(	select
							EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V4010.SEG_HL(@hl, @parentHL, 'I', 0)
						,	EDI_XML_V4010.SEG_LIN('001', 'BP', @customerPart, 'RC', @kanbanNumber)
						,	EDI_XML_V4010.SEG_SN1(null, @quantity, 'EA', null)
						for xml raw ('LOOP-HL'), type
					)
				)
		end
		close
			manifestDetails
		deallocate
			manifestDetails
	end
	close
		manifestHeaders
	deallocate
		manifestHeaders
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go


select
	EDI_XML_Toyota_ASN.LOOP_HL_OrderLines(76053)
return
go


/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_ASN.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_ASN.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_ASN.udf_Root
end
go

create function EDI_XML_Toyota_ASN.udf_Root
(	@ShipperID int
,	@Purpose char(2)
,	@PartialComplete int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	declare
		@itemLoops int
	,	@totalQuantity int

	select
		@itemLoops = count(distinct al.ManifestNumber) + count(*)
	,	@totalQuantity = sum(al.Quantity)
	from
		EDI_XML_Toyota_ASN.ASNLines al
	where
		al.ShipperID = @ShipperID
	
	set
		@xmlOutput =
			(	select
					EDI_XML.TRN_INFO('004010', '856', ah.TradingPartnerID, ah.iConnectID, ah.ShipperID, @PartialComplete)
				,	EDI_XML_V4010.SEG_BSN(@Purpose, ah.ShipperID, ah.ShipDate, ah.ShipTime)
				,	EDI_XML_V4010.SEG_DTM('011', ah.ShipDateTime, ah.TimeZoneCode)
				,	(	select
				 			EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V4010.SEG_HL(1, null, 'S', 1)
						,	EDI_XML_V4010.SEG_MEA('PD', 'G', ah.GrossWeight, 'LB')
						,	EDI_XML_V4010.SEG_MEA('PD', 'N', ah.NetWeight, 'LB')
						,	EDI_XML_V4010.SEG_TD1(ah.PackageType, ah.BOLQuantity)
						,	EDI_XML_V4010.SEG_TD5('B', '2', ah.Carrier, ah.TransMode, null, null)
						,	EDI_XML_V4010.SEG_TD3('TL', null, ah.TruckNumber)
						,	EDI_XML_V4010.SEG_REF('BM', ah.BOLNumber)
						,	(	select
						 			EDI_XML.LOOP_INFO('N1')
								,	EDI_XML_V4010.SEG_N1('SU', 92, ah.SupplierCode)
						 		for xml raw ('LOOP-N1'), type
						 	)
				 		for xml raw ('LOOP-HL'), type
				 	)
				,	EDI_XML_Toyota_ASN.LOOP_HL_OrderLines(@ShipperID)
				,	EDI_XML_V4010.SEG_CTT(1 + @ItemLoops, @TotalQuantity)
				from
					EDI_XML_Toyota_ASN.ASNHeaders ah
				where
					ah.ShipperID = @ShipperID
				for xml raw ('TRN-856'), type
			)

	/*	Add invoice. */
	set	@xmlOutput = convert
			(	xml
			,	convert(varchar(max), @xmlOutput)
					+ convert(varchar(max), EDI_XML_Toyota_Invoice.udf_Root(@ShipperID, @Purpose, 0))
			)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Toyota_ASN.udf_Root(76096, '00', 1)

select
	EDI_XML_Toyota_ASN.udf_Root(76023, '00', 1)

/*
Create schema Schema.FxAztec.EDI_XML_Toyota_ASN.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Toyota_ASN') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Toyota_ASN authorization dbo'
end
go

use FxAztec
go

update
	es
set	IConnectID =
		case
			when es.trading_partner_code = 'TMMI' then '2233'
			when es.trading_partner_code = 'TMMK' then '1407'
			when es.trading_partner_code = 'TMMWV' then '2315'
			when es.trading_partner_code = 'TMMC' then '2232'
		end
from
	dbo.edi_setups es
where
	es.asn_overlay_group like 'T%'
	and es.destination != ''

/*
Create View.FxAztec.EDI_XML_Toyota_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Toyota_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Toyota_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Toyota_ASN.ASNHeaders
end
go

create view EDI_XML_Toyota_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'TMMI')
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, s.date_shipped)
,	ShipTime = convert(time, s.date_shipped)
,	TimeZoneCode = 'ED'
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType = 'CTN90'
,	BOLQuantity =
		case
			when es.trading_partner_code = 'TMMWV' then
				coalesce
					(	nullif(pickup.Racks, 0)
					,	s.staged_objs
					)
			else s.staged_objs
		end
,	Carrier = s.ship_via
,	TransMode = coalesce(s.trans_mode, 'LT')
,	TruckNumber = coalesce(s.truck_number, convert(varchar(15), s.id))
,	BOLNumber = coalesce(s.bill_of_lading_number, s.id)
,	SupplierCode = es.supplier_code
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
	outer apply
		(	select
				Racks = sum(md.Racks)
			from
				EDIToyota.Pickups p
				join EDIToyota.ManifestDetails md
					on md.PickupID = p.RowID
			where
				p.ShipperID = s.id
		) pickup
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'T%'
go

select
	*
from
	EDI_XML_Toyota_ASN.ASNHeaders
where
	ShipperID in (76053, 76054, 76055)

select
	*
from
	dbo.shipper s
	join dbo.shipper_detail sd
		on sd.shipper = s.id
where
	s.id = 76053
/*
Create View.FxAztec.EDI_XML_Toyota_ASN.ASNLines.sql
*/

use FxAztec
go

--drop table EDI_XML_Toyota_ASN.ASNLines
if	objectproperty(object_id('EDI_XML_Toyota_ASN.ASNLines'), 'IsView') = 1 begin
	drop view EDI_XML_Toyota_ASN.ASNLines
end
go

create view EDI_XML_Toyota_ASN.ASNLines
as
select
	ShipperID = s.id
,	ReturnableContainer = 'M390'
,	SupplierCode = es.supplier_code
,	md.CustomerPart
,	md.ManifestNumber
,	md.Quantity
from
	dbo.shipper s
	join dbo.edi_setups es
		on es.destination = s.destination
	join EDIToyota.Pickups mp
		on mp.ShipperID = s.id
	join EDIToyota.ManifestDetails md
		on md.PickupID = mp.RowID
go

select
	*
from
	EDI_XML_Toyota_ASN.ASNLines al
where
	al.ShipperID in (76053, 76054, 76023)

/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_Invoice.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_Invoice.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_Invoice.SEG_DTM
end
go

create function EDI_XML_Toyota_Invoice.SEG_DTM
(	@dateCode varchar(3)
,	@date date
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO('004010', 'DTM')
			,	EDI_XML.DE('004010', '0374', @dateCode)
			,	EDI_XML.DE('004010', '0373', EDI_XML.FormatDate('004010',@date))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Toyota_Invoice.SEG_DTM('050', '2016-04-28 10:18')

/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_Invoice.udf_Root.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_Invoice.udf_Root'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_Invoice.udf_Root
end
go

create function EDI_XML_Toyota_Invoice.udf_Root
(	@ShipperID int
,	@Purpose char(2)
,	@PartialComplete int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set
		@xmlOutput =
			(	select
					EDI_XML.TRN_INFO('004010', '810', ih.TradingPartnerID, ih.iConnectID, ih.InvoiceNumber, 0)
				,	EDI_XML_V4010.SEG_BIG(ih.InvoiceDate, ih.InvoiceNumber)
				,	(	select
				 			EDI_XML.LOOP_INFO('IT1')
						,	EDI_XML_V4010.SEG_IT1(ih.KanbanCard, ih.Quantity, 'EA', ih.UnitPrice, 'QT', ih.CustomerPart, '1', 'N1')
						,	EDI_XML_V4010.SEG_REF('MK', ih.ManifestNumber)
						,	EDI_XML_Toyota_Invoice.SEG_DTM('050', ih.InvoiceDate)
				 		for xml raw ('LOOP-IT1'), type
				 	)
				,	EDI_XML_V4010.SEG_TDS(round(ih.InvoiceAmount,2))
				,	EDI_XML_V4010.SEG_CTT(1, null)
				from
					EDI_XML_Toyota_Invoice.InvoiceHeaders ih
				where
					ih.ShipperID = @ShipperID
				for xml raw ('TRN-810'), type
			)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Toyota_Invoice.udf_Root(76053, '00', 1)

select
	EDI_XML_Toyota_Invoice.udf_Root(76023, '00', 1)

/*
Create schema Schema.FxAztec.EDI_XML_Toyota_Invoice.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Toyota_Invoice') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Toyota_Invoice authorization dbo'
end
go

begin transaction
go

declare
	@shipper int = 76096

declare
	@TradingPartner	char(12),
	@ShipperIDHeader char(30) = @Shipper

select
	@TradingPartner	= coalesce(nullif(es.trading_partner_code,''), 'TMMI')

from
	Shipper s
join
	dbo.edi_setups es on s.destination = es.destination
join
	dbo.destination d on es.destination = d.destination
join
	dbo.customer c on c.customer = s.customer
	
where
	s.id = @shipper


Create	table	#ASNFlatFile (
				LineId	int identity,
				LineData char(78) )

--Declare Variables for 810 Flat File

Declare @1BIG01InvoiceDate char(8),
		@1BIG02InvoiceNumber char(5),
		@1IT01KanbanCard char(4) = 'M390',
		@1IT102QtyInvoiced char(12), 
		@1IT104UnitPrice char(16),
		@1IT102QtyInvoicedNumeric numeric(20,6), 
		@1IT104UnitPriceNumeric numeric(20,6),
		@1IT105BasisOfUnitPrice char(2) = 'QT',
		@1IT106PartQualifier char(2) = 'PN',
		@1IT107CustomerPart char(12),
		@1IT108PackageDrawingQual char(2) = 'PK',
		@1IT109PackageDrawing char(12) = '1',
		@1IT110 char(2) = 'ZZ', 
		@1IT111 char(12) = 'N1',
		@1REF01MKQualifier Char(2) = 'MK',
		@1REF02Manifest Char(30),
		@1DTM02PickUpDate char(8),
		@1TDS01InvoiceAmount char(12),
		@PartNumber varchar(25)

select
		
		@1BIG01InvoiceDate= CONVERT(VARCHAR(25), s.date_shipped, 112)+LEFT(CONVERT(VARCHAR(25), s.date_shipped, 108),2) +SUBSTRING(CONVERT(VARCHAR(25), s.date_shipped, 108),4,2),
		
		@1BIG02InvoiceNumber = '01350'

		


	from
		Shipper s
	join
		dbo.edi_setups es on s.destination = es.destination
	join
		dbo.destination d on es.destination = d.destination
	join
		dbo.customer c on c.customer = s.customer
	
	where
		s.id = @shipper


declare	@InvoiceDetail table (
	ManifestNumber varchar(25),
	PartNumber varchar(25),
	CustomerPart varchar(50),
	QtyShipped int,
	Price numeric(20,6))
	
insert	@InvoiceDetail 
(	ManifestNumber,
	PartNumber,
	CustomerPart,
	QtyShipped,
	Price
	)
	
select
	
	md.ManifestNumber,
	sd.part_original,
	md.customerpart,
	md.Quantity,
	sd.alternate_price
from
	shipper_detail sd
join
	shipper s on s.id = @shipper
join
		EDIToyota.Pickups mp on mp.ShipperID = @shipper
join
		EDIToyota.ManifestDetails md on md.PickupID= mp.RowID
Where
	sd.shipper = @shipper and
	sd.order_no = md.OrderNo
	
declare
	InvoiceLine cursor local for
select
	ManifestNumber,
	PartNumber,
	Customerpart
	,	round(QtyShipped,0)
	,	round(Price,4)
	,	round(QtyShipped,0)
	,	round(Price,4)
From
	@InvoiceDetail InvoiceDetail


open
	InvoiceLine

while
	1 = 1 begin
	
	fetch
		InvoiceLine
	into
		@1REF02Manifest,
		@PartNumber,
		@1IT107CustomerPart
	,	@1IT102QtyInvoiced
	, @1IT104UnitPrice
	,	@1IT102QtyInvoicedNumeric
	, @1IT104UnitPriceNumeric
			
			
	if	@@FETCH_STATUS != 0 begin
		break
	end

	INSERT	#ASNFlatFile (LineData)
	SELECT	('//STX12//810'
						+  @TradingPartner 
						+  @ShipperIDHeader
						+  'P' )

INSERT	#ASNFlatFile (LineData)
	SELECT	(	'01'
				+		@1BIG01InvoiceDate
				+		@1BIG02InvoiceNumber
						)


	Insert	#ASNFlatFile (LineData)
					Select  '02' 									
							+ @1IT01KanbanCard
							+ @1IT102QtyInvoiced
							+ @1IT104UnitPrice
							+ @1IT105BasisOfUnitPrice
							+ @1IT106PartQualifier
							+ @1IT107CustomerPart
							+ @1IT108PackageDrawingQual
							+ @1IT109PackageDrawing
							+ @1IT110
							+ @1IT111

	Insert	#ASNFlatFile (LineData)
					Select  '03' 									
							+ @1REF01MKQualifier
							+ @1REF02Manifest


	Insert	#ASNFlatFile (LineData)
					Select  '04' 									
							+ @1BIG01InvoiceDate



Select @1TDS01InvoiceAmount = substring(convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)),1,patindex('%.%', convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)))-1 ) +
		substring(convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)),patindex('%.%', convert(varchar(max),round(sum(@1IT102QtyInvoicedNumeric*@1IT104UnitPriceNumeric) ,2)))+1, 2)


Insert	#ASNFlatFile (LineData)
					Select  '05' 									
							+ @1TDS01InvoiceAmount


	
	
								
end
close
	InvoiceLine	
 
deallocate
	InvoiceLine	




select 
	--LineData +convert(char(1), (lineID % 2 ))
	 LineData + case when left(linedata,2) in ('06', '11', '14') then '' else right(convert(char(2), (lineID )),2) end
From 
	#ASNFlatFile
order by 
	LineID


	      
set ANSI_Padding OFF	
go

rollback
go


/*
Create View.FxAztec.EDI_XML_Toyota_Invoice.InvoiceHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Toyota_Invoice.InvoiceHeaders
if	objectproperty(object_id('EDI_XML_Toyota_Invoice.InvoiceHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Toyota_Invoice.InvoiceHeaders
end
go

create view EDI_XML_Toyota_Invoice.InvoiceHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'TMMI')
,	InvoiceDate = convert(date, s.date_shipped)
,	InvoiceTime = convert(time, s.date_shipped)
,	md.ManifestNumber
,	md.CustomerPart
,	md.Quantity
,	UnitPrice = convert(numeric(9,4), sd.alternate_price)
,	KanbanCard = 'M390'
,	InvoiceNumber = '01350'
,	InvoiceAmount = md.Quantity * sd.alternate_price
from
	dbo.shipper s
	join shipper_detail sd
		on sd.shipper = s.id
	join dbo.edi_setups es
		on s.destination = es.destination
	join EDIToyota.Pickups mp
		on mp.ShipperID = s.id
	join EDIToyota.ManifestDetails md
		on md.PickupID= mp.RowID
		and sd.order_no = md.OrderNo
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'T%'
go

select
	*
from
	EDI_XML_Toyota_Invoice.InvoiceHeaders
where
	ShipperID in (76053, 76054, 76055)

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.CE
end
go

create function EDI_XML_V2002FORD.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('002002FORD', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.CE('C001', EDI_XML_V2002FORD.DE('355', 'LB'))

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.DE
end
go

create function EDI_XML_V2002FORD.DE
(	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.DE('002002FORD', @elementCode, @value)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.DE('0353', '00')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_BSN
end
go

create function EDI_XML_V2002FORD.SEG_BSN
(	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_BSN('002002FORD', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_BSN('00', 75964, '2016-04-29', '10:11')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_CLD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_CLD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_CLD
end
go

create function EDI_XML_V2002FORD.SEG_CLD
(	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CLD('002002FORD', @loads, @units, @packageCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_CLD(5, 100, 'CTN90')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_CTT
end
go

create function EDI_XML_V2002FORD.SEG_CTT
(	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CTT('002002FORD', @lineCount, @hashTotal)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_CTT(12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_DTM
end
go

create function EDI_XML_V2002FORD.SEG_DTM
(	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_DTM('002002FORD', @dateCode, @dateTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_DTM('011', '2016-04-28 10:18')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_HL
end
go

create function EDI_XML_V2002FORD.SEG_HL
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_HL('002002FORD', @idNumber, @parentIDNumber, @levelCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_HL(1, null, 'S')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_INFO
end
go

create function EDI_XML_V2002FORD.SEG_INFO
(	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_INFO('002002FORD', @segmentCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_INFO ('BSN')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_LIN
end
go

create function EDI_XML_V2002FORD.SEG_LIN
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_LIN('002002FORD', @productQualifier, @productNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_LIN('BP', 'FL1W 4C000 FB')

select
	*
from
	fxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'LIN'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0350'
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_MEA.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_MEA'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_MEA
end
go

create function EDI_XML_V2002FORD.SEG_MEA
(	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_MEA('002002FORD', @measurementReference, @measurementQualifier, @measurementValue, @measurementUnit)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', 680, 'LB')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_N1
end
go

create function EDI_XML_V2002FORD.SEG_N1
(	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N1('002002FORD', @entityIdentifierCode, @identificationQualifier, @identificationCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_N1('ST', '92', 'TC05A')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_PRF
end
go

create function EDI_XML_V2002FORD.SEG_PRF
(	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_PRF('002002FORD', @poNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_PRF('ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_REF
end
go

create function EDI_XML_V2002FORD.SEG_REF
(	@refenceQualifier varchar(3)
,	@refenceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_REF('002002FORD', @refenceQualifier, @refenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_REF('BM', '797120')

select
	EDI_XML_V2002FORD.SEG_REF('PK', '75964')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_SN1
end
go

create function EDI_XML_V2002FORD.SEG_SN1
(	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_SN1('002002FORD', @identification, @units, @unitMeasure, @accum)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_SN1(null, 500, 'EA', 17200)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0350', '0355')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_TD1
end
go

create function EDI_XML_V2002FORD.SEG_TD1
(	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD1('002002FORD', @packageCode, @ladingQuantity)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_TD1('CTN90', 39)

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_TD3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_TD3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_TD3
end
go

create function EDI_XML_V2002FORD.SEG_TD3
(	@equipmentCode varchar(3)
,	@equipmentInitial varchar(12)
,	@equipmentNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2002FORD.SEG_INFO('TD3')
			,	EDI_XML_V2002FORD.DE('0040', @equipmentCode)
			,	EDI_XML_V2002FORD.DE('0206', @equipmentInitial)
			,	EDI_XML_V2002FORD.DE('0207', @equipmentNumber)
			for xml raw ('SEG-TD3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_TD3('TL', 'LGSI', '386206')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_TD5.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_TD5'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_TD5
end
go

create function EDI_XML_V2002FORD.SEG_TD5
(	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD5('002002FORD', @routingSequenceCode, @identificaitonQualifier, @identificaitonCode, @transMethodCode, @locationQualifier, @locationIdentifier)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_TD5('B', 2, 'RYDD', 'M', null, null)

select
	EDI_XML_V2002FORD.SEG_TD5('B', 2, 'PSKL', 'C', 'PP', 'PC07A')

/*
Create schema Schema.FxAztec.EDI_XML_V2002FORD.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_V2002FORD') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_V2002FORD authorization dbo'
end
go


/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.CE
end
go

create function EDI_XML_V2040.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('002040', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.CE('C001', EDI_XML_V2040.DE('355', 'LB'))

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = 'C001'
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.DE
end
go

create function EDI_XML_V2040.DE
(	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.DE('002040', @elementCode, @value)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.DE('0353', '00')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_BSN
end
go

create function EDI_XML_V2040.SEG_BSN
(	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_BSN('002040', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_BSN('00', 75964, '2016-04-29', '10:11')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_CLD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_CLD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_CLD
end
go

create function EDI_XML_V2040.SEG_CLD
(	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CLD('002040', @loads, @units, @packageCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_CLD(5, 100, 'CTN90')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_CTT
end
go

create function EDI_XML_V2040.SEG_CTT
(	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CTT('002040', @lineCount, @hashTotal)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_CTT(12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_DTM
end
go

create function EDI_XML_V2040.SEG_DTM
(	@dateCode varchar(3)
,	@dateTime datetime
,	@timeZoneCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('DTM')
			,	EDI_XML_V2040.DE('0374', @dateCode)
			,	EDI_XML_V2040.DE('0373', EDI_XML.FormatDate('002040', @dateTime))
			,	EDI_XML_V2040.DE('0337', EDI_XML.FormatTime('002040', @dateTime))
			,	EDI_XML_V2040.DE('0623', @timeZoneCode)
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_DTM('011', '2016-04-28 10:18', 'ED')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_ETD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_ETD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_ETD
end
go

create function EDI_XML_V2040.SEG_ETD
(	@transportationReasonCode varchar(3)
,	@transportationResponsibilityCode varchar(3)
,	@referenceNumberQualifier varchar(3)
,	@referenceNumber varchar(30)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_ETD ('002040', @transportationReasonCode, @transportationResponsibilityCode, @referenceNumberQualifier, @referenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_ETD('ZZ', 'A', 'AE', 'AETCNumber')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_HL
end
go

create function EDI_XML_V2040.SEG_HL
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
,	@childCode int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('HL')
			,	EDI_XML_V2040.DE('0628', @idNumber)
			,	EDI_XML_V2040.DE('0734', @parentIDNumber)
			,	EDI_XML_V2040.DE('0735', @levelCode)
			,	EDI_XML_V2040.DE('0736', @childCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_HL(1, null, 'S', 1)

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_INFO
end
go

create function EDI_XML_V2040.SEG_INFO
(	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_INFO('002040', @segmentCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_INFO ('BSN')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_LIN
end
go

create function EDI_XML_V2040.SEG_LIN
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_LIN('002040', @productQualifier, @productNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_LIN('BP', 'FL1W 4C000 FB')

select
	*
from
	fxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'LIN'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0350'
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_MEA.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_MEA'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_MEA
end
go

create function EDI_XML_V2040.SEG_MEA
(	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('MEA')
			,	EDI_XML_V2040.DE('0737', @measurementReference)
			,	EDI_XML_V2040.DE('0738', @measurementQualifier)
			,	EDI_XML_V2040.DE('0739', @measurementValue)
			,	EDI_XML_V2040.CE('C001', EDI_XML_V2040.DE('355', @measurementUnit))
			for xml raw ('SEG-MEA'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_MEA('PD', 'G', 680, 'LB')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_N1
end
go

create function EDI_XML_V2040.SEG_N1
(	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N1('002040', @entityIdentifierCode, @identificationQualifier, @identificationCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_N1('ST', '92', 'TC05A')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_PRF
end
go

create function EDI_XML_V2040.SEG_PRF
(	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_PRF('002040', @poNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_PRF('ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_REF
end
go

create function EDI_XML_V2040.SEG_REF
(	@refenceQualifier varchar(3)
,	@refenceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_REF('002040', @refenceQualifier, @refenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_REF('BM', '797120')

select
	EDI_XML_V2040.SEG_REF('PK', '75964')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_SN1
end
go

create function EDI_XML_V2040.SEG_SN1
(	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_SN1('002040', @identification, @units, @unitMeasure, @accum)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_SN1(null, 500, 'EA', 17200)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0350', '0355')
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_TD1
end
go

create function EDI_XML_V2040.SEG_TD1
(	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD1('002040', @packageCode, @ladingQuantity)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_TD1('CTN90', 39)

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_TD3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_TD3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_TD3
end
go

create function EDI_XML_V2040.SEG_TD3
(	@equipmentCode varchar(3)
,	@equipmentInitial varchar(12)
,	@equipmentNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('TD3')
			,	EDI_XML_V2040.DE('0040', @equipmentCode)
			,	EDI_XML_V2040.DE('0206', @equipmentInitial)
			,	EDI_XML_V2040.DE('0207', @equipmentNumber)
			for xml raw ('SEG-TD3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_TD3('TL', 'LGSI', '386206')

/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_TD5.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_TD5'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_TD5
end
go

create function EDI_XML_V2040.SEG_TD5
(	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD5('002040', @routingSequenceCode, @identificaitonQualifier, @identificaitonCode, @transMethodCode, @locationQualifier, @locationIdentifier)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_TD5('B', 2, 'RYDD', 'M', null, null)

select
	EDI_XML_V2040.SEG_TD5('B', 2, 'PSKL', 'C', 'PP', 'PC07A')

/*
Create schema Schema.FxAztec.EDI_XML_V2040.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_V2040') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_V2040 authorization dbo'
end
go


/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.CE
end
go

create function EDI_XML_V4010.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('004010', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.CE('C001', EDI_XML_V4010.DE('355', 'LB'))

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.DE
end
go

create function EDI_XML_V4010.DE
(	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.DE('004010', @elementCode, @value)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.DE('0353', '00')
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_BIG.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_BIG'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_BIG
end
go

create function EDI_XML_V4010.SEG_BIG
(	@invoiceDate date
,	@invoiceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO('004010', 'BIG')
			,	EDI_XML.DE('004010', '0373', EDI_XML.FormatDate('004010', @invoiceDate))
			,	EDI_XML.DE('004010', '0076', @invoiceNumber)
			for xml raw ('SEG-BIG'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_BIG(getdate(), '01350')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_BSN
end
go

create function EDI_XML_V4010.SEG_BSN
(	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_BSN('004010', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_BSN('00', 75964, '2016-04-29', '10:11')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_CLD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_CLD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_CLD
end
go

create function EDI_XML_V4010.SEG_CLD
(	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CLD('004010', @loads, @units, @packageCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_CLD(5, 100, 'CTN90')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_CTT
end
go

create function EDI_XML_V4010.SEG_CTT
(	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CTT('004010', @lineCount, @hashTotal)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_CTT(12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_DTM
end
go

create function EDI_XML_V4010.SEG_DTM
(	@dateCode varchar(3)
,	@dateTime datetime
,	@timeZoneCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('DTM')
			,	EDI_XML_V4010.DE('0374', @dateCode)
			,	EDI_XML_V4010.DE('0373', EDI_XML.FormatDate('004010', @dateTime))
			,	EDI_XML_V4010.DE('0337', EDI_XML.FormatTime('004010', @dateTime))
			,	EDI_XML_V4010.DE('0623', @timeZoneCode)
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_DTM('011', '2016-04-28 10:18', 'ED')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_HL
end
go

create function EDI_XML_V4010.SEG_HL
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
,	@childCode int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('HL')
			,	EDI_XML_V4010.DE('0628', @idNumber)
			,	EDI_XML_V4010.DE('0734', @parentIDNumber)
			,	EDI_XML_V4010.DE('0735', @levelCode)
			,	EDI_XML_V4010.DE('0736', @childCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_HL(1, null, 'S', 1)

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_INFO
end
go

create function EDI_XML_V4010.SEG_INFO
(	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_INFO('004010', @segmentCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_INFO ('BSN')
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_IT1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_IT1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_IT1
end
go

create function EDI_XML_V4010.SEG_IT1
(	@assignedIdentification varchar(20)
,	@quantityInvoiced int
,	@unit char(2)
,	@unitPrice numeric(9,4)
,	@unitPriceBasis char(2)
,	@companyPartNumber varchar(40)
,	@packagingDrawing varchar(40)
,	@mutuallyDefinedIdentifier varchar(40)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_IT1
		(	'004010'
		,	@assignedIdentification
		,	@quantityInvoiced
		,	@unit
		,	@unitPrice
		,	@unitPriceBasis
		,	@companyPartNumber
		,	@packagingDrawing
		,	@mutuallyDefinedIdentifier
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_IT1('M390', 36, 'EA', 10.42061, 'QT', '123210P05000', '1', 'N1')
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_LIN
end
go

create function EDI_XML_V4010.SEG_LIN
(	@assignedIdentification varchar(20)
,	@productQualifier varchar(3)
,	@productNumber varchar(25)
,	@containerQualifier varchar(3)
,	@containerNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('LIN')
			,	EDI_XML_V4010.DE('0350', @assignedIdentification)
			,	EDI_XML_V4010.DE('0235', @productQualifier)
			,	EDI_XML_V4010.DE('0234', @productNumber)
			,	EDI_XML_V4010.DE('0235', @containerQualifier)
			,	EDI_XML_V4010.DE('0234', @containerNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_LIN('001', 'BP', '123210P05000', 'RC', 'M390')

select
	*
from
	fxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'LIN'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0350'
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_MEA.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_MEA'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_MEA
end
go

create function EDI_XML_V4010.SEG_MEA
(	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('MEA')
			,	EDI_XML_V4010.DE('0737', @measurementReference)
			,	EDI_XML_V4010.DE('0738', @measurementQualifier)
			,	EDI_XML_V4010.DE('0739', @measurementValue)
			,	EDI_XML_V4010.CE('C001', EDI_XML_V4010.DE('355', @measurementUnit))
			for xml raw ('SEG-MEA'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_MEA('PD', 'G', 680, 'LB')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_N1
end
go

create function EDI_XML_V4010.SEG_N1
(	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N1('004010', @entityIdentifierCode, @identificationQualifier, @identificationCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_N1('ST', '92', 'TC05A')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_PRF
end
go

create function EDI_XML_V4010.SEG_PRF
(	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_PRF('004010', @poNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_PRF('ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_REF
end
go

create function EDI_XML_V4010.SEG_REF
(	@refenceQualifier varchar(3)
,	@refenceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_REF('004010', @refenceQualifier, @refenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_REF('BM', '797120')

select
	EDI_XML_V4010.SEG_REF('PK', '75964')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_SN1
end
go

create function EDI_XML_V4010.SEG_SN1
(	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_SN1('004010', @identification, @units, @unitMeasure, @accum)
--- </Body>

---	<Return>
	return
		@xmlOutput
end

GO


/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TD1
end
go

create function EDI_XML_V4010.SEG_TD1
(	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD1('004010', @packageCode, @ladingQuantity)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TD1('CTN90', 39)

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TD3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TD3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TD3
end
go

create function EDI_XML_V4010.SEG_TD3
(	@equipmentCode varchar(3)
,	@equipmentInitial varchar(12)
,	@equipmentNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('TD3')
			,	EDI_XML_V4010.DE('0040', @equipmentCode)
			,	EDI_XML_V4010.DE('0206', @equipmentInitial)
			,	EDI_XML_V4010.DE('0207', @equipmentNumber)
			for xml raw ('SEG-TD3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TD3('TL', 'LGSI', '386206')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TD5.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TD5'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TD5
end
go

create function EDI_XML_V4010.SEG_TD5
(	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD5('004010', @routingSequenceCode, @identificaitonQualifier, @identificaitonCode, @transMethodCode, @locationQualifier, @locationIdentifier)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TD5('B', 2, 'RYDD', 'M', null, null)

select
	EDI_XML_V4010.SEG_TD5('B', 2, 'PSKL', 'C', 'PP', 'PC07A')

/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TDS.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TDS'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TDS
end
go

create function EDI_XML_V4010.SEG_TDS
(	@totalMonetaryValue numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TDS('004010', @totalMonetaryValue)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TDS(375.141)

/*
Create schema Schema.FxAztec.EDI_XML_V4010.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_V4010') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_V4010 authorization dbo'
end
go

