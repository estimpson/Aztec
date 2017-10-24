SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SPORTAL].[SupplierList]
as
select
	SupplierCode = v.code
,	Status = 0
,	Name = v.name
,	Address = upper(ltrim(rtrim(coalesce(nullif(rtrim(v.address_1), ''), '') + coalesce(case when v.address_2 like '%,%' then ', ' else  ' ' end + nullif(rtrim(v.address_2), ''), '') + coalesce(case when v.address_3 like '%,%' then ', ' else  ' ' end  + nullif(rtrim(v.address_3), ''), ''))))
from
	dbo.vendor v
GO
