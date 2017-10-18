SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDIToyota].[FreightTypes]
as
select
	FreightType = Type_name
from
	freight_type_definition
GO
