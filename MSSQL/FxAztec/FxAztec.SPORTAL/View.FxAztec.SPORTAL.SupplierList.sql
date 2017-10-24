
/*
Create View.FxAztec.SPORTAL.SupplierList.sql
*/

use FxAztec
go

--drop table SPORTAL.SupplierList
if	objectproperty(object_id('SPORTAL.SupplierList'), 'IsView') = 1 begin
	drop view SPORTAL.SupplierList
end
go

create view SPORTAL.SupplierList
as
select
	SupplierCode = v.code
,	Status = 0
,	Name = v.name
,	Address = upper(ltrim(rtrim(coalesce(nullif(rtrim(v.address_1), ''), '') + coalesce(case when v.address_2 like '%,%' then ', ' else  ' ' end + nullif(rtrim(v.address_2), ''), '') + coalesce(case when v.address_3 like '%,%' then ', ' else  ' ' end  + nullif(rtrim(v.address_3), ''), ''))))
from
	dbo.vendor v
go

select
	*
from
	SPORTAL.SupplierList vl
order by
	1
