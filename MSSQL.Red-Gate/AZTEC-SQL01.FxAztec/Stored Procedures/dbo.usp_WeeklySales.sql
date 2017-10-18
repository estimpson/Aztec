SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[usp_WeeklySales]
AS 
    BEGIN

    SET TRANSACTION ISOLATION LEVEL
	read uncommitted
	
	SET ANSI_WARNINGS OFF 
	 
	 SET nocount ON

    CREATE TABLE #Demand
        (
          Destination varchar(15),
					MonthDate datetime,
          Part VARCHAR(25) ,
          CustomerPart varchar(35),
          CustomerECL varchar(35),
          Qty NUMERIC(20, 6) ,
          ExtCost NUMERIC(20, 6) ,
          ExtPrice NUMERIC(20, 6) ,
          Margain NUMERIC(20,6),
          PRIMARY KEY NONCLUSTERED ( Destination, MonthDate, Part, CustomerPart, CustomerECL )
        )

    INSERT  #Demand
            (	Destination,
				MonthDate,
				Part ,
				CustomerPart,
				CustomerECL,
				Qty ,
				ExtCost,
				ExtPrice,
				Margain
				 
            )
            SELECT  
					Destination = order_header.destination,
					MonthDate =  CASE WHEN release_no LIKE '%_F' AND DATEPART(d,dbo.order_detail.due_date ) >15  THEN ft.fn_TruncDate('mm',DATEADD(mm,1,dbo.order_detail.due_date)) ELSE ft.fn_TruncDate('wk',dbo.order_detail.due_date) END, 
                    Part = part_number ,
                    CustomerPart =  order_detail.customer_part,
                    CustomerECL =  COALESCE(order_header.engineering_level,''),
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
										CASE WHEN release_no LIKE '%_F' AND DATEPART(d,dbo.order_detail.due_date ) >15  THEN ft.fn_TruncDate('mm',DATEADD(mm,1,dbo.order_detail.due_date)) ELSE ft.fn_TruncDate('wk',dbo.order_detail.due_date) END,
                    part_number,
                    dbo.order_detail.customer_part,
                  COALESCE(order_header.engineering_level,'')
		
		SET TRANSACTION ISOLATION LEVEL
		READ COMMITTED
		
		SELECT	*
		FROM		#Demand 

		END










GO
