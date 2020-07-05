
/*
Create View.FxSYS.dbo.GetNewID.sql
*/

use FxSYS
go

--drop table dbo.GetNewID
if	objectproperty(object_id('dbo.GetNewID'), 'IsView') = 1 begin
	drop view dbo.GetNewID
end
go

create view dbo.GetNewID
as
select
	Value = newid()
go

select
	*
from
	dbo.GetNewID gni
go
