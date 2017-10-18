SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [EDIToyota].[usp_SaveNewShipper]
--Added gl_account_code column on insert to shipper_detail	Andre	2014-10-16
--Added salesman column on insert to shipper_detail	Andre	2014-10-23

	@LastManifestNumber varchar(50)
,	@FOB varchar(20)
,	@Carrier varchar(4)
,	@TransMode varchar(2)
,	@FreightType varchar(20)
,	@FreightCharge numeric(20, 6)
,	@AETCNumber varchar(20)
,	@DockCode varchar(15)
,	@ShipperNotes varchar(200)
,	@NewShipperID int out
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
/*	Get a new shipper ID. */
--- <Call>	
set	@CallProcName = 'monitor.usp_NewShipperID'
execute
	@ProcReturn = monitor.usp_NewShipperID
		@NewShipperID = @NewShipperID out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

/*	Write shipper header. */
--- <Insert rows="1">
set	@TableName = 'dbo.shipper'

insert
	dbo.shipper
(	id
,	destination
,	ship_via
,	status
,	aetc_number
,	freight_type
,	printed
,	customer
,	location
,	staged_objs
,	plant
,	invoiced
,	freight
,	gross_weight
,	net_weight
,	tare_weight
,	trans_mode
,	notes
,	terms
,	staged_pallets
,	picklist_printed
,	date_stamp
,	posted
,	scheduled_ship_time
,	currency_unit
,	cs_status
)
select
	id = @NewShipperID
,	destination = ShipTo.ShipToCode
,	ship_via = @Carrier
,	status = 'O'
,	aetc_number = @AETCNumber
,	freight_type = @FreightType
,	printed = 'N'
,	customer = destination.customer
,	location = @FOB
,	staged_objs = 0
,	plant = ShipTo.Plant
,	invoiced = 'N'
,	freight = @FreightCharge
,	gross_weight = 0
,	net_weight = 0
,	tare_weight = 0
,	trans_mode = @TransMode
,	notes = destination_shipping.note_for_shipper
,	terms = customer.terms
,	staged_pallets = 0
,	picklist_printed = 'N'
,	date_stamp = ShipTo.PickupDT
,	posted = 'N'
,	scheduled_ship_time = ShipTo.PickupDT
,	currency_unit = customer.default_currency_unit
,	cs_status = destination.cs_status
from
	(	select
			ShipToCode = st.ShipToCode
		,	PickupDT = min(p.PickupDT)
		,	Plant =
				(	select
						min(bo.Plant)
					from
						EDIToyota.ManifestDetails md
						join EDIToyota.BlanketOrders bo
							on bo.BlanketOrderNo = md.OrderNo
					where
						md.PickupID in
							(	select
									PickupID
								from
									#PickupIDs
							)
				)
		from
			EDIToyota.Pickups p
			join EDIToyota.ShipTos st
				on st.EDIShipToCode = p.ShipToCode
		where
			p.RowID in
			(	select
					PickupID
				from
					#PickupIDs
			)
		group by
			st.ShipToCode
	) ShipTo
	join dbo.destination
		on ShipTo.ShipToCode = destination.destination
	join dbo.destination_shipping
		on ShipTo.ShipToCode = destination_shipping.destination
	join dbo.customer
		on destination.customer = customer.customer

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

/*	Write shipper detail. */
--- <Insert rows="1+">
set	@TableName = 'dbo.shipper_detail'

insert
	dbo.shipper_detail
(	shipper
,	part
,	qty_required
,	qty_packed
,	qty_original
,	order_no
,	customer_po
,	release_no
,	release_date
,	price
,	tare_weight
,	gross_weight
,	net_weight
,	boxes_staged
,	pack_line_qty
,	alternative_qty
,	alternative_unit
,	week_no
,	price_type
,	customer_part
,	part_name
,	part_original
,	stage_using_weight
,	alternate_price
,	account_code
,	salesman
)
select
	shipper = @NewShipperID
,	part = ShipperDetails.Part
,	qty_required = ShipperDetails.QtyRequired
,	qty_packed = 0
,	qty_original = ShipperDetails.QtyRequired
,	order_no = ShipperDetails.OrderNo
,	customer_po = ShipperDetails.CustomerPO
,	release_no = FirstRelease.release_no
,	release_date = FirstRelease.due_date
,	price = order_header.price
,	tare_weight = 0
,	gross_weight = 0
,	net_weight = 0
,	boxes_staged = 0
,	pack_line_qty = 0
,	alternative_qty = 0
,	alternative_unit = order_header.unit
,	week_no = FirstRelease.week_no
,	price_type = order_header.price_unit
,	customer_part = ShipperDetails.CustomerPart
,	part_name = part.name
,	part_original = ShipperDetails.Part
,	stage_using_weight = 'N'
,	alternate_price = order_header.alternate_price
,	account_code = COALESCE(part.gl_account_code,'')
,	salesman = LEFT(order_header.salesman,10)
from
	(	select
			OrderNo
		,	CustomerPart
		,	Part
		,	CustomerPO =
				(	select
						customer_po
					from
						order_header
					where
						order_no = OrderNo
				)
		,	QtyRequired = sum(Quantity)
		,	Racks = sum(Racks)
		from
			EDIToyota.ManifestDetails
		where
			PickupID in
				(	select
						PickupID
					from
						#PickupIDs
				)
			and ManifestNumber <= @LastManifestNumber
		group by
			OrderNo
		,	CustomerPart
		,	Part
	) ShipperDetails
	join dbo.order_header
		on ShipperDetails.OrderNo = order_header.order_no
	join dbo.order_detail FirstRelease
		on ShipperDetails.OrderNo = FirstRelease.order_no
			and FirstRelease.id =
				(	select
						min(id)
					from
						dbo.order_detail
					where
						order_no = ShipperDetails.OrderNo
						and due_date =
							(	select
									min(due_date)
								from
									dbo.order_detail
								where
									order_no = ShipperDetails.OrderNo
							)
				)
	join dbo.part
		on ShipperDetails.Part = part.part

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Update rows="1">
set	@TableName = 'EDIToyota.Pickups'

