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
	MenuID = 'D443F0F2-AB29-494C-AB81-1B1A911CD81E'
,	MenuItemName = 'QualityBatch'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Quality Batch'
,	MenuIcon = 'BrowseObjects!'
,	MenuIcon = 'w_inventory_qualitycontrol'
where
	not exists
	(	select
			*
		from
			FT.MenuItems mi
		where
			mi.MenuID = 'D443F0F2-AB29-494C-AB81-1B1A911CD81E'
	)
