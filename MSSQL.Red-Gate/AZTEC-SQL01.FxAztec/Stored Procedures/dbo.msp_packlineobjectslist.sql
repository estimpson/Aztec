SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_packlineobjectslist] (@aishipper integer, @asorigin varchar ( 10)=null) as
if len ( @asorigin )  > 1
	select	serial,   
		part,   
		quantity,   
		unit_measure,   
		std_quantity,   
		weight,   
		type,
		parent_serial  
	from	object  
	where	shipper = @aishipper
	union
	select	serial,   
		part,   
		quantity,   
		unit_measure,   
		std_quantity,   
		weight,   
		type,
		parent_serial  
	from	object  
	where	origin = isnull(@asorigin,'')
	order by 1 asc
else
	select	serial,   
		part,   
		quantity,   
		unit_measure,   
		std_quantity,   
		weight,   
		type,
		parent_serial  
	from	object  
	where	shipper = @aishipper
	order by 1 asc
GO
