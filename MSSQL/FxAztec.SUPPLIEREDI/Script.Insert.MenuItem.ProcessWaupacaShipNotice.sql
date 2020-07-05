
/*
Script Script.Insert.MenuItem.ProcessWaupacaShipNotice.sql
*/

--use FxAztec
--go

/*
insert
	FT.MenuItems
(	MenuItemName
,	ItemOwner
,	Status
,	Type
,	MenuText
,	MenuIcon
,	ObjectClass
)
select
	MenuItemName = 'ProcessWaupacaShipNotice'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Process Waupaca Ship Notice'
,	MenuIcon = 'Compile!'
,	ObjectClass = 'w_processwaupacashipnotice'

select
	*
from
	FT.MenuItems mi
where
	MenuItemName = 'ProcessWaupacaShipNotice'
*/
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
	MenuID = '2D5A2EFF-1525-49D4-AA0C-FB19B0995D05'
,	MenuItemName = 'ProcessWaupacaShipNotice'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Process Waupaca Ship Notice'
,	MenuIcon = 'Compile!'
,	ObjectClass = 'w_processwaupacashipnotice'
where
	not exists
	(	select
			*
		from
			FT.MenuItems mi
		where
			mi.MenuID = '2D5A2EFF-1525-49D4-AA0C-FB19B0995D05'
	)

select
	*
from
	FT.MenuStructure ms
where
	ms.ParentMenuID = 'E489F079-5C16-4A2A-95DF-2AF994AE990B'

insert
	FT.MenuStructure
(	ParentMenuID
,	ChildMenuID
,	Sequence
)
select
	ParentMenuID = 'E489F079-5C16-4A2A-95DF-2AF994AE990B'
,	ChildMenuID = '2D5A2EFF-1525-49D4-AA0C-FB19B0995D05'
,	Sequence = 6
where
	not exists
	(	select
			*
		from
			FT.MenuStructure ms
		where
			ParentMenuID = 'E489F079-5C16-4A2A-95DF-2AF994AE990B'
			and ChildMenuID = '2D5A2EFF-1525-49D4-AA0C-FB19B0995D05'
	)