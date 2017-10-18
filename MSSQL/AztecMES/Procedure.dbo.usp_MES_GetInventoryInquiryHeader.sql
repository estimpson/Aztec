
/*
Create procedure fx21st.dbo.usp_MES_GetInventoryInquiryHeader
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_GetInventoryInquiryHeader'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_GetInventoryInquiryHeader
end
go

create procedure dbo.usp_MES_GetInventoryInquiryHeader
	@Serial int
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

select
	distinct
	InventoryStatus
,	PartCode
,	PartDescription
,	LocationCode
,	Qty
,	Unit
,	Status
from	 
	 dbo.fn_MES_InventoryInquiry(@Serial)
--- </Body>

---	<Return>
if	@TranCount = 0 begin
	commit tran @ProcName
end
set	@Result = 0
return
	@Result
--- </Return>

GO
