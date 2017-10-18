SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_calc_committed_dropship] (
	@orderno	integer,
	@rowid		integer )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure calculates the committed quantity for a dropship order.
--	Modified:	April 26 1999, Chris Rogers
--	Paramters:	@orderno		mandatory
--			@rowid			mandatory
--	Returns:	0			success
---------------------------------------------------------------------------------------
--	Outline:
--	1.	Declarations
--	2.	Initializations
--	3.	Sum quantity from po_detail for dropship
--	4.	Get standard unit from part_inventory table
--	5.	Convert quantity from order unit to standard unit
--	6.	Update order_detail with converted quantity
--	7.	Return success
---------------------------------------------------------------------------------------

--	1.	Declarations
	declare	@quantity	numeric(20,6),
		@part		varchar(25),
		@unit		varchar(2),
		@stdunit	varchar(2)
	
--	2.	Get part number and unit from order for later use
	select	@part = part_number,
		@unit = unit
	from	order_detail
	where	order_no = @orderno and
		row_id = @rowid
		
--	3.	Sum quantity from po_detail for dropship
	select	@quantity = sum ( standard_qty )
	from	po_detail
	where	sales_order = @orderno and
		dropship_oe_row_id = @rowid
		
--	4.	Get standard unit from part_inventory table
	select	@stdunit = standard_unit
	from	part_inventory
	where	part = @part
	
--	5.	Convert quantity from order unit to standard unit
	exec msp_unit_conversion @part, @quantity, @unit, @stdunit
	
--	6.	Update order_detail with converted quantity
	update	order_detail
	set	committed_qty = @quantity
	where	order_no = @orderno and
		row_id = @rowid

--	7.	Return success
	return 0
END -- (1E)
GO
