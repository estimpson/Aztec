

create index ix_audit_trail_shipper on dbo.audit_trail
	(	shipper
	,	type
	,	part
	,	package_type
	,	std_quantity
	)