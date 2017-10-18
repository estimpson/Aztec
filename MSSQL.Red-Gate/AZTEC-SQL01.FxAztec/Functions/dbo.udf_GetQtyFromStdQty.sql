SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetQtyFromStdQty]
(
	@Part varchar(25)
,	@StdQty numeric(20,6)
,	@Unit char(2)
)
returns numeric(20,6)
as
begin
--- <Body>
	/*	Convert standard to unit quantity. */
	declare
		@Qty numeric(20,6)
	
	set
		@Qty = @StdQty * coalesce
		(
			(
				select
					conversion
				from
					dbo.unit_conversion uc
					join dbo.part_unit_conversion puc on
						uc.code = puc.code
					join dbo.part_inventory pi on
						pi.part = @Part
				where
					puc.part = @Part
					and
						uc.unit1 = pi.standard_unit
					and
						uc.unit2 = @Unit
			)
		,	1
		)

--- </Body>

---	<Return>
	return
		@Qty
end
GO
