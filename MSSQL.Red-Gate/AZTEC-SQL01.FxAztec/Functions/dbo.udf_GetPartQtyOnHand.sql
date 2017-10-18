SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetPartQtyOnHand]
(
	@Part varchar(25)
)
returns numeric(20,6)
as
begin
--- <Body>
/*	Get the on hand quantity for a part number. */
	declare
		@QtyOnHand numeric(20,6)
	
	set
		@QtyOnHand = coalesce
		(
			(
				select
					sum(std_quantity)
				from
					dbo.object o
				where
					o.part = @Part
					and
						O.status = 'A'
			)
		,	0
		)

--- </Body>

---	<Return>
	return
		@QtyOnHand
end
GO
