SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [EDIToyota].[usp_SendProcessEmailNotification]
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
	@Current862s table
(	RawDocumentGUID uniqueidentifier
,	ReleaseNo varchar(50)
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ConsigneeCode varchar(15)
,	CustomerPart varchar(35)
,	CustomerPO varchar(35)
,	CustomerModelYear varchar(35)
,	NewDocument int
)

insert
	@Current862s
select
	*
from
	#current862s c

declare
	@Current830s table
(	RawDocumentGUID uniqueidentifier
,	ReleaseNo varchar(50)
,	ShipToCode varchar(15)
,	ShipFromCode varchar(15)
,	ConsigneeCode varchar(15)
,	CustomerPart varchar(35)
,	CustomerPO varchar(35)
,	CustomerModelYear varchar(35)
,	NewDocument int
)

insert
	@Current830s
select
	*
from
	#current830s c

Declare @EDIOrdersAlert table (
	TradingPartner varchar(100) NULL,
	DocumentType varchar(30) NULL, --'PR - Planning Release; SS - ShipSchedule'
	AlertType varchar(100) NULL,
	ReleaseNo varchar(100) NULL,
	ShipToCode varchar(100) NULL,
	ConsigneeCode varchar(100) NULL,
	ShipFromCode varchar(100) NULL,
	CustomerPart varchar(100) NULL,
	CustomerPO varchar(100) NULL,
	CustomerModelYear varchar NULL,
	Description varchar (max)
	)
		
insert	
	@EDIOrdersAlert
(	TradingPartner,
	DocumentType,
	AlertType,
	ReleaseNo ,
	ShipToCode,
	ConsigneeCode,
	ShipFromCode,
	CustomerPart,
	CustomerPO,
	CustomerModelYear,
	Description 
)

Select
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  ' Exception'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'Please Add Blanket Order to Fx and Reprocess EDI'
from
	@Current862s a
Where
		coalesce(a.newDocument,0) = 1
and not exists
( Select 1 from 
		EDIToyota.ShipSchedules b
 Join 
	EDIToyota.BlanketOrders bo on b.CustomerPart = bo.CustomerPart
and
	b.ShipToCode = bo.EDIShipToCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = b.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = b.CustomerModelYear)
where
				a.RawDocumentGUID = b.RawDocumentGUID and
				a.CustomerPart = b.CustomerPart and
				a.ShipToCode = b.ShipToCode and
				coalesce(a.customerPO,'') = coalesce(b.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(b.CustomerModelYear,'')
)
union
select
	TradingPartner	= coalesce
		(	(	select
					max(TradingPartner)
				from
					FxEDI.EDI.EDIDocuments
				where
					GUID = a.RawDocumentGUID
			)
		,	''
		)
,	DocumentType = 'PR'
,	AlertType = ' Exception'
,	ReleaseNo = coalesce(a.ReleaseNo, '')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode = coalesce(a.ConsigneeCode, '')
,	ShipFromCode = coalesce(a.ShipFromCode, '')
,	CustomerPart = coalesce(a.CustomerPart, '')
,	CustomerPO = coalesce(a.CustomerPO, '')
,	CustomerModelYear = coalesce(a.CustomerModelYear, '')
,	Description = 'Please Add Blanket Order to Fx and Reprocess EDI'
from
	@Current830s a
where
	coalesce(a.NewDocument, 0) = 1
	and not exists
	(	select
			*
		from
			EDIToyota.PlanningReleases b
			join EDIToyota.BlanketOrders bo
				on b.CustomerPart = bo.CustomerPart
				and
				(	bo.EDIShipToCode = b.ShipToCode
					or bo.MaterialIssuer = b.ShipToCode
				)
				and
				(	bo.CheckCustomerPOPlanning = 0
					or bo.CustomerPO = b.CustomerPO
				)
				and
				(	bo.CheckModelYearPlanning = 0
					or bo.ModelYear830 = b.CustomerModelYear
				)
		where
			a.RawDocumentGUID = b.RawDocumentGUID
			and a.CustomerPart = b.CustomerPart
			and a.ShipToCode = b.ShipToCode
			and coalesce(a.CustomerPO, '') = coalesce(b.CustomerPO, '')
			and coalesce(a.CustomerModelYear, '') = coalesce(b.CustomerModelYear, '')
	)
