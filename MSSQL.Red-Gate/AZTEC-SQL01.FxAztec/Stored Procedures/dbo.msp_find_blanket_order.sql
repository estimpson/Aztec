SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.msp_find_blanket_order    Script Date: 4/25/2001 11:11:14 AM ******/

/****** Object:  Stored Procedure dbo.msp_find_blanket_order    Script Date: 3/15/2000 3:48:55 PM ******/
CREATE PROCEDURE [dbo].[msp_find_blanket_order]
(	@customerpart	varchar (35),
	@shipto			varchar (20),
	@customerpo		varchar (30) = null,
	@modelyear		varchar (4) = null,
	@orderno		decimal (8)	OUTPUT )
AS
BEGIN -- (1B)
---------------------------------------------------------------------------------------
--  This procedure finds a blanket order from customer information.
--	Modified:	02 Jan 1999, Eric E. Stimpson
--	Paramters:	@customerpart	mandatory
--				@shipto			mandatory
--				@customerpo		optional
--				@modelyear		optional
--				@orderno		mandatory
--	Returns:	0				success
--				-1				error occurred (more than one order found)
--				100				order not found
---------------------------------------------------------------------------------------

--  Declare all the required local variables.
	DECLARE	@ordercount			integer

--	Initialize all variables.
	SELECT	@ordercount = 0

--	Get the number of orders.
	SELECT	@ordercount = IsNull
			( (	SELECT	Count ( 1 )
				  FROM	order_header AS oh,
						edi_setups AS edi
				 WHERE	customer_part = @customerpart AND
						oh.destination = @shipto AND
						edi.destination = @shipto AND
						( customer_po = @customerpo OR IsNull ( check_po, 'N' ) <> 'Y' ) AND
						( model_year = @modelyear OR IsNull ( check_model_year, 'N' ) <> 'Y' ) ), 0 )

--	If order count is equal to 0, set orderno to null and return 100 for "order not found."
	IF @ordercount = 0
	BEGIN -- (2B)
		SELECT	@orderno = NULL
		Return	100
	END -- (2B)

--	If order count is greater than 1, set orderno to null and return -1 for "error occurred."
--	Data integrity in order header should prevent this condition.
	IF @ordercount > 1
	BEGIN -- (3B)
		SELECT	@orderno = NULL
		Return	-1
	END -- (3B)

--	Order count is equal to 1, set orderno to the order found and return 0 for "success."
	SELECT	@orderno = order_no
	  FROM	order_header AS oh,
			edi_setups AS edi
	 WHERE	customer_part = @customerpart AND
			oh.destination = @shipto AND
			edi.destination = @shipto AND
			( customer_po = @customerpo OR IsNull ( check_po, 'N' ) <> 'Y' ) AND
			( model_year = @modelyear OR IsNull ( check_model_year, 'N' ) <> 'Y' )

	Return	0
END -- (1B)
GO
