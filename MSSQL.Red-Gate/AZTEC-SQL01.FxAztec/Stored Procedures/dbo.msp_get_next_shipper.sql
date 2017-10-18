SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_get_next_shipper]
(	@shipper	integer OUTPUT )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure gets the next available shipper and returns it via the reference
--	parameter @shipper.
--	Modified:	16 Feb 1999, Eric E. Stimpson
--	Paramters:	@shipper		mandatory
--	Returns:	0				success
---------------------------------------------------------------------------------------

--  Get the next available order number from parameters.
	SELECT	@shipper = shipper
	  FROM	parameters

	WHILE
	(	SELECT	shipper
		  FROM	shipper
				cross join parameters
		 WHERE	id = shipper ) > 0
	BEGIN -- (2B)
		UPDATE	parameters
		   SET	shipper = shipper + 1

		SELECT	@shipper = shipper
		  FROM	parameters
	END -- (2B)

	UPDATE	parameters
	   SET	shipper = shipper + 1

	Return 0
END -- (1B)
GO
