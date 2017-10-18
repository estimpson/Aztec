SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_labelsfromorder] ( @order integer, @part varchar(25) )
as
	select	box_label,
		pallet_label
	from	order_detail
	where	order_no = @order and
		part_number = @part and
		due_date = (	select	min(due_date)
				from	order_detail
				where	order_no = @order and
					part_number = @part )
GO
