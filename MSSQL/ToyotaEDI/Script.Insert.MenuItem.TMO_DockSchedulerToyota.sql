
/*
Script Script.Insert.MenuItem.TMO/DockSchedulerToyota.sql
*/

--use Fx
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
	MenuItemName = 'TMO/DockSchedulerToyota'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Toyota Dock Scheduler'
,	MenuIcon = 'CreateTable5!'
,	ObjectClass = 'w_dockscheduler_toyota'

select
	*
from
	FT.MenuItems mi
where
	MenuItemName = 'TMO/DockSchedulerToyota'
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
	MenuID = 'F70F241E-EE1C-4F49-8E15-C9FD180BDA19'
,	MenuItemName = 'TMO/DockSchedulerToyota'
,	ItemOwner = 'sys'
,	Status = 0
,	Type = 1
,	MenuText = 'Toyota Dock Scheduler'
,	MenuIcon = 'CreateTable5!'
,	ObjectClass = 'w_dockscheduler_toyota'
where
	not exists
	(	select
			*
		from
			FT.MenuItems mi
		where
			mi.MenuID = 'F70F241E-EE1C-4F49-8E15-C9FD180BDA19'
	)

insert
	FT.MenuStructure
(	ParentMenuID
,	ChildMenuID
,	Sequence
)
select
	ParentMenuID = '15FEE462-B210-44AE-94F9-00D892BBB3DB'
,	ChildMenuID = 'F70F241E-EE1C-4F49-8E15-C9FD180BDA19'
,	Sequence = 1
where
	not exists
		(	select
				*
			from
				FT.MenuStructure ms
			where
				ms.ParentMenuID = '15FEE462-B210-44AE-94F9-00D892BBB3DB'
				and ms.ChildMenuID = 'F70F241E-EE1C-4F49-8E15-C9FD180BDA19'
		)

select
	*
from
	FT.MenuItems mi
where
	MenuItemName = 'TMO/DockSchedulerToyota'

select
	*
from
	FT.MenuStructure ms
where
	ms.ParentMenuID = '15FEE462-B210-44AE-94F9-00D892BBB3DB'
order by
	ms.Sequence