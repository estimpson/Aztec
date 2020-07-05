
/*
Create Aggregate.FxSYS.dbo.ToList.sql
*/

use FxSYS
go


/*
Create Aggregate.FxSYS.dbo.ToList.sql
*/

use FxSYS
go

exec sp_configure 'show advanced options', 1
reconfigure
exec sp_configure 'clr strict security', 0
reconfigure
exec sp_configure 'clr enabled', 1
reconfigure


if	object_id('dbo.ToList') is not null begin
	drop aggregate dbo.ToList
end
go

drop assembly FxAggregates

create assembly FxAggregates
from 'c:\Temp\CLR\FxAggregates.dll'
go

print N'Creating dbo.ToList...'
go

create aggregate dbo.ToList(@value nvarchar (max))
returns nvarchar (max)
external name FxAggregates.ToList
go

exec sp_configure 'show advanced options', 0
reconfigure
