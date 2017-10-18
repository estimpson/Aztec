SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_jcs] (@workorder varchar (10) ) as
--	Declare
declare	@aqty	numeric(20,6),
	@acost	numeric(20,6),
	@part	varchar(25),
	@scost	numeric(20,6),
	@woqty	numeric(20,6),
	@wopart	varchar(25),
	@scrapqty	numeric(20,6),
	@downtimeqty	numeric(20,6),
	@laborqty	numeric(20,6),
	@downtimerate	numeric(20,6),
	@laborrate	numeric(20,6),
	@machine	varchar(10)

--	Get the machine on the workorder
select	@machine = machine_no
from	work_order
where	work_order = @workorder

--	Get the workorder part
select	@wopart = min(part)
from	workorder_detail
where	workorder = @workorder

--	Get the workorder qty for the part & workorder
select	@woqty = isnull ( sum ( qty_required ), 0)
from	workorder_detail
where	workorder = @workorder and
	part = @wopart

--	Get all the material issues done against the current workorder
select	@aqty	=	sum( quantity ),
	@acost	=	max( cost ),
	@part	=	min( part ) 
from	audit_trail 
where 	workorder = @workorder and 
	type = 'M'

if @acost is null
begin -- 1b
	select	@acost = isnull ( cost_cum, 1 ) 
	from	part_standard
	where	part = @part
end -- 1b

--	Get scrap quantity
select	@scrapqty = isnull ( sum ( quantity ), 0)
from	defects
where	work_order = @workorder

--	Get the downtime & rate
select	@downtimeqty = isnull ( sum ( down_time ), 0)
from	downtime
where	job = @workorder

--	Get downtime rate 
select	@downtimerate = isnull ( standard_rate, 0 )
from	machine
where	machine_no = (select distinct machine from downtime where job = @workorder ) 

--	Get the labor hours & rate
select	@laborqty = sum ( labor_hours )
from	shop_floor_time_log
where	work_order = @workorder

--	Get the labor rate
select	@laborrate = isnull ( standard_rate, 0 )
from	labor
where	id = (select min(labor_code) from part_machine where part = @wopart ) 

--	Get the standard cost for the part
select	@scost = isnull ( cost_cum, 1 ) 
from	part_standard
where	part = @wopart

--	Display results
select	isnull((@aqty * @acost),0), isnull((@scost * @woqty),0), isnull((@scrapqty * @scost),0), isnull((@downtimeqty * @downtimerate),0), isnull((@laborqty * @laborrate),0)
GO
