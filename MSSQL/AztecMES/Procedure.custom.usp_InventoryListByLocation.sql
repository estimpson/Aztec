
/*
Create procedure fx21st.custom.usp_InventoryListByLocation
*/

--use fx21st
--go
use fxAztec
go
 
if	objectproperty(object_id('custom.usp_InventoryListByLocation'), 'IsProcedure') = 1 begin
	drop procedure custom.usp_InventoryListByLocation
end
go

create procedure custom.usp_InventoryListByLocation
	@InventoryDate datetime
as
set nocount on
set ansi_warnings off

--- <Body>
select
	object.ObjectSerial,
	part.name,
	object.LocationCode,
	object.LastOperatorCode,
	object.StdQty,
	part.part,
	location.plant,
	part.cross_ref,
	object.ShortStatus
from
	(	select
			*
		from
			FT.ObjectHistory oh
		where
			oh.RowCreateDT <= @InventoryDate
			and oh.RowID =
			(	select
					max(oh2.RowID)
				from
					FT.ObjectHistory oh2
				where
					oh2.RowCreateDT <= @InventoryDate
					and oh2.ObjectSerial = oh.ObjectSerial
			)
			and oh.Type != -1
	) object
	right outer join part on object.PartCode = part.part
	left outer join location on object.LocationCode = location.code
where
	object.LocationCode != 'PRE-OBJECT'
--- </Body>

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
	@ProcReturn = custom.usp_InventoryListByLocation
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
go

