SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_get_next_bol]
(	@bol	integer OUTPUT )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
-- 	This procedure gets the next available bill of lading number and returns it via 
--	the reference parameter @bol.
--	Modified:	22 Feb 1999, Chris Rogers
--	Paramters:	@bol	mandatory
--	Returns:	0	success
---------------------------------------------------------------------------------------

--  Get the next available bol number from parameters.
	SELECT	@bol = bol_number
	  FROM	parameters

	WHILE
	(	SELECT	parameters.bol_number
		  FROM	bill_of_lading
			cross join parameters
		 WHERE	bill_of_lading.bol_number = parameters.bol_number ) > 0
	BEGIN -- (2B)
		UPDATE	parameters
		   SET	bol_number = bol_number + 1

		SELECT	@bol = bol_number
		  FROM	parameters
	END -- (2B)

	UPDATE	parameters
	   SET	bol_number = bol_number + 1

	Return 0
END -- (1B)
GO
