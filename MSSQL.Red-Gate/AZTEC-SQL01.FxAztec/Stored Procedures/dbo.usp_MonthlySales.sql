SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[usp_MonthlySales]
AS 
    BEGIN

    SET TRANSACTION ISOLATION LEVEL
	read uncommitted
	
	SET ANSI_WARNINGS OFF 
	 
	 SET nocount ON

    CREATE TABLE #Demand
        (
          Destination VARCHAR(15),
		  MonthDate DATETIME,
          Part VARCHAR(25) ,
          Qty NUMERIC(20, 6) ,
          ExtCost NUMERIC(20, 6) ,
          ExtPrice NUMERIC(20, 6) ,
          Margain NUMERIC(20,6),
          PRIMARY KEY NONCLUSTERED ( Destination, MonthDate, Part )
        )

    INSERT  #Demand
            (	Destination,
				MonthDate,
				Part ,
				Qty ,
				ExtCost,
				ExtPrice,
				Margain
				 
            )
            SELECT  
					Destination = order_header.destination,
					MonthDate =  CASE WHEN release_no LIKE '%_F' AND DATEPART(d,dbo.order_detail.due_date ) >15  THEN ft.fn_TruncDate('mm',DATEADD(mm,1,dbo.order_detail.due_date)) ELSE ft.fn_TruncDate('mm',dbo.order_detail.due_date) END, 
                    Part = part_number ,
                    Qty = COALESCE(SUM(quantity),0) ,
                    ExtCost = COALESCE(SUM(quantity * cost_cum),0),
                    ExtPrice = COALESCE(SUM(quantity * dbo.order_detail.alternate_price),0),
                    Margain = COALESCE(SUM(quantity * dbo.order_detail.alternate_price),0)-COALESCE(SUM(quantity * cost_cum),0)
            FROM    dbo.order_detail
					JOIN	dbo.order_header ON dbo.order_detail.order_no = dbo.order_header.order_no
					JOIN	customer ON order_header.customer = customer.customer
                    JOIN dbo.part_standard ON part_number = part
            WHERE   order_detail.due_date <  DATEADD(mm, 6, ft.fn_TruncDate('mm',GETDATE()))  AND
							order_detail.due_date>= DATEADD(mm, -1, ft.fn_TruncDate('mm',GETDATE())) AND
							quantity>=1 
							
            GROUP BY 
					order_header.destination,
					CASE WHEN release_no LIKE '%_F' AND DATEPART(d,dbo.order_detail.due_date ) >15  THEN ft.fn_TruncDate('mm',DATEADD(mm,1,dbo.order_detail.due_date)) ELSE ft.fn_TruncDate('mm',dbo.order_detail.due_date) END,
                    part_number
		
		SET TRANSACTION ISOLATION LEVEL
		READ COMMITTED
		
		SELECT	*
		FROM		#Demand 

		END









GO
