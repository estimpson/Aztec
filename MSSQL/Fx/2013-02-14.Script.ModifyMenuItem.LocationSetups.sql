
/*
Script.ModifyMenuItem.LocationSetups.sql
*/

update
	FT.MenuItems
set
	ObjectClass = 'w_locationinquiry'
where
	MenuItemName = 'TMS/Locations'

select
	*
from
	FT.MenuItems mi
