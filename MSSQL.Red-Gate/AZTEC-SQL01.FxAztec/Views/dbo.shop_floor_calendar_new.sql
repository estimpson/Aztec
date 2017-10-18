SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  View dbo.shop_floor_calendar_new    Script Date: 4/25/2001 11:11:12 AM ******/

/****** Object:  View dbo.shop_floor_calendar_new    Script Date: 3/15/2000 3:48:54 PM ******/
/****** Object:  View dbo.shop_floor_calendar_new    Script Date: 7/15/98 11:26:37 AM ******/
create view [dbo].[shop_floor_calendar_new]
(	machine,
	work_date,
	begin_time,
	up_hours,
	down_hours,
	end_time,
	end_date,
	crew_size,
	labor_code )
as
(	select	machine,
		convert ( smalldatetime,
		convert ( varchar, begin_datetime, 106) ),
		convert ( smalldatetime, convert ( varchar, begin_datetime, 108) ),
		convert ( numeric ( 5,2 ),
 			( datediff ( mi, begin_datetime, end_datetime ) * .01667) ),
		convert ( numeric ( 5,2 ), 0 ),
		convert ( smalldatetime, convert ( varchar, end_datetime, 108) ),
		convert ( smalldatetime, convert ( varchar, end_datetime, 106) ),
		crew_size,
		labor_code
	from shop_floor_calendar )
GO
