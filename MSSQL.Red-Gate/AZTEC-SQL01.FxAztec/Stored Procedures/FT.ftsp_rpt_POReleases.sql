SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [FT].[ftsp_rpt_POReleases] ( @fromDate datetime, @ThroughDate datetime )
as

-- ft.Report_PO_Demand '2011-07-01', '2012-12-11'
select	
	po.vendor_code, 
	v.name,
	v.contact,
	v.phone,
	pod.po_number,
	pod.part_number,
	pod.description,
	pod.date_due,
	pod.quantity,
	pod.balance,
	pod.last_recvd_date,
	case when datediff(dd, pod.date_due, getdate())>0 then datediff(dd, pod.date_due, getdate()) else 0 end  DaysLate,
	isNULL(v.outside_processor,'N')

from		
	po_detail pod
join		
	po_header po on pod.po_number = po.po_number
join
	dbo.vendor v on po.vendor_code = v.code
where
	pod.balance >0 and
	pod.date_due >= @fromDate and
	pod.date_due < dateadd(dd, 1,  FT.fn_TruncDate('dd',@ThroughDate))
	
GO
