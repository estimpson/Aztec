select
	*
from
	FxAztec.dbo.employee e

select
	*
from
	dbo.object o
where
	o.serial in
	(	select
			at.serial
		from
			dbo.audit_trail at
		where
			at.date_stamp between '2018-11-02 14:00' and '2018-11-02 16:00'
			and at.operator = '142'
	)