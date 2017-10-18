SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view
  [dbo].[cs_part_profile_vw]
  as select part,
    customer_part,
    customer_standard_pack,
    customer_unit,
    taxable,
    type,
    customer
    from part_customer
GO
