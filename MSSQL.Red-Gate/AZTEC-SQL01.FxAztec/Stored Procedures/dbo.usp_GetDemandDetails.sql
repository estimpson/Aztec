SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_GetDemandDetails]
	@RawPart varchar(25)
as
/*
Example:
Initial queries {
}

Test syntax {
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
	@ProcReturn = dbo.usp_GetDemandDetails
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

rollback
go

}

Results {
}
*/
--SET QUOTED_IDENTIFIER ON|OFF
--SET ANSI_NULLS ON|OFF
set nocount on
set ansi_warnings off

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

--- <Tran Required=No AutoCreate=No TranDTParm=No>
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
select
	rawMPS.OrderNo
,	Sequence = vs.Sequence
,	Part = finMPS.PartCode
,	Description = part.name
,	finMPS.ReleaseDT
,	OrderQty = finMPS.GrossQty
,	AvailFIN = finMPS.OnHandQty
,	AvailWIP = convert (numeric (20,6), rawMPS.WIPQty * finMPS.GrossQty / rawMPS.GrossQty - finMPS.OnHandQty)
,	AvailRaw = convert (numeric (20,6), rawMPS.OnHandQty * finMPS.GrossQty / rawMPS.GrossQty )
,	NetQty = convert (numeric (20,6), rawMPS.RequiredQty * finMPS.GrossQty / rawMPS.GrossQty )
,	Unit = part_inventory.standard_unit
,	vs.ShipToCode
,	vs.ShipToName
,	vs.BillToCode
,	vs.BillToName
from
	FT.vwNetMPS rawMPS
	join FT.vwNetMPS finMPS on
		finMPS.OrderNo = rawMPS.OrderNo and finMPS.LineID = rawMPS.LineID and
		finMPS.Sequence = 0
	left outer join FT.vwSOD vs on rawMPS.OrderNo = vs.OrderNo and
		rawMPS.LineID = vs.LineID
	join dbo.part on finMPS.PartCode = part.part
	join dbo.part_inventory on finMPS.PartCode = part_inventory.part
where
	rawMPS.PartCode = @RawPart
order by
	vs.ShipDT,
	rawMPS.OrderNo

--- </Body>
GO
