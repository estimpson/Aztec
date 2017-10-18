SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_jobstatusall] ( @workorder varchar(10) ) as
--	Declare variables
declare	@jcqty	numeric(20,6),
	@miqty	numeric(20,6),
	@objectsproduced numeric(20,6),
	@avgtimeperobject numeric(20,6),
	@objectsused	numeric(20,6),
	@avgtimebetissues numeric(20,6),
	@defectsperobject numeric(20,6),
	@avgtimebetdefects numeric(20,6),	
	@downtimeevents numeric(20,6),
	@avgtimebetdowntime numeric(20,6),	
	@operatorslogged numeric(20,6),
	@avgtimeoflog	numeric(20,6),		
	@part	varchar(25),
	@defectsqty	numeric(20,6),
	@packagetype	varchar(10),
	@packageqty	numeric(20,6),
	@startdate	datetime,
	@enddate	datetime,
	@woqty		numeric(20,6),
	@woobjects	integer,
	@stdate		datetime,
	@eddate		datetime,
	@hrs		numeric(6,2),
	@defectshrs	numeric(6,2),
	@defectsevents	numeric(20,6),
	@downtimehrs	numeric(6,2),
	@laborhrs	numeric(6,2),
	@std_runtime	numeric (20,6),
	@pre_runtime	numeric (20,6), 
	@act_runtime	numeric (20,6),
	@jobcomplete	numeric (20,6),
	@materialissues	numeric (20,6)

--	Get startdatetime & enddatetime of the job	
select	@hrs = datediff(hh, start_date, end_date) + datediff(hh,start_time, end_time)
from	work_order 
where	work_order = @workorder

--	Get workorder quantity
select	@std_runtime 	= isnull(max(qty_required),0) / isnull(parts_per_hour,1), 
	@pre_runtime 	= isnull(max(balance),0) / isnull(parts_per_hour,1), 
	@act_runtime	= max(run_time),
	@jobcomplete	= ((sum(qty_completed) * 100) / isnull(sum(qty_required),1 ) ),
	@woqty		= isnull(sum(qty_required),0)
from	workorder_detail 
where	workorder = @workorder
group by qty_required, balance, parts_per_hour

--	Get job complete quantity from audit_trail for the passed workorder
select	@jcqty = isnull ( sum(quantity), 0 ),
	@objectsproduced = isnull ( count ( 1 ), 0) 
from	audit_trail
where	workorder = @workorder and type = 'J'

--	Get material issue quantity from audit_trail for the passed workorder
select	@miqty = isnull ( sum ( quantity ), 0) ,
	@objectsused = isnull ( count ( 1 ), 0 )  
from	audit_trail
where	workorder = @workorder and type = 'M'

--	Get defects quantity 
select 	@defectsqty = isnull ( sum ( quantity ) , 0) ,
	@defectsevents = isnull(count(1),0)
from	defects
where	work_order = @workorder

if @defectsevents = 0 
	select @defectsevents = 1.0

select	@stdate = min ( defect_date ), 
	@eddate = max ( defect_date )
from	defects
where	work_order = @workorder

select	@defectshrs = isnull( datediff(hh, @stdate, @eddate), 0 )

--	Get downtime quantity
select	@downtimeevents = isnull ( count(1), 0 ),
	@downtimehrs = isnull ( sum ( down_time ), 0 )
from	downtime
where	job = @workorder

--	Get labor recordings
select	@operatorslogged = isnull ( count(1), 0 ) 
from	shop_floor_time_log
where	work_order = @workorder

select	@laborhrs = isnull ( sum( labor_hours ), 0)
from	shop_floor_time_log
where	work_order = @workorder

select	@packageqty = isnull(@packageqty,1.0),
	@objectsproduced = isnull(@objectsproduced,1.0),
	@woobjects = isnull(@woobjects,1.0),
	@defectsperobject = @defectsqty / isnull(@defectsevents,1.0),
	@downtimeevents = isnull(@downtimeevents,1.0),
	@operatorslogged = isnull(@operatorslogged,1.0)	

if @woobjects > 0 	
	select	@avgtimeperobject= isnull((@objectsproduced) * (isnull(@hrs,0) / isnull(@woobjects,1)),0),
		@avgtimebetissues= isnull((@objectsused) * (isnull(@hrs,0) / isnull(@woobjects,1)),0)
else
	select	@avgtimeperobject=0,
		@avgtimebetissues=0
		
if @defectsperobject > 0 
	select	@avgtimebetdefects= isnull(@defectshrs,0) / isnull ( @defectsevents,1)
else
	select	@avgtimebetdefects= 0

if @downtimeevents > 0 
	select	@avgtimebetdowntime= isnull(@downtimehrs,0) / isnull ( @downtimeevents,1)
else
	select	@avgtimebetdowntime= 0
		
if @operatorslogged > 0 
	select	@avgtimeoflog = isnull(@laborhrs,0) / isnull ( @operatorslogged,1)
else
	select	@avgtimeoflog = 0			

if @woqty > 0 
	select	@materialissues = isnull(((isnull(@miqty,0) / isnull (@woqty,1)) * 100),0)
else
	select	@materialissues = 0	
	
--	Display results
select	@objectsproduced, 
	@avgtimeperobject, 
	@objectsused, 
	@avgtimebetissues, 
	@defectsperobject, 
	@avgtimebetdefects, 
	@downtimeevents, 
	@avgtimebetdowntime, 
	@operatorslogged,
	@avgtimeoflog,
	@std_runtime, 
	@pre_runtime, 
	@act_runtime, 
	@jobcomplete, 
	@materialissues,
	@downtimehrs, 
	@defectsqty, 
	@laborhrs,
	@jcqty,
	@miqty
GO
