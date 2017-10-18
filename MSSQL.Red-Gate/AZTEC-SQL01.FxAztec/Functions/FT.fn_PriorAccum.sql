SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create function [FT].[fn_PriorAccum]
(	@Shipper int,
	@OrderNo int)
returns numeric(20,6)
begin
--- <Body>
	declare		@PriorAccum numeric(20,6),
						@CurrentAccum numeric (20,6),
						@DateShipped datetime,
						@PriorShippedDT datetime

set	@DateShipped = (select max(date_shipped) from shipper where id = @shipper)
set @PriorShippedDT = (select max(date_shipped) from shipper_detail where order_no = @orderno and date_shipped is not null and date_shipped < ft.fn_truncdate('dd', @DateShipped))
set	@PriorAccum = (select max(accum_shipped) from shipper_detail where date_shipped = @PriorShippedDT and order_no = @OrderNo )
set @CurrentAccum = (select coalesce(max(accum_shipped),0) from shipper_detail where shipper = @Shipper and order_no = @OrderNo )

set @PriorAccum = (select coalesce(@PriorAccum, @CurrentAccum))
						
--- </Body>

---	<Return>
	return	@PriorAccum
end



GO
