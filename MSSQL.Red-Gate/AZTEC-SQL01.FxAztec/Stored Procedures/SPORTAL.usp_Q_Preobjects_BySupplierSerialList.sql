SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [SPORTAL].[usp_Q_Preobjects_BySupplierSerialList]
	@SupplierCode varchar(20)
,	@SerialList varchar(max)
,	@TranDT datetime = null out
,	@Result integer = null out
as
/*
Args:
@SupplierCode - A valid supplier.
@SerialList - Comma separated list of valid pre-object serials associated
	with this supplier.  List may contain spaces between entries and may
	terminate with or without a comma.  All serials in the list must be
	valid.  Examples:
	'1,2,3,4'
	'1, 2, 3, 4'
	'1,2,3,4,'
*/
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

/*	Validate serial list is numeric. */
if	exists
	(	select
			*
		from
			dbo.fn_SplitStringToRows(@SerialList, ',') fsstr
		where
			fsstr.Value like '%[^0-9]%'
	) begin
	set	@Result = 999999
	RAISERROR ('Error:  Non-numeric values in serial list %s in procedure %s', 16, 1, @SerialList, @ProcName)
	--rollback tran @ProcName
	return
end

/*	Validate all serials in list are valid. */
declare
	@Serials table
(	Serial int
)
insert
	@Serials
(	Serial
)
select
	Serial = convert(int, fsstr.Value)
from
	dbo.fn_SplitStringToRows(@SerialList, ',') fsstr
where
	fsstr.Value like '%[0-9]%'

declare
	@InvalidSerialList varchar(max)
select
	@InvalidSerialList = Fx.ToList(s.Serial)
from
	@Serials s
where
	not exists
	(	select
			so.Serial
		from
			SPORTAL.SupplierObjects so
			join SPORTAL.SupplierObjectBatches sob
				on sob.RowID = so.SupplierObjectBatch
		where
			sob.SupplierCode = @SupplierCode
			and so.Serial = s.Serial
			and so.Status = 0
	)

if	@InvalidSerialList > '' begin
	set	@Result = 999999
	RAISERROR ('Error:  Invalid serials in serial list %s in procedure %s', 16, 1, @InvalidSerialList, @ProcName)
	--rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Return pre-objects.*/
select
	so.Serial
,	so.Status
,	so.Type
,	sob.SupplierCode
,	sob.SupplierPartCode
,	sob.InternalPartCode
,	so.Quantity
,	so.LotNumber
,	so.RowCreateDT
,	so.RowModifiedDT
from
	SPORTAL.SupplierObjects so
	join SPORTAL.SupplierObjectBatches sob
		on sob.RowID = so.SupplierObjectBatch
	join @Serials s
		on s.Serial = so.Serial
where
	sob.SupplierCode = @SupplierCode
	and so.Status = 0
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
	@SupplierCode varchar(20) = 'MAR0200'
,	@SerialList varchar(max) = '1,2,3,'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierSerialList
	@SupplierCode = @SupplierCode
,	@SerialList = @SerialList
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
