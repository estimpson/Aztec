use FxAztec
go

begin transaction
go
drop table
	CDC.po_detail

select
	__$operation = 0
,	__$loginID = @@SPID
,	__$operator = convert(varchar(5), 'EES')
,	__$sysuser = convert(sysname, system_user)
,	pd.po_number
,	pd.vendor_code
,	pd.part_number
,	pd.description
,	pd.unit_of_measure
,	pd.date_due
,	pd.requisition_number
,	pd.status
,	pd.type
,	pd.last_recvd_date
,	pd.last_recvd_amount
,	pd.cross_reference_part
,	pd.account_code
,	pd.notes
,	pd.quantity
,	pd.received
,	pd.balance
,	pd.active_release_cum
,	pd.received_cum
,	pd.price
,	pd.row_id
,	pd.invoice_status
,	pd.invoice_date
,	pd.invoice_qty
,	pd.invoice_unit_price
,	pd.release_no
,	pd.ship_to_destination
,	pd.terms
,	pd.week_no
,	pd.plant
,	pd.invoice_number
,	pd.standard_qty
,	pd.sales_order
,	pd.dropship_oe_row_id
,	pd.ship_type
,	pd.dropship_shipper
,	pd.price_unit
,	pd.printed
,	pd.selected_for_print
,	pd.deleted
,	pd.ship_via
,	pd.release_type
,	pd.dimension_qty_string
,	pd.taxable
,	pd.scheduled_time
,	pd.truck_number
,	pd.confirm_asn
,	pd.job_cost_no
,	pd.alternate_price
,	pd.requisition_id
,	pd.promise_date
,	pd.other_charge
,	pd.RowID
,	pd.RowCreateDT
,	pd.RowCreateUser
,	pd.RowModifiedDT
,	pd.RowModifiedUser
,	RowVersion = convert(binary(8), pd.RowVersion)
into
	CDC.po_detail
from
	dbo.po_detail pd with (tablockx)
go

drop trigger dbo.cdc_po_detail_i
go

create trigger cdc_po_detail_i on dbo.po_detail after insert
as
insert
	CDC.po_detail
(	__$operation
,	__$loginID
,	__$operator
,	__$sysuser
,	po_number
,	vendor_code
,	part_number
,	description
,	unit_of_measure
,	date_due
,	requisition_number
,	status
,	type
,	last_recvd_date
,	last_recvd_amount
,	cross_reference_part
,	account_code
,	notes
,	quantity
,	received
,	balance
,	active_release_cum
,	received_cum
,	price
,	row_id
,	invoice_status
,	invoice_date
,	invoice_qty
,	invoice_unit_price
,	release_no
,	ship_to_destination
,	terms
,	week_no
,	plant
,	invoice_number
,	standard_qty
,	sales_order
,	dropship_oe_row_id
,	ship_type
,	dropship_shipper
,	price_unit
,	printed
,	selected_for_print
,	deleted
,	ship_via
,	release_type
,	dimension_qty_string
,	taxable
,	scheduled_time
,	truck_number
,	confirm_asn
,	job_cost_no
,	alternate_price
,	requisition_id
,	promise_date
,	other_charge
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
,	[RowVersion]
)
select
	__$operation = 1
,	__$loginID = @@SPID
,	__$operator =
		(	select top(1)
				ul.UserCode
			from
				FXSYS.UserLogin ul
			where
				ul.LoginID = @@SPID
			order by
				ul.RowID desc
		)
