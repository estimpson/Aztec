
/*
Script.ModifyMenuItem.LocationSetups.sql
*/

update
	FT.MenuItems
set
	ObjectClass = 'w_locationinquiry'
where
	MenuID = 'A12CAFC5-DF36-44EC-8FE2-C3AB36E71DC6'

select
	*
from
	FT.MenuItems mi

