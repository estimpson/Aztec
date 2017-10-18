
/*
Create Procedure.FxEDI.EDI_iConnect.usp_ShipNotice997_Stage_1.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI_iConnect.usp_ShipNotice997_Stage_1'), 'IsProcedure') = 1 begin
	drop procedure EDI_iConnect.usp_ShipNotice997_Stage_1
end
go

create procedure EDI_iConnect.usp_ShipNotice997_Stage_1
	@TranDT datetime = null out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIIConnect.usp_Test
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
/*	Look for documents already in the queue.*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin
	rollback tran @ProcName
	goto queueError
end

/*	Move new and reprocessed IConnect acknowledements to Staging. */
/*		Set new and requeued documents to in process.*/
set	@TableName = 'EDI.EDIDocuments ed'

if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
			and ed.Status in
				(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
				,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
				)
	) begin
	
	--- <Update rows="1+">
	update
		ed
	set
		Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	from
		EDI.EDIDocuments ed
	where
		ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
		and ed.Status in
			(	0 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'New'))
			,	2 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Requeued'))
			)
		and not exists
		(	select
				*
			from
				EDI.EDIDocuments ed1
			where
			ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
			and ed1.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
		)
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		goto queueError
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		goto queueError
	end
	--- </Update>
end
--- </Update>

/*	Prepare data for Staging Tables...*/
if	exists
	(	select
			*
		from
			EDI.EDIDocuments ed
		where
			ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
			and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	) begin

/*		- prepare IConnect acknowledgements...*/
	declare
		@ShipNotice997s table
	(	RawDocumentGUID uniqueidentifier
	,	DocumentImportDT datetime
	,	ASN_Number varchar(30)
	,	AcknowledgementStatus int
	,	ValidationOutput varchar(max)
	)

	insert
		@ShipNotice997s
	(	RawDocumentGUID
	,	DocumentImportDT
	,	ASN_Number
	,	AcknowledgementStatus
	,	ValidationOutput
	)
	select
		RawDocumentGUID = ed.GUID
	,	DocumentImportDT = ed.RowCreateDT
	,	ASN_Number = ed.Data.value('(/TRN-997/Record/Item [@Name="ASNNum"]/@Value)[1]', 'varchar(30)')
	,	AcknowledgementStatus = ed.Data.value('(/TRN-997/Record/Field [@Name="ErrorCode"]/@Value)[1]', 'varchar(30)')
	,	ValidationOutput = ed.Data.value('(/TRN-997/Record/Field [@Name="Status"]/@Value)[1]', 'varchar(max)')
	from
		EDI.EDIDocuments ed
	where
		ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))

	--- <Insert rows="*">
	set	@TableName = 'FxTSM.EDIIConnect.ShipNoticeAcknowledgements'
	
	insert
		FxAztec.EDI_iConnect.ShipNoticeAcknowledgements
	(   RawDocumentGUID
	,	Type
	,	DocumentImportDT
	,	ASN_Number
	,	AcknowledgementStatus
	,	ValidationOutput
	)
	select
		ica.RawDocumentGUID
	,	Type = 2 -- (select dbo.udf_TypeValue('EDIIConnect.ShipNoticeAcknowledgements', '997'))
	,	ica.DocumentImportDT
	,	convert(int, ica.ASN_Number)
	,	ica.AcknowledgementStatus
	,	ica.ValidationOutput
	from
		@ShipNotice997s ica
	where
		ica.ASN_Number not like '%[^0-9]%'
	
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

	--- <Update rows="1+">
	set	@TableName = 'EDI.EDIDocuments'
	
	update
		ed
	set
		Status = 1 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'Processed'))
	from
		EDI.EDIDocuments ed
	where
		ed.Data.exist('/TRN-997/Record/Item [@Name="ASNNum"][@Value>""]') = 1
		and ed.Status = 100 -- (select dbo.udf_StatusValue('EDI.EDIDocuments', 'InProcess'))
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
	
end
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

---	<Error>
queueError:

set @Result = 100
raiserror ('Ship notice 997s already in process.  Use EDIIConnect.usp_ClearQueue to clear the queue if necessary.', 16, 1)
return
--- </Error>

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
	@ProcReturn = EDIIConnect.usp_ShipNotice997_Stage_1
	@TranDT = @TranDT out
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
go

