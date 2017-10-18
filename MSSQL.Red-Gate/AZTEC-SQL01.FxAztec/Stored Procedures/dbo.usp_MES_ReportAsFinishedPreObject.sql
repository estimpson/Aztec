SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_ReportAsFinishedPreObject]
	@Operator varchar (10)
,	@PreObjectSerial int
,	@TranDT datetime out
,	@Result int out
as
set nocount on
set	@Result = 999999

----<Tran Required=Yes AutoCreate=Yes>
--declare	@TranCount smallint
--set	@TranCount = @@TranCount
--if	@TranCount = 0 begin
--	begin transaction JCPreObject
--end
--else begin
--	save transaction JCPreObject
--end
--set @TranDT = coalesce(@TranDT, getdate())
----</Tran>

----<Error Handling>
--declare
--	@ProcReturn integer,
--	@ProcResult integer,
--	@Error integer,
--	@RowCount integer
----</Error Handling>

----	Argument Validation:
----		Operator required:
--if	not exists
--	(	select	1
--		from	employee
--		where	operator_code = @Operator) begin

--	set	@Result = 60001
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, @Operator)
--	return	@Result
--end

--if	coalesce (
--	(	select	max (part)
--		from	audit_trail
--		where	serial = @PreObjectSerial), '') = 'PALLET' begin
--		set	@Result = 0
--	rollback tran JCPreObject
--	return	@Result
--end

----		WOD ID must be valid:
--declare	@WODID int, @Part varchar(25)
--select	@WODID = WODID, @Part = Part
--from	FT.PreObjectHistory
--where	Serial = @PreObjectSerial
----if	not exists
----	(	select	1
----		from	WODetails
----		where	ID = @WODID) begin
	
----	set	@Result = 200101
----	rollback tran JCPreObject
----	RAISERROR (@Result, 16, 1, @WODID)
----	return	@Result
----end

----if	not exists
----	(	select	1
----		from	WODetails
----		where	ID = @WODID) begin
			
----	set	@Result = 200101
----	rollback tran JCPreObject
----	RAISERROR (@Result, 16, 1, @WODID)
----	return	@Result
----end

--update	FT.PreObjectHistory
--set		WODID = @WODID
--where	Serial = @PreObjectSerial

--declare	@Machine varchar (10)
----select	@Machine = WOHeaders.Machine
----from	WODetails
----	join WOHeaders on WODetails.WOID = WOHeaders.ID
----where	WODetails.ID = @WODID

----		Quantity must be valid:
--declare	@QtyRequested numeric (20,6)
--select	@QtyRequested = Quantity
--from	FT.PreObjectHistory
--where	Serial = @PreObjectSerial
--if	not coalesce (@QtyRequested, 0) > 0 begin
--	set	@Result = 202001
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, @QtyRequested)
--	return	@Result
--end

--if	exists
--	(	select	1
--		from	location
--		where	code = @Machine and
--			group_no = 'INVENTARIO') begin
--	set	@Result = 100033
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, @PreObjectSerial)
--	return	@Result
--end


----		Serial must be a Pre-Object:
--if	not exists
--	(	select	1
--		from	FT.PreObjectHistory
--		where	Serial = @PreObjectSerial) begin
--	set	@Result = 100101
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, @PreObjectSerial)
--	return	@Result
--end

----		If PreObject has already been Job Completed, do nothing:
--if	exists
--	(	select	1
--		from	audit_trail
--		where	type = 'J' and
--			serial = @PreObjectSerial) begin
----	set	@Result = 100100
--	set	@Result = 0
--	rollback tran JCPreObject
----	RAISERROR (@Result, 10, 1, @PreObjectSerial)
--	return	@Result
--end

----	I.	If this box has been deleted, recreate it.
----if	not exists
----	(	select	1
----		from	object
----		where	serial = @PreObjectSerial) begin

