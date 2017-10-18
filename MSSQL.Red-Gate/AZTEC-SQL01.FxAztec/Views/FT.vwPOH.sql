SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwPOH]
(	Part,
	MinOnHand,
	OnHand )
as
--	Description:
--	Get approved or on hold objects in 'non-secured' locations.
--	Get min on hand only for raw parts.
select	Part = part.part,
	MinOnHand = IsNull ( part_online.min_onhand, 0 ),
	OnHand =
	(	select
			sum ( object.std_quantity )
		from
			dbo.object
			join dbo.location on object.location = location.code and
				IsNull ( location.secured_location, 'N' ) != 'Y'
		where
			object.part = part.part and
			object.status in ( 'A', 'H' ) )
from
	dbo.part
	left outer join dbo.part_online on part.part = part_online.part and
		part_online.min_onhand >= 0 and
		part.type = 'R'
GO
