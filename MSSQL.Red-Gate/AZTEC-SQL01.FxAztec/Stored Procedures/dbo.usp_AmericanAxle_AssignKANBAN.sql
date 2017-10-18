SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[usp_AmericanAxle_AssignKANBAN]
	@serial int
,	@tranDT datetime = null out
,	@result integer = null out
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
/*	Object serial must be staged to a shipper. */
if	not exists
	(	select
			*
		from
			dbo.object o
		where
			serial = @serial
			and o.shipper > 0
	) begin
	
	set	@Result = 999999
	RAISERROR ('Error assigning KANBAN to serial %d.  This serial must be staged to a shipper.', 16, 1, @serial)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
declare
	@shipperID int
,	@partCode varchar(25)

select
	@shipperID = o.shipper
,	@partCode = o.part
from
	dbo.object o
where
	serial = @serial

/*	Get all open releases for the order related to this shipper line. */

declare
	@openReleases table
(	ID int not null IDENTITY(1, 1) primary key
,	OrderNo int
,	PartCode varchar(25)
,	StdQty numeric(20,6)
,	ReleaseNo varchar(30)
,	AARelase char(4)
,	AAOrderID char(8)
,	AAKANBAN char(6)
,	PriorOrderAccum numeric(20,6)
,	PostOrderAccum numeric(20,6)
,	PriorShipperAccum numeric(20,6)
,	PostShipperAccum numeric(20,6)
,	PriorNettedAccum numeric(20,6)
,	PostNettedAccum numeric(20,6)
,	NetQtyRequired numeric(20,6)
,	LabelledQty numeric(20,6)
)

insert
	@openReleases
(	OrderNo
,	PartCode
,	StdQty
,	ReleaseNo
,	AARelase
,	AAOrderID
,	AAKANBAN
)
select
	OrderNo = od.order_no
,	PartCode = od.part_number
,	StdQty = od.std_qty
,	ReleaseNo = od.release_no
,	AARelease = dbo.fn_SplitStringToArray(od.release_no, '_', 1)
,	AAOrderId = dbo.fn_SplitStringToArray(od.release_no, '_', 2)
,	AAKANBAN = dbo.fn_SplitStringToArray(od.release_no, '_', 3)
from
	dbo.shipper_detail sd
	join dbo.order_detail od
		on od.order_no = sd.order_no
		and od.part_number = sd.part_original
		and od.release_no like '%[_]%[_]%'
where
	sd.shipper = @shipperID
	and sd.part_original = @partCode
order by
	od.due_date,
	substring(od.release_no,6,30)
	

/*	Get all open shippers (in ship date/time order) for these releases. */
declare
	@openShippers table
(	ID int not null IDENTITY(1, 1) primary key
,	ShipperID int
,	StdQty numeric(20,6)
,	PriorAccum numeric(20,6)
,	PostAccum numeric(20,6)
)

insert
	@openShippers
(	ShipperID
,	StdQty
)
select
	ShipperID = sd.shipper
,	StdQty = sd.qty_required
from
	dbo.shipper_detail sd
	join dbo.shipper sOpen
		on sOpen.id = sd.shipper
		and sOpen.status in ('O', 'A', 'S')
where
	sd.order_no = (select max(OrderNo) from @openReleases)
	and coalesce(sOpen.type,'X') != 'R'
order by
	dbo.fn_DateTime(sOpen.date_stamp, sOpen.scheduled_ship_time)
,	sd.shipper

update
	os
set	PriorAccum = coalesce
	(	(	select
				sum(os1.StdQty)
			from
				@openShippers os1
			where
				os1.ID < os.ID
		)
	,	0
	)
,	PostAccum = coalesce
	(	(	select
				sum(os1.StdQty)
			from
				@openShippers os1
			where
				os1.ID <= os.ID
		)
	,	0
	)
from
	@openShippers os

/*	Get all inventory staged to this shipper grouped by release.*/
declare
	@stagedInventory table
(	ID int not null IDENTITY(1, 1) primary key
,	ReleaseNo varchar(30)
,	StdQty numeric(20,6)
,	PriorAccum numeric(20,6)
,	PostAccum numeric(20,6)
)

insert
	@stagedInventory
(	ReleaseNo
,	StdQty
)
select
	ReleaseNo =
		case
			when o.serial = @serial then null
			else o.custom4 + '_' + o.custom5 + '_' + nullif(rtrim(o.kanban_number), '')
		end
,	StdQty = sum(o.std_quantity)
from
	dbo.object o
where
	o.shipper = @shipperID
	and o.part = @partCode
group by
		case
			when o.serial = @serial then null
			else o.custom4 + '_' + o.custom5 + '_' + nullif(rtrim(o.kanban_number), '')
		end

update
	si
