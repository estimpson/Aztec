SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_vendor_price] ( @as_part varchar(25), @as_vendor varchar(10), @adec_qty decimal(20,6) )
as
begin transaction
	declare @price numeric (20,6)
	
	SELECT	@price = part_vendor_price_matrix.price  
	FROM	part_vendor_price_matrix
	WHERE	part = @as_part and
		vendor = @as_vendor and
		break_qty = (	select	max ( break_qty )
				from	part_vendor_price_matrix
				where	part = @as_part and
					vendor = @as_vendor and
					break_qty <= @adec_qty ) 
	
	if isnull ( @price, -1 ) = -1
		select	@price = price
		from	part_standard
		where	part = @as_part
	
	select isnull(@price,0)
commit transaction
GO
