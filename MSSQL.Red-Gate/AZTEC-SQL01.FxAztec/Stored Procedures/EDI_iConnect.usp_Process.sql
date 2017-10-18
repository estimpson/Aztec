SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI_iConnect].[usp_Process]
	@TranDT datetime = null out
,	@Result integer = null out
,	@Testing int = 1
--<Debug>
,	@Debug integer = 0
--</Debug>
as
set nocount on
set ansi_warnings on
set	@Result = 999999

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	set	@StartDT = GetDate ()
	print	'START.   ' + Convert (varchar (50), @StartDT)
	set	@ProcStartDT = GetDate ()
end
--</Debug>

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI4010.usp_Test
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
--<Debug>
if @Debug & 1 = 1 begin
	print	'Get all of the new acknowledgements.'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	Get all of the new acknowledgements. */
declare
	@NewShipNoticeAcknowledgements table
(	RawDocumentGUID uniqueidentifier
,	DocumentImportDT datetime
,	ASN_Number varchar(30)
,	ShipDate datetime
,	SupplierCode varchar(30)
,	AcknowledgementStatus int
,	AcknowledgementType int
,	ValidationOutput varchar(max)
)

insert
	@NewShipNoticeAcknowledgements
select
	sna.RawDocumentGUID
,   sna.DocumentImportDT
,   sna.ASN_Number
,   sna.ShipDate
,   sna.SupplierCode
,   sna.AcknowledgementStatus
,	AcknowledgementType = sna.Type
,   sna.ValidationOutput
from
	EDI_iConnect.ShipNoticeAcknowledgements sna
where
	sna.Status = 0 --(select dbo.udf_StatusValue('EDI4010.ShipSchedules', 'Status', 'New'))

--<Debug>
if @Debug & 1 = 1 begin
	print	'If there aren''t any new ship notice acknowledgements, done.'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	If there aren't any new ship notice acknowledgements, done. */
if	not exists
	(	select
			*
		from
			@NewShipNoticeAcknowledgements nsna
	)
	and @Testing = 0 begin
	set @Result = 100
	rollback transaction @ProcName
	return
end

--<Debug>
if @Debug & 1 = 1 begin
	print	'Mark acknowledgement as active...'
	set	@StartDT = GetDate ()
end
/*	Mark acknowledgement as active. */
--- <Update rows="1+">
set	@TableName = 'EDI_iConnect.ShipNoticeAcknowledgements'

update
	sna
set
	Status = 1 --(select dbo.udf_StatusValue('EDI_iConnect.ShipNoticeAcknowledgements'', 'Status', 'Active'))
from
	EDI_iConnect.ShipNoticeAcknowledgements sna
	join @NewShipNoticeAcknowledgements nsna
		on nsna.RawDocumentGUID = sna.RawDocumentGUID

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 and @Testing = 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

--<Debug>
if @Debug & 1 = 1 begin
	print	'...marked.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--<Debug>
if @Debug & 1 = 1 begin
	print	'Write record to CustomerEDI_GenerationLog_Responses.'
	set	@StartDT = GetDate ()
end
--</Debug>
/*	Write record to CustomerEDI_GenerationLog_Responses. */
if	@Testing = 0 begin

	--- <Insert rows="1+">
	set	@TableName = 'dbo.CustomerEDI_GenerationLog_Responses'
	
	insert
		dbo.CustomerEDI_GenerationLog_Responses
	(	FileStreamID
	,	Status
	,	Type
	,	ParentFileStreamID
	,	ParentGenerationLogRowID
	,	MessageInfo
	)
	select
		FileStreamID = nsna.RawDocumentGUID
	,	Status = nsna.AcknowledgementStatus
	,	Type = nsna.AcknowledgementType --(select dbo.udf_TypeValue('dbo.CustomerEDI_GenerationLog_Responses', 'Type', 'IConnectAcknowledgement'))
	,   ParentFileStreamID = cegl.FileStreamID
	,	ParentGenerationLogRowID = cegl.RowID
	,	MessageInfo = nsna.ValidationOutput
	from
		@NewShipNoticeAcknowledgements nsna
		cross apply
			(	select top 1
					cegl.FileStreamID
				,	cegl.RowID
				from
					dbo.CustomerEDI_GenerationLog cegl
				where
					nsna.ASN_Number like '%' + convert(varchar, cegl.ShipperID) + '%'
				order by
					cegl.FileGenerationDT desc
			) cegl

	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount <= 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Insert>

	--- <Update rows="1+">
	set	@TableName = 'dbo.CustomerEDI_GenerationLog'
	
	update
		cegl
	set
		FileAcknowledgementDT = @TranDT
	,	Status =
			case
				when nsna.AcknowledgementStatus < 0 then -nsna.AcknowledgementType
				else nsna.AcknowledgementType
			end
	from
		dbo.CustomerEDI_GenerationLog cegl
		cross apply
			(	select top 1
					nsna.RawDocumentGUID
				,   nsna.DocumentImportDT
				,   nsna.ASN_Number
				,   nsna.ShipDate
				,   nsna.SupplierCode
				,   nsna.AcknowledgementStatus
				,	nsna.AcknowledgementType
				,   nsna.ValidationOutput
				from
					@NewShipNoticeAcknowledgements nsna
				where
					nsna.ASN_Number like '%' + convert(varchar, cegl.ShipperID) + '%'
				order by
					nsna.AcknowledgementType desc		
			) nsna
		cross apply
			(	select top 1
					cegl.FileStreamID
				,	cegl.RowID
				from
					dbo.CustomerEDI_GenerationLog cegl
				where
					nsna.ASN_Number like '%' + convert(varchar, cegl.ShipperID) + '%'
				order by
					cegl.FileGenerationDT desc
			) ceglLast
	where
		cegl.RowID = ceglLast.RowID
	
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
else
	begin
	select
		FileStreamID = nsna.RawDocumentGUID
	,	Status = nsna.AcknowledgementStatus
	,	Type = nsna.AcknowledgementType
	,   ParentFileStreamID = cegl.FileStreamID
	,	ParentGenerationLogRowID = cegl.RowID
	,	MessageInfo = nsna.ValidationOutput
	
	from
		@NewShipNoticeAcknowledgements nsna
		cross apply
			(	select top 1
					cegl.FileStreamID
				,	cegl.RowID
				from
					dbo.CustomerEDI_GenerationLog cegl
				where
					nsna.ASN_Number like '%' + convert(varchar, cegl.ShipperID) + '%'
				order by
					cegl.FileGenerationDT desc
			) cegl

	rollback tran @ProcName
end
	
---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 and @@TRANCOUNT > 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
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

begin transaction
go

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI_iConnect.usp_Process
	@TranDT = @TranDT out
,	@Result = @ProcResult out
,	@Testing = 1
,	@Debug = 1

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

--commit transaction
rollback transaction
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