,	__$sysuser = system_user
,	Inserted.po_number
,	Inserted.vendor_code
,	Inserted.part_number
,	Inserted.description
,	Inserted.unit_of_measure
,	Inserted.date_due
,	Inserted.requisition_number
,	Inserted.status
,	Inserted.type
,	Inserted.last_recvd_date
,	Inserted.last_recvd_amount
,	Inserted.cross_reference_part
,	Inserted.account_code
,	Inserted.notes
,	Inserted.quantity
,	Inserted.received
,	Inserted.balance
,	Inserted.active_release_cum
,	Inserted.received_cum
,	Inserted.price
,	Inserted.row_id
,	Inserted.invoice_status
,	Inserted.invoice_date
,	Inserted.invoice_qty
,	Inserted.invoice_unit_price
,	Inserted.release_no
,	Inserted.ship_to_destination
,	Inserted.terms
,	Inserted.week_no
,	Inserted.plant
,	Inserted.invoice_number
,	Inserted.standard_qty
,	Inserted.sales_order
,	Inserted.dropship_oe_row_id
,	Inserted.ship_type
,	Inserted.dropship_shipper
,	Inserted.price_unit
,	Inserted.printed
,	Inserted.selected_for_print
,	Inserted.deleted
,	Inserted.ship_via
,	Inserted.release_type
,	Inserted.dimension_qty_string
,	Inserted.taxable
,	Inserted.scheduled_time
,	Inserted.truck_number
,	Inserted.confirm_asn
,	Inserted.job_cost_no
,	Inserted.alternate_price
,	Inserted.requisition_id
,	Inserted.promise_date
,	Inserted.other_charge
,	Inserted.RowID
,	Inserted.RowCreateDT
,	Inserted.RowCreateUser
,	Inserted.RowModifiedDT
,	Inserted.RowModifiedUser
,	Inserted.RowVersion
from
	Inserted
go

drop trigger dbo.cdc_po_detail_u
go

create trigger cdc_po_detail_u on dbo.po_detail after update
as
insert
	CDC.po_detail
(	__$operation
,	__$loginID
,	__$operator
,	__$sysuser
,	po_number
,	vendor_code
,	part_number
,	description
,	unit_of_measure
,	date_due
,	requisition_number
,	status
,	type
,	last_recvd_date
,	last_recvd_amount
,	cross_reference_part
,	account_code
,	notes
,	quantity
,	received
,	balance
,	active_release_cum
,	received_cum
,	price
,	row_id
,	invoice_status
,	invoice_date
,	invoice_qty
,	invoice_unit_price
,	release_no
,	ship_to_destination
,	terms
,	week_no
,	plant
,	invoice_number
,	standard_qty
,	sales_order
,	dropship_oe_row_id
,	ship_type
,	dropship_shipper
,	price_unit
,	printed
,	selected_for_print
,	deleted
,	ship_via
,	release_type
,	dimension_qty_string
,	taxable
,	scheduled_time
,	truck_number
,	confirm_asn
,	job_cost_no
,	alternate_price
,	requisition_id
,	promise_date
,	other_charge
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
,	[RowVersion]
)
select
	__$operation = 2
,	__$loginID = @@SPID
,	__$operator =
		(	select top(1)
				ul.UserCode
			from
				FXSYS.UserLogin ul
			where
				ul.LoginID = @@SPID
			order by
				ul.RowID desc
		)
,	__$sysuser = system_user
,	Inserted.po_number
,	Inserted.vendor_code
,	Inserted.part_number
,	Inserted.description
,	Inserted.unit_of_measure
,	Inserted.date_due
,	Inserted.requisition_number
,	Inserted.status
,	Inserted.type
,	Inserted.last_recvd_date
,	Inserted.last_recvd_amount
,	Inserted.cross_reference_part
,	Inserted.account_code
,	Inserted.notes
,	Inserted.quantity
,	Inserted.received
,	Inserted.balance
,	Inserted.active_release_cum
,	Inserted.received_cum
,	Inserted.price
,	Inserted.row_id
,	Inserted.invoice_status
,	Inserted.invoice_date
,	Inserted.invoice_qty
,	Inserted.invoice_unit_price
,	Inserted.release_no
,	Inserted.ship_to_destination
,	Inserted.terms
,	Inserted.week_no
,	Inserted.plant
,	Inserted.invoice_number
,	Inserted.standard_qty
,	Inserted.sales_order
,	Inserted.dropship_oe_row_id
,	Inserted.ship_type
,	Inserted.dropship_shipper
,	Inserted.price_unit
,	Inserted.printed
,	Inserted.selected_for_print
,	Inserted.deleted
,	Inserted.ship_via
,	Inserted.release_type
,	Inserted.dimension_qty_string
,	Inserted.taxable
,	Inserted.scheduled_time
,	Inserted.truck_number
,	Inserted.confirm_asn
,	Inserted.job_cost_no
,	Inserted.alternate_price
,	Inserted.requisition_id
,	Inserted.promise_date
,	Inserted.other_charge
,	Inserted.RowID
,	Inserted.RowCreateDT
,	Inserted.RowCreateUser
,	Inserted.RowModifiedDT
,	Inserted.RowModifiedUser
,	Inserted.RowVersion
from
	Inserted
