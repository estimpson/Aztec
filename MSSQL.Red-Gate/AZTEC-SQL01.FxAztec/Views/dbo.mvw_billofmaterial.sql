SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_billofmaterial]
    ( parent_part,
      part,
      type,
      std_qty ) AS
-------------------------------------------------------------------
--	View : mvw_billofmaterial required for super cop processing
--	
--	Harish Gubbi 01/07/2000	Created newly for super cop purposes
-------------------------------------------------------------------
select	bill_of_material_ec.parent_part,
        bill_of_material_ec.part,
        bill_of_material_ec.type,
        bill_of_material_ec.std_qty * (1 + bill_of_material_ec.scrap_factor)
from	bill_of_material_ec
where	(bill_of_material_ec.start_datetime <= getdate() ) AND
	(bill_of_material_ec.end_datetime > getdate() OR
	bill_of_material_ec.end_datetime is null) and
	isnull(bill_of_material_ec.substitute_part,'N') <> 'Y'
GO
