SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_Surcharge_GetBlanketPrice]
	@Part varchar(25)
,	@Vendor varchar(25)
,	@OrderQty numeric(20,6) = null
,	@BlanketPrice numeric(20,6) out
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
	@BlanketPrice = coalesce
		(	ppvp.BaseBlanketPrice
		,	(	select top 1
		 			pvpm.price
		 		from
		 			dbo.part_vendor_price_matrix pvpm
				where
					pvpm.part = @Part
					and pvpm.vendor = @Vendor
					and pvpm.break_qty >= @OrderQty
				order by
					pvpm.break_qty desc
		 	)
		,	(	select top 1
		 			pvpm.price
		 		from
		 			dbo.part_vendor_price_matrix pvpm
				where
					pvpm.part = @Part
					and pvpm.vendor = @Vendor
				order by
					pvpm.break_qty desc
		 	)
		)
from
	dbo.PartPurchasing_VendorPrice ppvp
where
	ppvp.PartCode = @Part
	and ppvp.VendorCode = @Vendor
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
	@ProcReturn = dbo.usp_Surcharge_GetBlanketPrice
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
