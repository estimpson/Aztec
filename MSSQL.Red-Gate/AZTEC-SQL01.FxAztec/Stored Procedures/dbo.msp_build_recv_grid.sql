SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_build_recv_grid] ( @po_number integer, @start_dt datetime )
AS

        SELECT  po_detail.part_number,
                Max ( po_detail.date_due ),   
                Max ( @start_dt )  date1 ,
                ( Sum( CASE     WHEN    date_due <  @start_dt THEN quantity ELSE 0 END ) - Sum( CASE    WHEN    date_due < @start_dt THEN received ELSE 0 END ) )qty_past_due,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 1, @start_dt)  AND date_due >= @start_dt THEN quantity ELSE 0  END ) - Sum( CASE  WHEN date_due < DateAdd ( dd, 1, @start_dt)  AND date_due >= @start_dt THEN received ELSE 0  END ) ) qty_date1,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 2, @start_dt)  AND date_due >= DateAdd ( dd, 1, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN        date_due < DateAdd ( dd, 2, @start_dt)  AND date_due >=  DateAdd ( dd, 1, @start_dt) THEN received ELSE 0 END ) )qty_date2,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 3, @start_dt)  AND date_due >= DateAdd ( dd, 2, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN        date_due < DateAdd ( dd, 3, @start_dt)  AND date_due >= DateAdd ( dd, 2, @start_dt) THEN received ELSE 0 END ) ) qty_date3,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 4, @start_dt)  AND date_due >= DateAdd ( dd, 3, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN        date_due < DateAdd ( dd, 4, @start_dt)  AND date_due >= DateAdd ( dd, 3, @start_dt) THEN received ELSE 0 END ) ) qty_date4,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 5, @start_dt)  AND date_due >= DateAdd ( dd, 4, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN        date_due < DateAdd ( dd, 5, @start_dt)  AND date_due >= DateAdd ( dd, 4, @start_dt) THEN received ELSE 0 END ) ) qty_date5,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd,  6, @start_dt)  AND date_due >= DateAdd ( dd, 5, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN       date_due <  DateAdd ( dd, 6, @start_dt)  AND date_due >= DateAdd ( dd, 5, @start_dt) THEN received ELSE 0 END ) ) qty_date6,
                ( Sum( CASE  WHEN       date_due < DateAdd ( dd, 7, @start_dt)  AND date_due >= DateAdd ( dd, 6, @start_dt) THEN quantity ELSE 0 END ) - Sum( CASE  WHEN       date_due <  DateAdd ( dd, 7, @start_dt)  AND date_due >= DateAdd ( dd, 6, @start_dt) THEN received  ELSE 0  END ) )qty_date7,
                Sum( CASE       WHEN    date_due < @start_dt THEN received ELSE 0 END ) recv_past_due,
                Sum( CASE  WHEN date_due < DateAdd ( dd, 1, @start_dt)  AND date_due >= @start_dt THEN received ELSE 0  END ) recv_date1,
                Sum( CASE  WHEN date_due < DateAdd ( dd, 2, @start_dt)  AND date_due >=  DateAdd ( dd, 1, @start_dt) THEN received ELSE 0 END ) recv_date2,
                Sum( CASE  WHEN date_due < DateAdd ( dd, 3, @start_dt)  AND date_due >= DateAdd ( dd, 2, @start_dt) THEN received ELSE 0 END ) recv_date3,
                Sum( CASE  WHEN date_due < DateAdd ( dd, 4, @start_dt)  AND date_due >= DateAdd ( dd, 3, @start_dt) THEN received ELSE 0 END ) recv_date4,
                Sum( CASE  WHEN date_due < DateAdd ( dd, 5, @start_dt)  AND date_due >= DateAdd ( dd, 4, @start_dt) THEN received ELSE 0 END ) recv_date5,
                Sum( CASE  WHEN date_due <  DateAdd ( dd, 6, @start_dt)  AND date_due >= DateAdd ( dd, 5, @start_dt) THEN received ELSE 0 END ) recv_date6,
                Sum( CASE  WHEN date_due <  DateAdd ( dd, 7, @start_dt)  AND date_due >= DateAdd ( dd, 6, @start_dt) THEN received  ELSE 0  END ) recv_date7,
                Max ( po_detail.po_number),
                Max ( po_detail.release_type), 
                Max ( po_detail.release_no)
        FROM    po_detail
        WHERE   po_detail.po_number = @po_number and ( po_detail.deleted is null or po_detail.deleted <> 'Y' )
      GROUP BY part_number
GO
