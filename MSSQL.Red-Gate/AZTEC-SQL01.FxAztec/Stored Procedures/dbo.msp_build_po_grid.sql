SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_po_grid] 
        ( @po_number integer = null,
        @start_dt datetime,
        @part varchar(25)=null,
        @mode varchar(1) ) 
as
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	This procedure builds the PO processor crosstab datawindow for a particular PO or Part
--
--	Arguments :	@po_number	: The po number for which the crosstab is being build
--			@start_dt 	: The start date from which the crosstab is built
--			@part		: The part for which crosstab is built
--			@mode		: The part mode or vendor mode switch.
--
--	MB : 09/09/1999	: Original
--
--	Process :
--		1. Create temp table to get all the parts from po_detail and part_vendor table
--		2. Check if its vendor mode  or part mode
--		3. Check if its a Blanket Purchase Order
--		4.  Insert part list to temp table 
--		5. Select rows from po detail and temp table 	    
--		6. Select the row from Blanket Purchase Order Detail	    
--		7. Select vendor list for the part, different po's
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	1. Create temp table to get all the parts from po_detail and part_vendor table

create table #mps_part ( part varchar (25) )

--	2. Check if its vendor mode  or part mode
if @mode='V'
begin
	--	3. Check if its a Blanket Purchase Order
	if ( select type from po_header where po_number = @po_number ) <>'B' 
	begin
		--	4.  Insert part list to temp table 
		
		insert into #mps_part 
		select	distinct pv.part 
		from	part_vendor pv
			join po_header poh on poh.vendor_code = pv.vendor
			left outer join part p on p.part = pv.part and p.class = 'P'
		where 	poh.po_number = @po_number
		union all
		select 	distinct pod.part_number
		from 	po_detail pod
			left outer join part p on p.part = pod.part_number and p.class = 'P'
		where 	pod.po_number = @po_number and 
			pod.part_number not in ( select	distinct pv.part 
						 from	part_vendor pv
						 join po_header poh on poh.vendor_code = pv.vendor
						 left outer join part p on p.part = pv.part and p.class = 'P'
						 where 	poh.po_number = @po_number)
		--	5. Select rows from po detail and temp table 	    
		select	po_detail.part_number,
			Max(po_detail.date_due),
			date1=Max(@start_dt),
			qty_past_due=(Sum(case when po_detail.date_due<@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<@start_dt then received else 0 end)),
			qty_date1=(Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then received else 0 end)),
			qty_date2=(Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then received else 0 end)),
			qty_date3=(Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then received else 0 end)),
			qty_date4=(Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then received else 0 end)),
			qty_date5=(Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then received else 0 end)),
			qty_date6=(Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then received else 0 end)),
			qty_date7=(Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then received else 0 end)),
			Max(po_detail.po_number),
			Max(po_detail.release_type),
			Max(po_detail.release_no),
			flag=  isnull ( (select	max(1) 
					from	po_detail pod
					where	pod.date_due>DateAdd ( dd,7,@start_dt ) and
						pod.po_number = @po_number and
						po_detail.part_number = pod.part_number and
						( pod.deleted = 'N' or pod.deleted  is null ) ), 0 )
		from	po_detail 
			left outer join part p on p.part = po_detail.part_number and p.class = 'P'
		where	po_detail.po_number=@po_number
		group by po_Detail.part_number
	        union
		select  #mps_part.part,
			@start_dt,
			date1=@start_dt,
			qty_past_due=0,
			qty_date1=0,
			qty_date2=0,
			qty_date3=0,
			qty_date4=0,
			qty_date5=0,
			qty_date6=0,
			qty_date7=0,
			@po_number,
			null,
			null,
			flag= 0
		from	#mps_part
			left outer join part p on p.part = #mps_part.part and p.class = 'P'
		where 	#mps_part.part not in ( select distinct part_number  from po_Detail 
						where po_number = @po_number)
		group by #mps_part.part
		order by 1
	end
	else
--	6. Select the row from Blanket Purchase Order Detail	    
		select	max ( po_header.blanket_part),
			Max(po_detail.date_due),
			date1=Max(@start_dt),
			qty_past_due= (Sum(case when po_detail.date_due<@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<@start_dt then received else 0 end)),
			qty_date1= (Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then received else 0 end)),
			qty_date2= (Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then received else 0 end)),
			qty_date3= (Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then received else 0 end)),
			qty_date4= (Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then received else 0 end)),
			qty_date5= (Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then received else 0 end)),
			qty_date6= (Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then received else 0 end)),
			qty_date7= (Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then received else 0 end)),
			Max(po_detail.po_number),
			Max(po_detail.release_type),
			Max(po_detail.release_no),
			flag=isnull ( ( select max(1)
					from po_detail
					where po_detail.date_due>DateAdd(dd,7,@start_dt)
					and po_number=@po_number), 0 )
		from	po_header 
			left outer join po_Detail on po_Detail.po_number  = po_header.po_number
			left outer join part p on p.part = po_detail.part_number and p.class = 'P'
		where	po_header.po_number = @po_number
end		
else if @mode='P'
--	7. Select vendor list for the part, different po's
	select	max ( po_detail.vendor_code ),
		Max(po_detail.date_due),
		date1=Max(@start_dt),
		qty_past_due=(Sum(case when po_detail.date_due<@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<@start_dt then received else 0 end)),
		qty_date1=(Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,1,@start_dt) and po_detail.date_due>=@start_dt then received else 0 end)),
		qty_date2=(Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,2,@start_dt) and po_detail.date_due>=DateAdd(dd,1,@start_dt) then received else 0 end)),
		qty_date3=(Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,3,@start_dt) and po_detail.date_due>=DateAdd(dd,2,@start_dt) then received else 0 end)),
		qty_date4=(Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,4,@start_dt) and po_detail.date_due>=DateAdd(dd,3,@start_dt) then received else 0 end)),
		qty_date5=(Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,5,@start_dt) and po_detail.date_due>=DateAdd(dd,4,@start_dt) then received else 0 end)),
		qty_date6=(Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,6,@start_dt) and po_detail.date_due>=DateAdd(dd,5,@start_dt) then received else 0 end)),
		qty_date7=(Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then quantity else 0 end)-Sum(case when po_detail.date_due<DateAdd(dd,7,@start_dt) and po_detail.date_due>=DateAdd(dd,6,@start_dt) then received else 0 end)),
		Max(po_detail.po_number),
		Max(po_detail.release_type),
		Max(po_detail.release_no),
		flag= isnull ( (select max(1) 
				from po_detail pod
				where pod.date_due>DateAdd(dd,7,@start_dt) and
				po_detail.po_number = pod.po_number and
				po_detail.part_number = pod.part_number and
				( pod.deleted = 'N' or pod.deleted  is null ) ), 0 )
	from	po_detail
		left outer join part p on p.part = po_detail.part_number and p.class = 'P'
	where	po_detail.status='A' and
		po_detail.part_number = @part
	group by  po_detail.part_number, po_detail.po_number
drop table #mps_part
GO
