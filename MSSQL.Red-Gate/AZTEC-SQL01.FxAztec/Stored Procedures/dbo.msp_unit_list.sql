SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_unit_list] ( @part varchar(25) ) AS

select unit=null,description='(None)'
union select distinct standard_unit,description
  from part_inventory,unit_measure
  where standard_unit=unit and part_inventory.part=@part
union select distinct unit_conversion.unit1,description
  from part_unit_conversion
  ,unit_conversion,unit_measure
  where unit1=unit and(part_unit_conversion.code=unit_conversion.code)
  and((part_unit_conversion.part=@part))
union select distinct unit_conversion.unit2,description
  from part_unit_conversion
  ,unit_conversion,unit_measure
  where unit2=unit and(part_unit_conversion.code=unit_conversion.code)
  and((part_unit_conversion.part=@part))
GO
