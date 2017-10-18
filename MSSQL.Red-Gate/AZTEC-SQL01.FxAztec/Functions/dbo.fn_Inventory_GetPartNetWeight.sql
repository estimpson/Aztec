SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_Inventory_GetPartNetWeight]
(	@Part varchar(25)
,	@StdQty numeric(20,6)
)
returns numeric(20,6)
as
begin
--- <Body>
/*	Return the net weight of a quantity of a part. */
	declare
		@NetWeight numeric(20,6)
	
	set @NetWeight =
		(	select
				unit_weight * @StdQty
			from
				dbo.part_inventory
			where
				part = @Part
		)
	
--- </Body>

---	<Return>
	return
		@NetWeight
end
GO