union

--Orders Processed
Select 
	TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  ' OrderProcessed'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,   Description = 'EDI Processed for Fx Blanket Sales Order No: ' + convert(varchar(15), bo.BlanketOrderNo)
from
	@Current862s a
	 Join 
	EDIToyota.BlanketOrders bo on a.CustomerPart = bo.CustomerPart
and
	a.ShipToCode = bo.EDIShipToCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = a.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = a.CustomerModelYear)
	Where
		coalesce(a.newDocument,0) = 1 

union
select
	TradingPartner	= coalesce
		(	(	select
					max(TradingPartner)
				from
					FxEDI.EDI.EDIDocuments
				where
					GUID = a.RawDocumentGUID
			)
		,	''
		)
,	DocumentType = 'PR'
,	AlertType = ' OrderProcessed'
,	ReleaseNo = coalesce(a.ReleaseNo, '')
,	ShipToCode = bo.ShipToCode
,	ConsigneeCode = coalesce(a.ConsigneeCode, '')
,	ShipFromCode = coalesce(a.ShipFromCode, '')
,	CustomerPart = coalesce(a.CustomerPart, '')
,	CustomerPO = coalesce(a.CustomerPO, '')
,	CustomerModelYear = coalesce(a.CustomerModelYear, '')
,	Description = 'EDI Processed for Fx Blanket Sales Order No: ' + convert(varchar(15), bo.BlanketOrderNo)
from
	@Current830s a
	join EDIToyota.BlanketOrders bo
		on a.CustomerPart = bo.CustomerPart
		and
		(	bo.EDIShipToCode = a.ShipToCode
			or bo.MaterialIssuer = a.ShipToCode
		)
		and
		(	bo.CheckCustomerPOPlanning = 0
			or bo.CustomerPO = a.CustomerPO
		)
		and
		(	bo.CheckModelYearPlanning = 0
			or bo.ModelYear830 = a.CustomerModelYear
		)
where
	coalesce(a.NewDocument, 0) = 1
--Accums Reporting -- Commented Toyota does not send Accums
order by 1,2,5,4,7
		

Select	*
into	#EDIAlerts
From	@EDIOrdersAlert

Select	TradingPartner ,
				DocumentType , --'PR - Planning Release; SS - ShipSchedule'
				AlertType ,
				ReleaseNo ,
				ShipToCode,
				ConsigneeCode ,				
				CustomerPart ,
				CustomerPO ,
				Description 
				
into	#EDIAlertsEmail
From	@EDIOrdersAlert

--SELECT * fROM #EDIAlertsEmail

