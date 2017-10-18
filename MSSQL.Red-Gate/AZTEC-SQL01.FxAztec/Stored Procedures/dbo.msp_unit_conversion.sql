SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_unit_conversion]
(	@part			varchar (25),
	@altquantity	numeric (20,6) OUTPUT,
	@unitfrom		char (2),
	@unitto			char (2) )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure calculates an alternate quantity for a part from an alternate
--	quantity and unit of measure.
--	Modified:	02 Jan 1999, Eric E. Stimpson
--	Paramters:	@part			mandatory
--				@altquantiy		mandatory
--				@unit			optional
--	Returns:	0				success
--				-1				error, invalid from unit for this part
--				-2				error, invalid to unit for this part
--				100				no change, from unit and to unit were same
---------------------------------------------------------------------------------------

--	Declarations.
	DECLARE	@stdquantity	numeric (20,6),
			@factor			numeric (20,6)

--	Initialize all variables
	SELECT	@stdquantity = 0,
			@factor = 1

--	If from unit and to unit are the same, return no change.
	IF @unitfrom = @unitto
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
						unit_conversion.unit1 = @unitfrom AND
						unit_conversion.unit2 = part_inventory.standard_unit ), -1 )

--	If factor is -1, an error occurred because from unit of measure was invalid.  Return error.
	IF @factor = -1
		Return	-1

--	Calculate the standard quantity.
	SELECT	@stdquantity = @altquantity * @factor

--	Get the alternate quantity conversion factor.
	SELECT	@factor = IsNull
			( (	SELECT	conversion
				  FROM	unit_conversion,
						part_inventory,
						part_unit_conversion
				 WHERE	part_inventory.part = @part AND
						part_unit_conversion.part = @part AND
						part_unit_conversion.code = unit_conversion.code AND
						unit_conversion.unit1 = part_inventory.standard_unit AND
						unit_conversion.unit2 = @unitto ), -2 )

--	If factor is -2, an error occurred because to unit of measure was invalid.  Return error.
	IF @factor = -2
		Return	-2

--	Calculate the alternate quantity and return success,
	SELECT	@altquantity = @stdquantity * @factor
	Return	0

END -- (1B)
GO
