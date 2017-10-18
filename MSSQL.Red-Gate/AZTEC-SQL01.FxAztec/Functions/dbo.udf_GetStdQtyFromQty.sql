SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetStdQtyFromQty]
(
	@Part varchar(25)
,	@Qty numeric(20,6)
,	@Unit char(2)
)
returns numeric(20,6)
as
begin
--- <Body>
	/*	Convert standard to unit quantity. */
	declare
		@StdQty numeric(20,6)
	
	set
		@StdQty = @Qty * coalesce
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
						uc.unit1 = @Unit
					and
						uc.unit2 = pi.standard_unit
			)
		,	1
		)

--- </Body>

---	<Return>
	return
		@StdQty
end
GO
