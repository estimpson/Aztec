
select
	rh.ReceiverNumber, *
from
	(	select
			Ord = row_number() over (partition by part order by at.date_stamp desc)
		,	Serial = at.serial
		,	PartCode = at.part
		from
			dbo.audit_trail at
		where
			type = 'R'
			and part in
			(	select
	 				mpl.ChildPart
	 			from
	 				dbo.MES_PickList mpl
	 			where
	 				WODID = 3
			)
	) Inventory
	join dbo.ReceiverObjects ro
		on ro.Serial = Inventory.serial
	join dbo.ReceiverLines rl
		on rl.ReceiverLineID = ro.ReceiverLineID
	join dbo.ReceiverHeaders rh
		on rl.ReceiverID = rh.ReceiverID
where
	Ord <= 3

select
	*
from
	(	select
			Ord = row_number() over (partition by part order by serial asc)
		,	Serial = '*S' + convert(varchar, serial) + '*  ' + convert(varchar, serial)
		,	PartCode = part
		from
			object
		where
			part in
			(	select
	 				mpl.ChildPart
	 			from
	 				dbo.MES_PickList mpl
	 			where
	 				WODID = 3
			)
	) Inventory
where
	Ord <= 3
