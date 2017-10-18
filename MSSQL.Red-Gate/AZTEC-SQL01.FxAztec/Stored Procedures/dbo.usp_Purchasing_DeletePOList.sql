SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_Purchasing_DeletePOList]
	@User varchar(10)
,	@POList varchar(max)
,	@DeletedReleaseCount int = null out
,	@DeletedPOCount int = null out
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
/*	Parse po list. */
create table #poList
(	PO int
,	RowID int not null IDENTITY(1, 1) primary key
)

insert
	#poList
select
	PO = convert(int, fsstr.value)
from
	dbo.fn_SplitStringToRows(@POList, ',') fsstr
where
	fsstr.Value like '%[0-9]%'
	and fsstr.Value not like '%[^0-9]%'

/*	Quit with error if any POs have an open release. */
--if	exists
--		(	select
--				*
--			from
--				dbo.po_detail pd
--			where
--				pd.po_number in
--					(	select
--							pl.PO
--						from
--							#poList pl
--					)
--				and pd.quantity > coalesce(pd.received, 0)
--		) begin

--	set	@Result = 999999
--	RAISERROR ('Error deleting POs in procedure %s.  One or more of the selected POs have an open release.  Close open releases and try again.', 16, 1, @ProcName)
--	rollback tran @ProcName
--	return
--end

/*	Delete all received releases from the list of POs. */
--- <Delete rows="*">
set	@TableName = 'dbo.po_detail'

delete
	pd
from
	dbo.po_detail pd
where
	pd.po_number in
		(	select
				pl.PO
			from
				#poList pl
		)
	and pd.quantity <= pd.received

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>
set	@DeletedReleaseCount = @RowCount


/*	Delete listed POs. */
--- <Delete rows="*">
set	@TableName = 'dbo.po_header'

delete
	ph
from
	dbo.po_header ph
where
	ph.po_number in
		(	select
				pl.PO
			from
				#poList pl
		)
	and not exists
		(	select
				*
			from
				dbo.po_detail pd
			where
				pd.po_number = ph.po_number
		)

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Delete>
set	@DeletedPOCount = @RowCount
-- </Body>

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
	@ProcReturn = dbo.usp_Purchasing_DeletePOList
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
