SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
Create PROCEDURE [FT].[ftsp_rpt_release_discrepancy]
	
AS
BEGIN

--Get Destination(s)

declare	@ShipTos table
(	ShipToID varchar(20) primary key)

insert	@ShipTos
select
	shipto_id
from
	dbo.m_in_release_plan mirp
group by
	shipto_id

--Get CustomerPart and ShipTos

declare	@CustomerPartShipTos table
(	ShipToID varchar(20),
	CustomerPart varchar(35), PRIMARY KEY(ShiptoID, CustomerPart))

insert	@CustomerPartShipTos
select
	shipto_id,
	customer_part
from
	dbo.m_in_release_plan mirp
group by
	shipto_id,
	customer_part
UNION	
		
SELECT	Destination,
		Customer_part
FROM	dbo.order_header
WHERE	destination IN (SELECT ShipToID FROM @ShipTos) AND
		COALESCE(order_header.status, 'X')!= 'C'
GROUP BY Destination,
		 Customer_part
		 
 declare	@CustomerPartShipTosCalendar table
(	ShipToID varchar(20),
	CustomerPart varchar(35), 
	MondayDate datetime,
	EDIQty numeric(20,6),
	OrderQty numeric(20,6),
	EDIAccum numeric(20,6),
	OrderAccum numeric(20,6), PRIMARY KEY(ShiptoID, CustomerPart, MondayDate))
	
INSERT @CustomerPartShipTosCalendar
        ( ShipToID ,
          CustomerPart ,
          MondayDate 
        )
SELECT	ShipToID,
		CustomerPart,
		EntryDT
FROM	@CustomerPartShipTos CPST
CROSS JOIN
		(SELECT * FROM [FT].[fn_Calendar_StartCurrentMonday] (   NULL, 'wk',  1,  17)) MondayWeeks
UNION
SELECT	ShipToID,
		CustomerPart,
		PastDueDT
FROM	@CustomerPartShipTos CPST
CROSS JOIN
		( SELECT DATEADD(wk, -1, ft.fn_TruncDate_monday('wk',GETDATE())) PastDueDT) PastDue
		

 /*SELECT	* 
 FROM	@CustomerPartShipTosCalendar	CPSTC	
 ORDER BY	MondayDate, CustomerPart*/	



-- Create temp tables to hold order_detail and m_in_release_plan data
DECLARE @tempReleaseQty TABLE (customerPart varchar(35), destination varchar(15),onEDIQty dec(20,6), MondayofWeek datetime)
DECLARE @tempOrderQty TABLE (customerPart varchar(35), destination varchar(15),onOrderQty dec(20,6), onEDIQty dec(20,6), MondayofWeek datetime)   

INSERT	@tempReleaseQty (customerPart, destination , onEDIQty, MondayofWeek)
SELECT	mirp.customer_part, 
		mirp.shipto_id, 
		SUM(mirp.quantity), 
		DATEADD(wk, -1, ft.fn_TruncDate_monday('wk',GETDATE()))
FROM	dbo.m_in_release_plan mirp
WHERE	mirp.release_dt >= DATEADD(wk, -52, ft.fn_TruncDate_monday('wk',GETDATE())) and 
		mirp.release_dt < DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',GETDATE())) 
GROUP BY mirp.customer_part,
		 mirp.shipto_id
UNION
SELECT	mirp.customer_part, 
		mirp.shipto_id, 
		SUM(mirp.quantity), 
		DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',release_dt))
FROM	dbo.m_in_release_plan mirp
WHERE	mirp.release_dt >= DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',GETDATE())) 
GROUP BY DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',release_dt)),
		mirp.customer_part,
		 mirp.shipto_id
		 
INSERT	@tempOrderQty (customerPart, destination , onOrderQty, MondayofWeek)

SELECT	od.customer_part, 
		od.destination, 
		SUM(od.std_qty), 
		DATEADD(wk, -1, ft.fn_TruncDate_monday('wk',GETDATE()))
FROM	dbo.order_detail od
WHERE	od.due_date >= DATEADD(wk, -52, ft.fn_TruncDate_monday('wk',GETDATE())) and 
		od.due_date < DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',GETDATE())) AND
		od.destination IN (SELECT shiptoID FROM @ShipTos) 
GROUP BY od.customer_part,
		 od.destination
UNION
SELECT	od.customer_part, 
		od.destination, 
		SUM(od.std_qty), 
		DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',od.due_date))
FROM	dbo.order_detail od
WHERE	od.due_date >= DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',GETDATE())) and 
		od.destination IN (SELECT shiptoID FROM @ShipTos) 
GROUP BY od.customer_part,
		 od.destination,
		 DATEADD(wk, 0, ft.fn_TruncDate_monday('wk',od.due_date))
		 
UPDATE	CPSTCO
SET		EDIQty = ISNULL(TRQ.OnEDIQty,0),
		OrderQty = ISNULL(TOQ.OnOrderQty,0),
		EDIAccum = ISNULL((SELECT SUM(ISNULL(TRQ2.OnEDIQty,0)) FROM	@TempReleaseQty TRQ2 WHERE TRQ2.MondayofWeek <= CPSTCO.MondayDate AND CPSTCO.CustomerPart=TRQ2.CustomerPart AND CPSTCO.ShipToID = TRQ2.Destination),0),
		OrderAccum = ISNULL((SELECT SUM(ISNULL(TOQ2.OnOrderQty,0)) FROM	@TempOrderQty TOQ2 WHERE TOQ2.MondayofWeek <= CPSTCO.MondayDate AND CPSTCO.CustomerPart=TOQ2.CustomerPart AND CPSTCO.ShipToID = TOQ2.Destination),0)	
FROM	@CustomerPartShipTosCalendar CPSTCO
LEFT JOIN
		@TempOrderQty TOQ ON CPSTCO.MondayDate = TOQ.MondayofWeek AND CPSTCO.CustomerPart=TOQ.CustomerPart AND CPSTCO.ShipToID = TOQ.Destination
LEFT JOIN
		@TempReleaseQty TRQ ON CPSTCO.MondayDate = TRQ.MondayofWeek AND CPSTCO.CustomerPart=TRQ.CustomerPart AND CPSTCO.ShipToID = TRQ.Destination
		
SELECT	*, 
			(EDIQty-OrderQty) as QtyDifference,
			(CASE WHEN OrderQty = 0 AND EDIQty = 0 THEN 0 WHEN OrderQty>0 THEN (EDIQty-OrderQty)/OrderQty ELSE NULL END) as QtyPercentDiff,
			EDIAccum-OrderAccum As AccumDifference,
			(Select MAX(LEFT(Blanket_part,7)) FROM order_header WHERE  COALESCE(order_header.status, 'X')!= 'C' AND customer_part = CustomerPart AND destination = shiptoid) AS Part
			
FROM	@CustomerPartShipTosCalendar



		
END
GO
