SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[usp_UpdateShipToDimensions]
	@TranDT datetime out
,	@Result integer out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>



/* clear table */
truncate table EDI.ShipToDimensions

--- <Insert>
set	@TableName = 'EDI.ShipToDimensions'
insert 
	EDI.ShipToDimensions
(	ShipToAddress
,	ShipToCode
,	ShipToName
,	BillToCode
,	BillToName
,	EDIOperatorCode
,	EDIOverlayGroup
,	ParentShipTo
,	PoolCode
,	PoolFlag
,	TradingPartnerCode
,	SupplierCode
)
select
	ShipToAddress = 'SHIP_TO+' + d.destination
,	ShipToCode = d.destination --could be a field in edi_setups if not using customer's shipto code as destination code.
,	ShipToName = d.name
,	BillToCode = c.customer
,	BillToName = c.name
,	EDIOperatorCode = coalesce(d.scheduler, c.salesrep, 'N/S')
,	EDIOverlayGroup = es.asn_overlay_group
,	ParentShipTo = es.parent_destination
,	PoolCode = es.pool_code
,	PoolFlag = coalesce(es.pool_flag, null)
,	TradingPartnerCode = es.trading_partner_code
,	SupplierCode = es.supplier_code
from
	fxAztec_Test.dbo.destination d
	join fxAztec_Test.dbo.edi_setups es on
		d.destination = es.destination
	join fxAztec_Test.dbo.customer c on
		d.customer = c.customer

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



--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>



GO
