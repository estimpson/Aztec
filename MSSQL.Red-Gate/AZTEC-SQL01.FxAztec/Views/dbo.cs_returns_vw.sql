SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [dbo].[cs_returns_vw] as
SELECT 	id,
	status, 
	customer, 
	destination, 
	date_stamp, 
	operator
FROM 	shipper
where 	type = 'R' and status in ( 'O' , 'S' )
GO
