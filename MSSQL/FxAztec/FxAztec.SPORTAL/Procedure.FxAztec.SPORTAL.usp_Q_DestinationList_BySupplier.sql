
/*
Create Procedure.FxAztec.SPORTAL.usp_Q_DestinationList_BySupplier.sql
*/

use FxAztec
go

--if	objectproperty(object_id('SPORTAL.usp_Q_DestinationList_BySupplier'), 'IsProcedure') = 1 begin
--	drop procedure SPORTAL.usp_Q_DestinationList_BySupplier
--end
--go

--create procedure SPORTAL.usp_Q_DestinationList_BySupplier
alter procedure SPORTAL.usp_Q_DestinationList_BySupplier
	@SupplierCode varchar(10)
as
begin
	set nocount on

	begin try
		begin transaction
		select ' ' as Destination
		union all
		select distinct
			d.destination as Destination
		--,	xrt.TopPart
		--,	xrt.ChildPart
		from
			FT.XRt xrt
			join dbo.part_vendor pv
				join dbo.destination dV
					on dV.vendor = pv.vendor
				on xrt.ChildPart = pv.part
				and dV.destination = @SupplierCode
			join dbo.po_header ph
				on xrt.TopPart = ph.blanket_part
			join dbo.destination d on
				d.vendor = ph.vendor_code
		where xrt.ChildPart in
			(	select
					ph.blanket_part
				from
					dbo.po_header ph
					join dbo.destination d
						on d.vendor = ph.vendor_code
				where
					d.destination = @SupplierCode
			)
			and xrt.BOMLevel = 1
		order by
			Destination

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch
end
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
	@SupplierCode varchar(10)

set	@SupplierCode = 'HIB0010'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_DestinationList_BySupplier
	@SupplierCode = @SupplierCode

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

