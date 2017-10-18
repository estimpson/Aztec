SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_Shipping_QRCL_ChangeQtyRequired]
	@Operator varchar(5)
,	@ShipperID int
,	@ShipperPart varchar(35)
,	@NewQtyRequired numeric(20,6)
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings off

--- <SP Begin Logging>
declare
	@tranCountEntry int = @@TRANCOUNT
if	@tranCountEntry > 0 begin
	rollback
end

declare
	@LogID int

insert
	FxSYS.USP_Calls
(	USP_Name
,	BeginDT
,	InArguments
)
select
	USP_Name = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
,	BeginDT = getdate()
,	InArguments =
		'@Operator = ' + coalesce('''' + @Operator + '''', '<null>')
		+ ', @ShipperID = ' + coalesce(convert(varchar, @ShipperID), '<null>')
		+ ', @ShipperPart = ' + coalesce('''' + @ShipperPart + '''', '<null>')
		+ ', @NewQtyRequired = ' + coalesce(convert(varchar, @NewQtyRequired), '<null>')
		+ ', @TranDT = ' + coalesce(convert(varchar, @TranDT, 121), '<null>')
		+ ', @Result = ' + coalesce(convert(varchar, @Result), '<null>')

set	@LogID = scope_identity()

while
	@tranCountEntry > @@TRANCOUNT begin
	begin transaction
end
--- </SP Begin Logging>

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
--- <Insert rows="1">
set	@TableName = 'dbo.Shipping_QRCL_ChangeLog'

insert
	dbo.Shipping_QRCL_ChangeLog
(	Operator
,	ShipperID
,	ShipperPart
,	QtyRequiredOld
,	QtyRequiredNew
)
select
	Operator = @Operator
,	ShipperID = @ShipperID
,	ShipperPart = @ShipperPart
,	QtyRequiredOld = sd.qty_required
,	QtyRequiredNew = @NewQtyRequired
from
	dbo.shipper_detail sd
where
	sd.shipper = @ShipperID
	and sd.part = @ShipperPart

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

if	@NewQtyRequired > 0 begin
	--- <Update rows="1">
	set	@TableName = 'dbo.shipper_detail'

	update
		sd
	set
		qty_required = @NewQtyRequired
	from
		dbo.shipper_detail sd
	where
		sd.shipper = @ShipperID
		and sd.part = @ShipperPart

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Update>
end
else
if	not exists
		(	select
				*
			from
				dbo.object o
				join dbo.shipper_detail sd
					on sd.shipper = o.shipper
					and o.part = sd.part_original
					and coalesce(o.suffix, -1) = coalesce(sd.suffix, -1)
			where
				sd.shipper = @ShipperID
				and sd.part = @ShipperPart
		) begin

	--- <Delete rows="1">
	set	@TableName = 'dbo.shipper_detail'
	
	delete
		sd
	from
		dbo.shipper_detail sd
	where
		sd.shipper = @ShipperID
		and sd.part = @ShipperPart
	
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end
else begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  The shipper has inventory staged to this line.  Unstage the selected part and try again.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

--- <SP End Logging>
update
	uc
set
	EndDT = getdate()
,	OutArguments =
		'@TranDT = ' + coalesce(convert(varchar, @TranDT, 121), '<null>')
		+ ', @Result = ' + coalesce(convert(varchar, @Result), '<null>')
from
	FXSYS.USP_Calls uc
where
	RowID = @LogID
--- </SP End Logging>

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
	@ProcReturn = dbo.usp_Shipping_QRCL_ChangeQtyRequired
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
