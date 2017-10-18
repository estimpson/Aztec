SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [custom].[MES_SiloInventory]
as
select
	Silo = l.code
,	Active = case when l.sequence = 1 then 1 else 0 end
,	Serial = o.serial
,	Part = o.part
,	Quantity = o.std_quantity
,	DateReceived = (select min (date_stamp) from dbo.audit_trail where serial = o.serial and type = 'R')
,	ReceivedQty = (select min (std_quantity) from dbo.audit_trail where serial = o.serial and type = 'R')
from
	dbo.location l
	left join dbo.object o
		on o.location = l.code
where
	l.code like 'SILO%'
GO