update
	p
set	
	ShipperID = @NewShipperID
,	Status = 1 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'Scheduled'))
FROM
	EDIToyota.Pickups p
WHERE
	p.RowID IN
		(	SELECT
				PickupID
			FROM
				#PickupIDs
		)
	AND p.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.Pickups', 'New'))

SELECT
	@Error = @@Error,
	@RowCount = @@Rowcount

IF	@Error != 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	ROLLBACK TRAN @ProcName
	RETURN
END
IF	@RowCount != 1 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	ROLLBACK TRAN @ProcName
	RETURN
END
--- </Update>

/*	Set the status on the manifest details(s). */
--- <Update rows="1+">
SET	@TableName = 'EDIToyota.ManifestDetails'

UPDATE
	md
SET
	Status = 1 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'Scheduled'))
FROM
	EDIToyota.ManifestDetails md
WHERE
	md.PickupID IN
		(	SELECT
				PickupID
			FROM
				#PickupIDs
		)
	AND md.ManifestNumber <= @LastManifestNumber
	AND md.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'New'))

SELECT
	@Error = @@Error,
	@RowCount = @@Rowcount

IF	@Error != 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	ROLLBACK TRAN @ProcName
	RETURN
END
IF	@RowCount <= 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	ROLLBACK TRAN @ProcName
	RETURN
END
--- </Update>

/*	If necessary, create new pickup for unscheduled manifests. */
IF	EXISTS
	(	SELECT
			*
		FROM
			EDIToyota.ManifestDetails md
		WHERE
			md.PickupID IN
				(	SELECT
						PickupID
					FROM
						#PickupIDs
				)
			AND md.ManifestNumber > @LastManifestNumber
			AND md.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'New'))
	) BEGIN
	
	--- <Insert rows="1">
	SET	@TableName = 'EDIToyota.Pickups'
	
	INSERT
		EDIToyota.Pickups
	(	ReleaseDate
	,	PickupDT
	,	ShipToCode
	,	PickupCode
	,	ShipperID
	,	Racks
	)
	SELECT
		p.ReleaseDate
	,	p.PickupDT
	,	p.ShipToCode
	,	p.PickupCode
	,	ShipperID = NULL
	,	Racks = SUM(md.Racks)
	FROM
		EDIToyota.ManifestDetails md
		JOIN EDIToyota.Pickups p
			ON p.RowID = md.PickupID
	WHERE
		md.PickupID IN
			(	SELECT
					PickupID
				FROM
					#PickupIDs
			)
		AND md.ManifestNumber > @LastManifestNumber
		AND md.Status = 0 --(select dbo.udf_StatusValue('EDIToyota.ManifestDetails', 'New'))
	GROUP BY
		p.ReleaseDate
	,	p.PickupDT
	,	p.ShipToCode
	,	p.PickupCode
	
	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		ROLLBACK TRAN @ProcName
		RETURN
	END
	IF	@RowCount != 1 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		ROLLBACK TRAN @ProcName
		RETURN
	END
	--- </Insert>
	
	--- <Update rows="1+">
	SET	@TableName = 'EDIToyota.ManifestDetails'
	
	UPDATE
		md
	SET	
		PickupID = SCOPE_IDENTITY()
	,	OrigPickupID = md.PickupID
	FROM
		EDIToyota.ManifestDetails md
	WHERE
		md.PickupID IN
			(	SELECT
					PickupID
				FROM
					#PickupIDs
			)
		AND md.ManifestNumber > @LastManifestNumber

	SELECT
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	IF	@Error != 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		ROLLBACK TRAN @ProcName
		RETURN
	END
	IF	@RowCount <= 0 BEGIN
		SET	@Result = 999999
		RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
		ROLLBACK TRAN @ProcName
		RETURN
	END
	--- </Update>
END

DROP TABLE
	#PickupIDs
--- </Body>

---	<CloseTran AutoCommit=Yes>
IF	@TranCount = 0 BEGIN
	COMMIT TRAN @ProcName
END
---	</CloseTran AutoCommit=Yes>

---	<Return>
SET	@Result = 0
RETURN
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
	@ProcReturn = EDIToyota.usp_SaveNewShipper
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
