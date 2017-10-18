SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[usp_MonthlySales_test]
AS 
    Begin

    SET TRANSACTION ISOLATION LEVEL
	read uncommitted
	
	SET ANSI_WARNINGS OFF 
	 
	 SET nocount ON

    CREATE TABLE #Demand
        (
          Destination varchar(15),
		  MonthDate datetime,
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
					MonthDate =  case when release_no like '%_F' and datepart(d,dbo.order_detail.due_date ) >15  then ft.fn_TruncDate('mm',dateadd(mm,1,dbo.order_detail.due_date)) else ft.fn_TruncDate('mm',dbo.order_detail.due_date) end, 
                    Part = part_number ,
                    Qty = COALESCE(SUM(quantity),0) ,
                    ExtCost = COALESCE(SUM(quantity * cost_cum),0),
                    ExtPrice = COALESCE(SUM(quantity * dbo.order_detail.alternate_price),0),
                    Margain = COALESCE(SUM(quantity * dbo.order_detail.alternate_price),0)-COALESCE(SUM(quantity * cost_cum),0)
            FROM    dbo.order_detail
					join	dbo.order_header on dbo.order_detail.order_no = dbo.order_header.order_no
					join	customer on order_header.customer = customer.customer
                    JOIN dbo.part_standard ON part_number = part
            WHERE   order_detail.due_date <  dateadd(mm, 6, ft.fn_TruncDate('mm',getdate()))  and
							order_detail.due_date>= dateadd(mm, -1, ft.fn_TruncDate('mm',getdate())) and
							quantity>1 
							
            GROUP BY 
					order_header.destination,
					case when release_no like '%_F' and datepart(d,dbo.order_detail.due_date ) >15  then ft.fn_TruncDate('mm',dateadd(mm,1,dbo.order_detail.due_date)) else ft.fn_TruncDate('mm',dbo.order_detail.due_date) end,
                    part_number
		
		SET TRANSACTION ISOLATION LEVEL
		read committed
		
		select	*
		from		#Demand 
		Where Part like '%3343%'

		End









GO
