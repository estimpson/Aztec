SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_calculateyield] (
@part	varchar(25),
@requiredqty numeric(20,6), 
@workorder varchar(10) ) as
-------------------------------------------------------------------------------------------------
--	Name : msp_calculateyield
--
--	Purpose:	To calculate the yield for graph purposes
--
--	Arguments:	@part varchar			Part for which yield has to be computed
--			@requiredqty numeric(20,6)	Required or demand quantity
--			@workorder varchar(10)		Work order no to get the Material issues from Audit trail
--	
--	Development	GPH	12/12/99	Original
--			GPH	04/25/00	Modified the where clause (eliminated part in the where clause
--						from audit trail select
-------------------------------------------------------------------------------------------------
--	1.	Declare local variables.
declare @completedqty numeric(20,6)

--	2.	Create temporary table for exploding components.
create table #bomparts (part	varchar(25),
			bomqty	numeric(20,6) )
			
create table #bpartsqty (part	varchar(25),
			qty	numeric(20,6))

--	3.	Get components parts
insert	into #bomparts
select	part, quantity
from	bill_of_material
where	parent_part = @part

--	4.	Get the materials issued for the above part from audit_trail
select	@completedqty = isnull(sum(quantity),0)
from	audit_trail
where	workorder = @workorder and type = 'M'

--	5.	Insert data into the temp table
insert	into #bpartsqty
select	part, isnull( bomqty, 0) * isnull(@requiredqty ,0)
from	#bomparts
union	all
select	part, isnull( bomqty, 0) * isnull(@completedqty ,0)
from	#bomparts

--	6.	Display results
select	part, qty from #bpartsqty
GO
