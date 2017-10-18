SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_customer_price_matrix] ( @part varchar (25), @customer varchar (25) ) AS

SELECT 	0.000000, 
	0.000000 
FROM	parameters 
UNION ALL  
SELECT 	qty_break,   
     	price  
FROM 	part_customer_price_matrix 
WHERE 	part = @part AND
	customer = @customer
GO
