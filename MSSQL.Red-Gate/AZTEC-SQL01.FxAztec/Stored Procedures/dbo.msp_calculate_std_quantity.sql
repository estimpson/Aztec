SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_calculate_std_quantity]
(	@part			varchar (25),
	@altquantity	numeric (20,6) OUTPUT,
	@unit			char (2) )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure calculates the standard quantity for a part from an alternate
--	quantity and unit of measure.
--	Modified:	02 Jan 1999, Eric E. Stimpson
--	Paramters:	@part			mandatory
--				@altquantiy		mandatory
--				@unit			optional
--	Returns:	0				success
--				-1				error, invalid unit for this part
--				100				no change, unit was standard unit
---------------------------------------------------------------------------------------

--	Declarations.
	DECLARE	@stdquantity	numeric (20,6),
			@factor			numeric (20,6)

--	Initialize all variables
	SELECT	@stdquantity = 0,
			@factor = 1

--	If unit is standard unit, return no change, unit was standard unit.
	IF @unit =
	(	SELECT	standard_unit
		  FROM	part_inventory
		 WHERE	part = @part )
		Return	100

--	Get the standard quantity conversion factor.
	SELECT	@factor = IsNull
			( (	SELECT	conversion
				  FROM	unit_conversion,
						part_inventory,
						part_unit_conversion
				 WHERE	part_inventory.part = @part AND
						part_unit_conversion.part = @part AND
						part_unit_conversion.code = unit_conversion.code AND
						unit_conversion.unit1 = @unit AND
						unit_conversion.unit2 = part_inventory.standard_unit ), -1 )

--	If factor is -1, an error occurred because part had an invalid unit of measure.  Return error.
	IF @factor = -1
		Return	-1

--	Calculate the standard quantity
	SELECT	@stdquantity = @altquantity * @factor

--	Assign the standard quantity to return variable and return success.
	SELECT	@altquantity = @stdquantity
	Return	0
END -- (1B)
GO