If Exists (Select 1 From #EDIAlerts)

Begin		

		declare
			@html nvarchar(max),
			@EmailTableName sysname  = N'#EDIAlertsEmail'
		
		exec [FT].[usp_TableToHTML]
				@tableName = @Emailtablename			
			,	@html = @html out
			--, @OrderBy = '[AlertType], [TradingPartner],  [DocumentType], [ShipToCode], [CustomerPart]'
		
		declare
			@EmailBody nvarchar(max)
		,	@EmailHeader nvarchar(max) = 'EDI Processing for EDIToyota' 

		select
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody


		exec msdb.dbo.sp_send_dbmail
			@profile_name = 'FxAlerts'-- sysname
	,		@recipients = 'edialerts@aztecmfgcorp.com' -- varchar(max)
	,		@copy_recipients = 'rjohnson@aztecmfgcorp.com;estimpson@fore-thought.com' -- varchar(max)
	, 	@subject = @EmailHeader
	,  	@body = @EmailBody
	,  	@body_format = 'HTML'
	,		@importance = 'High' 
					

Insert [EDIAlerts].[ProcessedReleases]

(	 EDIGroup
	,TradingPartner
	,DocumentType --'PR - Planning Release; SS - ShipSchedule'
	,AlertType 
	,ReleaseNo
	,ShipToCode
	,ConsigneeCode 
	,ShipFromCode 
	,CustomerPart
	,CustomerPO
	,CustomerModelYear
	,Description
)


Select 
	'EDIToyota'
	,*
From
	#EDIAlerts
union
Select
	'EDIToyota'
	,TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'SS'
,	AlertType =  'Exception Quantity Due'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
, Description = 'Qty Due : ' + convert(varchar(max), c.ReleaseQty) + ' on - ' + convert(varchar(max), c.ReleaseDT)
from
	@Current862s a
Join
		EDIToyota.ShipSchedules c
on			c.RawDocumentGUID = a.RawDocumentGUID and
				a.CustomerPart = c.CustomerPart and
				a.ShipToCode =c.ShipToCode and
				coalesce(a.customerPO,'') = coalesce(c.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(c.CustomerModelYear,'')
Where
		coalesce(a.newDocument,0) = 1
and not exists
( Select 1 from 
		EDIToyota.ShipSchedules b
 Join 
	EDIToyota.BlanketOrders bo on b.CustomerPart = bo.CustomerPart
and
	b.ShipToCode = bo.EDIShipToCode
and
(	bo.CheckCustomerPOShipSchedule = 0
	or bo.CustomerPO = b.CustomerPO)
and
(	bo.CheckModelYearShipSchedule = 0
	or bo.ModelYear862 = b.CustomerModelYear)
where
				a.RawDocumentGUID = b.RawDocumentGUID and
				a.CustomerPart = b.CustomerPart and
				a.ShipToCode = b.ShipToCode and
				coalesce(a.customerPO,'') = coalesce(b.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(b.CustomerModelYear,''))

union
Select
	'EDIToyota'
	,TradingPartner = Coalesce((Select max(TradingPartner) from fxEDI.EDI.EDIDocuments where GUID = a.RawDocumentGUID) ,'')
,	DocumentType = 'PR'
,	AlertType =  'Exception Quantity Due'
,	ReleaseNo =  Coalesce(a.ReleaseNo,'')
,	ShipToCode = a.ShipToCode
,	ConsigneeCode =  coalesce(a.ConsigneeCode,'')
,	ShipFromCode = coalesce(a.ShipFromCode,'')
,	CustomerPart = Coalesce(a.CustomerPart,'')
,	CustomerPO = Coalesce(a.CustomerPO,'')
,	CustomerModelYear = Coalesce(a.CustomerModelYear,'')
,  Description = 'Qty Due : ' + convert(varchar(max), c.ReleaseQty) + ' on - ' + convert(varchar(max), c.ReleaseDT)
from
	@Current830s a
Join
		EDIToyota.PlanningReleases c
on			c.RawDocumentGUID = a.RawDocumentGUID and
				a.CustomerPart = c.CustomerPart and
				a.ShipToCode =c.ShipToCode and
				coalesce(a.customerPO,'') = coalesce(c.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(c.CustomerModelYear,'')
Where
		coalesce(a.newDocument,0) = 1
and  not exists
( Select 1 from 
		EDIToyota.PlanningReleases b
 Join 
	EDIToyota.BlanketOrders bo on b.CustomerPart = bo.CustomerPart
and
	b.ShipToCode = bo.EDIShipToCode
and
(	bo.CheckCustomerPOPlanning = 0
	or bo.CustomerPO = b.CustomerPO)
and
(	bo.CheckModelYearPlanning = 0
	or bo.ModelYear830 = b.CustomerModelYear)
where
				a.RawDocumentGUID = b.RawDocumentGUID and
				a.CustomerPart = b.CustomerPart and
				a.ShipToCode = b.ShipToCode and
				coalesce(a.customerPO,'') = coalesce(b.CustomerPO,'') and
				coalesce(a.CustomerModelYear,'') = coalesce(b.CustomerModelYear,''))

					



End
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
	@ProcReturn = EDIToyota.usp_SendProcessEmailNotification
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