go

drop trigger dbo.cdc_po_detail_d
go

create trigger cdc_po_detail_d on dbo.po_detail after delete
as
insert
	CDC.po_detail
(	__$operation
,	__$loginID
,	__$operator
,	__$sysuser
,	po_number
,	vendor_code
,	part_number
,	description
,	unit_of_measure
,	date_due
,	requisition_number
,	status
,	type
,	last_recvd_date
,	last_recvd_amount
,	cross_reference_part
,	account_code
,	notes
,	quantity
,	received
,	balance
,	active_release_cum
,	received_cum
,	price
,	row_id
,	invoice_status
,	invoice_date
,	invoice_qty
,	invoice_unit_price
,	release_no
,	ship_to_destination
,	terms
,	week_no
,	plant
,	invoice_number
,	standard_qty
,	sales_order
,	dropship_oe_row_id
,	ship_type
,	dropship_shipper
,	price_unit
,	printed
,	selected_for_print
,	deleted
,	ship_via
,	release_type
,	dimension_qty_string
,	taxable
,	scheduled_time
,	truck_number
,	confirm_asn
,	job_cost_no
,	alternate_price
,	requisition_id
,	promise_date
,	other_charge
,	RowID
,	RowCreateDT
,	RowCreateUser
,	RowModifiedDT
,	RowModifiedUser
,	[RowVersion]
)
select
	__$operation = -1
,	__$loginID = @@SPID
,	__$operator =
		(	select top(1)
				ul.UserCode
			from
				FXSYS.UserLogin ul
			where
				ul.LoginID = @@SPID
			order by
				ul.RowID desc
		)
,	__$sysuser = system_user
,	Deleted.po_number
,	Deleted.vendor_code
,	Deleted.part_number
,	Deleted.description
,	Deleted.unit_of_measure
,	Deleted.date_due
,	Deleted.requisition_number
,	Deleted.status
,	Deleted.type
,	Deleted.last_recvd_date
,	Deleted.last_recvd_amount
,	Deleted.cross_reference_part
,	Deleted.account_code
,	Deleted.notes
,	Deleted.quantity
,	Deleted.received
,	Deleted.balance
,	Deleted.active_release_cum
,	Deleted.received_cum
,	Deleted.price
,	Deleted.row_id
,	Deleted.invoice_status
,	Deleted.invoice_date
,	Deleted.invoice_qty
,	Deleted.invoice_unit_price
,	Deleted.release_no
,	Deleted.ship_to_destination
,	Deleted.terms
,	Deleted.week_no
,	Deleted.plant
,	Deleted.invoice_number
,	Deleted.standard_qty
,	Deleted.sales_order
,	Deleted.dropship_oe_row_id
,	Deleted.ship_type
,	Deleted.dropship_shipper
,	Deleted.price_unit
,	Deleted.printed
,	Deleted.selected_for_print
,	Deleted.deleted
,	Deleted.ship_via
,	Deleted.release_type
,	Deleted.dimension_qty_string
,	Deleted.taxable
,	Deleted.scheduled_time
,	Deleted.truck_number
,	Deleted.confirm_asn
,	Deleted.job_cost_no
,	Deleted.alternate_price
,	Deleted.requisition_id
,	Deleted.promise_date
,	Deleted.other_charge
,	Deleted.RowID
,	Deleted.RowCreateDT
,	Deleted.RowCreateUser
,	Deleted.RowModifiedDT
,	Deleted.RowModifiedUser
,	Deleted.RowVersion
from
	Deleted
go

commit
go