set	PriorAccum = coalesce
	(	(	select
				sum(si1.StdQty)
			from
				@stagedInventory si1
			where
				si1.ID < si.ID
		)
	,	0
	)
,	PostAccum = coalesce
	(	(	select
				sum(si1.StdQty)
			from
				@stagedInventory si1
			where
				si1.ID <= si.ID
		)
	,	0
	)
from
	@stagedInventory si

/*	Calculate the first release with unmet labelled inventory...*/
/*		First, calculate the prior/post accum for open releases.*/
update
	[or]
set	PriorOrderAccum = coalesce
	(	(	select
				sum(or1.StdQty)
			from
				@openReleases or1
			where
				or1.ID < [or].ID
		)
	,	0
	)
,	PostOrderAccum = coalesce
	(	(	select
				sum(or1.StdQty)
			from
				@openReleases or1
			where
				or1.ID <= [or].ID
		)
	,	0
	)
from
	@openReleases [or]

/*		Get the prior/post accum for this shipment based on ship date/time order.*/
update
	[or]
set	PriorShipperAccum = os.PriorAccum
,	PostShipperAccum = os.PostAccum
from
	@openReleases [or]
	join @openShippers os
		on os.ShipperID = @shipperID

/*		Net shipment accums against release accums to determine releases that belong to this shipment.*/
update
	[or]
set	PriorNettedAccum =
		case
			when [or].PriorOrderAccum > [or].PriorShipperAccum then [or].PriorOrderAccum
			else [or].PriorShipperAccum
		end
,	PostNettedAccum =
		case
			when [or].PostOrderAccum < [or].PostShipperAccum then [or].PostOrderAccum
			else [or].PostShipperAccum
		end
from
	@openReleases [or]

/*		Calculate acutal net release requirements for this shipment.*/
update
	[or]
set NetQtyRequired =
		case
			when [or].PostNettedAccum > [or].PriorNettedAccum then [or].PostNettedAccum - [or].PriorNettedAccum
			else 0
		end
from
	@openReleases [or]

/*		Apply inventory already labelled for this shipment.*/
update
	[or]
set LabelledQty = coalesce(si.StdQty, 0)
from
	@openReleases [or]
	left join @stagedInventory si
		on si.ReleaseNo = [or].ReleaseNo

/*	Get the KANBAN information for the first release with unmet labelled inventory.*/
declare
	@SalesOrderNo int
,	@AARelease char(4)
,	@AAOrderID char(8)
,	@AAKANBAN char(6)

select
	@SalesOrderNo = [or].OrderNo
,	@AARelease = [or].AARelase
,	@AAOrderID = [or].AAOrderID
,	@AAKANBAN = [or].AAKANBAN
from
	@openReleases [or]
where
	[or].ID =
		(	select
				min(ID)
			from
				@openReleases or1
			where
				or1.NetQtyRequired > or1.LabelledQty
		)

if	@AAKANBAN is null begin
	
	set	@Result = 999999
	RAISERROR ('Error finding KANBAN for serial %d.  Unable to find an open release.', 16, 1, @serial)
	rollback tran @ProcName
	return
end

/*	Assign KANBAN to object if not already assigned.*/
if	not exists
	(	select
			*
		from
			dbo.object o
		where
			serial = @serial
			and custom4 = @AARelease
			and custom5 = @AAOrderID
			and kanban_number = @AAKANBAN
	) begin
	
	/*	Add object quantity back to previously assigned order KANBAN.*/
	--- <Update rows="*">
	set	@TableName = 'dbo.kanban'
	
	update
		k
	set
		standard_quantity = k.standard_quantity + o.std_quantity
	from
		dbo.kanban k
		join dbo.object o
			on o.serial = @serial
	where
		k.order_no = @SalesOrderNo
		and k.kanban_number = o.kanban_number
		and k.line16 = o.custom4
		and k.line17 = o.custom5
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Update>
	
	/*	Update object.*/
	--- <Update rows="1">
	set	@TableName = 'dbo.object'

	update
		o
	set
		custom4 = @AARelease
	,	custom5 = @AAOrderID
	,	kanban_number = @AAKANBAN
	from
		dbo.object o
	where
		serial = @serial

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
	
	/*	Deduct object quantity from order KANBAN.*/
	--- <Update rows="*">
	set	@TableName = 'dbo.kanban'
	
	update
		k
	set
		standard_quantity = k.standard_quantity - o.std_quantity
	from
		dbo.kanban k
		join dbo.object o
			on o.serial = @serial
	where
		k.order_no = @SalesOrderNo
		and k.kanban_number = @AAKANBAN
		and k.line16 = @AARelease
		and k.line17 = @AAOrderID
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Update>
end
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
	@serial int

set	@serial = 1302688

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_AmericanAxle_AssignKANBAN
	@serial = @serial
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.object
where
	serial = @serial
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
