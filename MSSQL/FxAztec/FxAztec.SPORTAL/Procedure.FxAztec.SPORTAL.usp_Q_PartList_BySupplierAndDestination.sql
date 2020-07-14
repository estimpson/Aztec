
/*
Create Procedure.FxAztec.SPORTAL.usp_Q_PartList_BySupplierAndDestination.sql
*/

use FxAztec
go

--if	objectproperty(object_id('SPORTAL.usp_Q_PartList_BySupplierAndDestination'), 'IsProcedure') = 1 begin
--	drop procedure SPORTAL.usp_Q_PartList_BySupplierAndDestination
--end
--go

--create procedure SPORTAL.usp_Q_PartList_BySupplierAndDestination
alter procedure SPORTAL.usp_Q_PartList_BySupplierAndDestination
	@SupplierCode varchar(20)
,	@Destination varchar(20)
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SPORTAL.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=Yes>
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
/*	Validate supplier code. */
if	not exists
	(	select
			*
		from
			SPORTAL.SupplierList sl
		where
			sl.SupplierCode = @SupplierCode
			and sl.Status = 0
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid supplier code %s in procedure %s', 16, 1, @SupplierCode, @ProcName)
	--rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Return part list for this supplier. */
select
	spl.SupplierCode
,	spl.SupplierName
,	spl.SupplierPartCode
,	spl.Status
,	spl.SupplierStdPack
,	spl.InternalPartCode
,	spl.Decription
,	spl.PartClass
,	spl.PartSubClass
,	spl.HasBlanketPO
,	spl.LabelFormatName
,	spo.PONumber
from
	SPORTAL.SupplierPartList spl
	cross apply
		(	select top (1)
				PONumber = ph.po_number
			from
				dbo.po_header ph
				join dbo.destination d
					on d.vendor = ph.vendor_code
			where
				ph.blanket_part = spl.InternalPartCode
				and d.destination = @SupplierCode
				and ph.ship_to_destination = @Destination
			order by
				ph.po_number desc		
		) spo
where
	spl.SupplierCode = @SupplierCode
	and spl.Status = 0
order by
	spl.SupplierPartCode
--- </Body>

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
	@SupplierCode varchar(20) = 'HIB0010'
,	@Destination varchar(20) = 'MID0010'

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_PartList_BySupplierAndDestination
	@SupplierCode = @SupplierCode
,	@Destination = @Destination
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
go


exec SPORTAL.usp_Q_PartList_BySupplierAndDestination
	@SupplierCode = 'ROC0010'
,	@Destination = 'MID0010'