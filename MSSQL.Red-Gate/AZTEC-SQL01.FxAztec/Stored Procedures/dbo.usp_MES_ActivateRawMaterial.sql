SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[usp_MES_ActivateRawMaterial]
	@Operator varchar(5)
,	@Serial int
,	@TranDT datetime out
,	@Result integer out
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
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>
---	</ArgumentValidation>


--- <Body>
/*	Recreate object if necessary. */
if	not exists
	(	select
			*
		from
			dbo.object o
		where
			serial = @Serial
	) begin

	--- <Insert>
	set	@TableName = 'dbo.object'

	insert
		object
	(	serial, part, lot, location
	,	last_date, unit_measure, operator
	,	status
	,	origin, cost, note, po_number
	,	name, plant, quantity, last_time
	,	package_type, std_quantity
	,	custom1, custom2, custom3, custom4, custom5
	,	user_defined_status
	,	std_cost, field1)
	select
		@Serial, atLastTrans.part, atLastTrans.lot, atLastTrans.to_loc
	,	@TranDT, atLastTrans.unit, @Operator
	,	'A'
	,	atLastTrans.shipper, atLastTrans.cost, null /*note*/, atLastTrans.po_number
	,	atLastTrans.part_name, atLastTrans.plant, case when atLastTrans.type = 'R' then atLastTrans.quantity else 0 end, @TranDT
	,	atLastTrans.package_type, case when atLastTrans.type = 'R' then atLastTrans.std_quantity else 0 end
	,	null /*custom1*/, null /*custom2*/, null /*custom3*/, null /*custom4*/, null /*custom5*/
	,	'Approved'
	,	atLastTrans.std_cost, '' /*field1*/
	from
		dbo.audit_trail atLastTrans
	where
		atLastTrans.serial = @Serial
		and atLastTrans.date_stamp =
		(	select
				max(date_stamp)
			from
				dbo.audit_trail
			where
				serial = @Serial
		)
	--- </Insert>
end	
		
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
--- </Body>


---	<Return>
if	@TranCount = 0 begin
	commit tran @ProcName
end
set	@Result = 0
return
	@Result
--- </Return>
GO
