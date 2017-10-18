SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_get_next_serial]
(@serial integer OUTPUT )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure gets the next available shipper and returns it via the reference
--	parameter @shipper.
--	Modified:	26 Feb 1999, Mamatha bettagere
--	Paramters:	@shipper    mandatory
--	Returns:	0	    success
---------------------------------------------------------------------------------------
--  Get the next available order number from parameters.
	SELECT	@serial = next_serial
	  FROM	parameters

	WHILE
	( (	SELECT	serial
		  FROM	object
		 cross join parameters
		 WHERE	serial = next_serial ) > 0 OR
	(	SELECT	serial
		  FROM	audit_trail
		 cross join parameters
		 WHERE	serial = next_serial ) > 0 )
	BEGIN -- (2B)
		UPDATE	parameters
		   SET	next_serial = next_serial + 1

		SELECT	@serial = next_serial
		  FROM	parameters
	END -- (2B)

	UPDATE	parameters
	   SET	next_serial = next_serial + 1

	Return 0
END -- (1B)
GO
