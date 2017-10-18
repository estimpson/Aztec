insert
	Fx.Globals
(	Name
,	Value
)
select
	Name = 'ShippingDock.ChangeDestination'
,	Value = convert(bit, 0)
where
	not exists
		(	select
				*
			from
				Fx.Globals g
			where
				g.Name = 'ShippingDock.ChangeDestination'
		)
go

