
/*
Create View.FxEDI.FS.GetNewID.sql
*/

use FxEDI
go

--drop table FS.GetNewID
if	objectproperty(object_id('FS.GetNewID'), 'IsView') = 1 begin
	drop view FS.GetNewID
end
go

create view FS.GetNewID
as
select
	Value = newid()
go

select
	*
from
	FS.GetNewID gni
go