--	--insert
--	--	dbo.object
--	--(	serial
--	--,	part
--	--,	location
--	--,	last_date
--	--,	unit_measure
--	--,	operator
--	--,	status
--	--,	quantity
--	--,	plant
--	--,	std_quantity
--	--,	last_time
--	--,	user_defined_status
--	--,	type
--	--,	po_number 
--	--)
--	--select
--	--	poh.Serial
--	--,   poh.part
--	--,   location = FT.fn_VarcharGlobal ('AssemblyPreObject')
--	--,   poh.CreateDT
--	--,   (select standard_unit from part_inventory where part = poh.Part)
--	--,   @Operator
--	--,   'H'
--	--,   poh.Quantity
--	--,   (select plant from location where code = FT.fn_VarcharGlobal ('AssemblyPreObject'))
--	--,   poh.Quantity
--	--,   poh.CreateDT
--	--,   'PRESTOCK'
--	--,   null
--	--,   null
--	--from
--	--	FT.PreObjectHistory poh
--	--where
--	--	poh.Serial = @PreObjectSerial
----end

--select	@Part = part
--from	object
--where	serial = @PreObjectSerial 

----	    bom of the part must be complete
--if	not exists (select	1
--		from	part
--		where	class = 'M'
--			and part = @Part) begin
--	set	@Result = 70102
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, @Part)
--	return	@Result			                          	
--end


----	II.	Write job complete.
----		A.	Set status on Pre-Object History.
--update	FT.PreObjectHistory
--set	Status = Status | 2 -- Change to a constant.
--where	Serial = @PreObjectSerial

--set	@Error = @@Error
--set	@RowCount = @@Rowcount

--if	@Error != 0 begin
--	set	@Result = 999999
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@RowCount != 1 begin
--	set	@Result = 999999
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	return	@Result
--end

----		B.	Update object.
--update	object
--set	status = 'A',
--	user_defined_status = 'Approved',
--	last_date = @TranDT,
--	last_time = @TranDT,
--	location = @Machine,
--	plant = (select plant from location where code = @Machine),
--	operator = @Operator,
--	workorder = @WODID,
--	cost = (select cost_cum from dbo.part_standard where part = object.part),
--	std_cost = (select cost_cum from dbo.part_standard where part = object.part)
--where	serial = @PreObjectSerial

--set	@Error = @@Error
--set	@RowCount = @@Rowcount

--if	@Error != 0 begin
--	set	@Result = 999999
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@RowCount != 1 begin
--	set	@Result = 999999
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	return	@Result
--end

----		C.	Update part_online.
--update	part_online
--set	on_hand =
--	(	select	sum (std_quantity)
--		from	object
--		where	part = part_online.part and
--			status = 'A')
--from	part_online
--	join object on part_online.part = object.part
--where	object.serial = @PreObjectSerial

--set	@Error = @@Error
--set	@RowCount = @@Rowcount

--if	@Error != 0 begin
--	set	@Result = 999999
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@RowCount != 1 begin
--	insert	part_online
--	(	part, on_hand)
--	select	part = part,
--		on_hand = sum (std_quantity)
--	from	object
--	where	part =
--		(	select	part
--			from	object
--			where	serial = @PreObjectSerial) and
--		status = 'A'
--	group by
--		part
	
--	set	@Error = @@Error
--	set	@RowCount = @@Rowcount
	
--	if	@Error != 0 begin
--		set	@Result = 999999
--		RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--		rollback tran JCPreObject
--		return	@Result
--	end
--	if	@RowCount != 1 begin
--		set	@Result = 999999
--		rollback tran JCPreObject
--		RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--		return	@Result
--	end
--end

----		D.	Create back flush header.
--declare	@NewBackflushNumber varchar(50)

----insert
----	BackFlushHeaders
----(	TranDT,
----	WODID,
----	PartProduced,
----	SerialProduced,
----	QtyProduced)
----select
----	@TranDT,
----	ID,
----	Part,
----	@PreObjectSerial,
----	@QtyRequested
----from	WODetails
----where	ID = @WODID

--set	@NewBackflushNumber =
--	(	select
--			bh.BackflushNumber
--		from
--			dbo.BackflushHeaders bh
--		where
--			bh.RowID = SCOPE_IDENTITY ()
--	)

