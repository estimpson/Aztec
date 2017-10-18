SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[msp_DestroyDropShipShipperLineItem]
(	@ShipperID integer,
	@PartNumber varchar (35),
	@Result integer = null output )
as
---------------------------------------------------------------------------------------
--	Description:
--	This procedure removes a line item from the specified shipper.
--
--	Parameters:
--	ShipperID	The shipper ID to remove the line from.
--	PartNumber	The part number of the line.
--	Result		The result of running the procedure.  Same as return
--			value.
--
--	Returns:
--	    0	Success.
--	  -10	Invalid shipper.
--	  -11	Shipper is not a drop ship.
--	  -12	Invalid line item.
--	 -999	Unknown error.
--
--	History:
--	08 JUN 2002, Eric Stimpson	Original.
--
--	Process:
--	I.	Validate parameters.
--		A.	Shipper exists.
--			1.	Shipper is drop ship.
--			2.	Line item exists.
--	II.	Delete line from Shipper.
--	III.	Return success.
---------------------------------------------------------------------------------------
begin transaction

--	I.	Validate parameters.
--		A.	Shipper exists.
if not exists
(	select	1
	from	shipper
	where	id = @ShipperID )
begin
	select	@Result = -10
	rollback
	return	@Result
end

--			1.	Shipper is drop ship.
if
(	select	type
	from	shipper
	where	id = @ShipperID and
		status in ( 'C', 'D', 'Z' ) ) != 'D'
begin
	select	@Result = -11
	rollback
	return	@Result
end

--			2.	Line item exists.
if not exists
(	select	1
	from	shipper_detail
	where	shipper = @ShipperID and
		part = @PartNumber )
begin
	select	@Result = -12
	rollback
	return	@Result
end

--	II.	Delete line from Shipper.
delete	shipper_detail
where	shipper = @ShipperID and
	part = @PartNumber

if @@RowCount != 1
begin
	select	@Result = -999
	rollback
	return	@Result
end

--	III.	Return success.
select	@Result = 0
return	@Result
GO
