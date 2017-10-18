SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_PriceAdmin_GetBlanketPrices]
as
	set nocount on

	select	pc.part, 
			pc.customer, 
			null as 'effective_date', 
			pc.blanket_price,
			oh.customer_po
	from	dbo.part_customer pc left outer join dbo.order_header oh on
			oh.customer = pc.customer and
			oh.blanket_part = pc.part and
			oh.order_no = (	select	max(order_no)
							from	dbo.order_header oh1 
							where	oh1.customer = pc.customer and
									oh1.blanket_part = pc.part	)
GO