----		E.	Insert audit_trail.
--insert	audit_trail
--(	serial, date_stamp, type, part, quantity, remarks, price,
--	operator, from_loc, to_loc, on_hand, lot, weight, status, unit,
--	workorder, std_quantity, cost, custom1, custom2, custom3,
--	custom4, custom5, plant, notes, gl_account, std_cost,
--	group_no, user_defined_status, part_name, tare_weight)
--select	serial = object.serial, date_stamp = @TranDT, type = 'J', part = object.part,
--	quantity = object.quantity, remarks = 'Job comp', price = 0,
--	operator = object.operator, from_loc = object.location, to_loc = object.location,
--	on_hand = IsNull (part_online.on_hand, 0) +
--	(	case	when object.status = 'A' then object.std_quantity
--			else 0
--		end), lot = object.lot, weight = object.weight,
--	status = object.status, unit = object.unit_measure,
--	workorder = object.workorder, std_quantity = object.std_quantity, cost = object.cost,
--	custom1 = object.custom1, custom2 = object.custom2, custom3 = object.custom3,
--	custom4 = object.custom4, custom5 = object.custom5, plant = object.plant,
--	notes = '', gl_account = '', std_cost = object.cost,
--	group_no = @NewBackflushNumber, user_defined_status = object.user_defined_status, part_name = object.name, tare_weight = object.tare_weight
--from	object
--	left outer join part_online on object.part = part_online.part
--	join part on object.part = part.part
--where	object.serial = @PreObjectSerial

--set	@Error = @@Error
--set	@RowCount = @@Rowcount

--if	@Error != 0 begin
--	set	@Result = 999999
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@RowCount != 1 begin
--	set	@Result = 999999
--	rollback tran JCPreObject
--	RAISERROR (@Result, 16, 1, 'ProdControl_JCPreObject')
--	return	@Result
--end

----	III.	Perform back flush.
----		B.	Execute back flush details.
--execute @ProcReturn = dbo.usp_MES_BackFlush
--	@Operator = @Operator
--,	@BackflushNumber = @NewBackflushNumber
--,	@TranDT = @TranDT out
--,	@Result = @ProcResult out

--set	@Error = @@Error
--if	@ProcResult != 0 begin
--	set	@Result = 999999
--	RAISERROR ('An error result was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@ProcReturn != 0 begin
--	set	@Result = 999999
--	RAISERROR ('An error was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
--	rollback tran JCPreObject
--	return	@Result
--end
--if	@Error != 0 begin
--	set	@Result = 999999
--	RAISERROR ('An error occurred during the execution of the procedure %s', 16, 1, 'ProdControl_BackFlush')
--	rollback tran JCPreObject
--	return	@Result
--end

----	IV.	Update workorder.
----update	WODetails
----set	QtyCompleted = QtyCompleted + @QtyRequested
----where	ID = @WODID

----<CloseTran Required=Yes AutoCreate=Yes>
--if	@TranCount = 0 begin
--	commit transaction JCPreObject
--end
----</CloseTran Required=Yes AutoCreate=Yes>

--	V.	Success.
set	@Result = 0
return	@Result

/*
select
	*
from
	FT.PreObjectHistory poh
where
	WODID = 7

begin transaction
go

declare
    @ProcResult int
,   @ProcReturn int
,   @Operator varchar(10)
,   @PreObjectSerial int
,	@TranDT datetime

set	@Operator = 'ES'
set	@PreObjectSerial = 791622

execute @ProcReturn = dbo.usp_MES_ReportAsFinishedPreObject 
    @Operator = @Operator
,   @PreObjectSerial = @PreObjectSerial
,	@TranDT = @TranDT out
,   @Result = @ProcResult out

select
    @ProcResult
,   @PreObjectSerial
,   @ProcReturn
,	@TranDT

select
    *
from
    BackFlushHeaders
where
    SerialProduced = @PreObjectSerial

select
    BackFlushDetails.*
from
    BackFlushDetails
    join BackFlushHeaders
        on BackFlushHeaders.ID = BackFlushDetails.BFID
where
    SerialProduced = @PreObjectSerial

select
    *
from
    audit_trail
where
    date_stamp = @TranDT

select	*
from	audit_trail
where	date_stamp >= DateAdd (n, -1, getdate()) and
	serial in
	(	select	SerialConsumed
		from	BackFlushDetails
			join BackFlushHeaders on BackFlushHeaders.ID = BackFlushDetails.BFID
		where	SerialProduced = @PreObjectSerial)

select
    *
from
    object
where
    serial = @PreObjectSerial

select
    *
from
    object
where
    serial in
    (	select
			SerialConsumed
		from
			BackFlushDetails
			join BackFlushHeaders
				on BackFlushHeaders.ID = BackFlushDetails.BFID
		where
			SerialProduced = @PreObjectSerial
	)
go

rollback
go

*/
GO
