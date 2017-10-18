insert
	FT.MenuItems
(	MenuID
,	MenuItemName
,	ItemOwner
,	Status
,	Type
,	MenuText
,	MenuIcon
,	ObjectClass
)
select
	MenuID = '67E32D3B-3362-4F73-986D-1CA9D4F235D1'
,	MenuItemName = 'CycleCount'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Cycle Count'
,	MenuIcon = 'Table!'
,	MenuIcon = 'w_inventory_cyclecount'
where
	not exists
	(	select
			*
		from
			FT.MenuItems mi
		where
			mi.MenuID = '67E32D3B-3362-4F73-986D-1CA9D4F235D1'
	)
