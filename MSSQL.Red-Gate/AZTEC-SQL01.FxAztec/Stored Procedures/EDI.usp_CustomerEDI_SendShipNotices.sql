SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [EDI].[usp_CustomerEDI_SendShipNotices]
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
GO
