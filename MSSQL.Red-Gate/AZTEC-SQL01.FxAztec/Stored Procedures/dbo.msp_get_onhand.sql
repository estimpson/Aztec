SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* modified on 10/29/98 */

create procedure [dbo].[msp_get_onhand] ( @l_s_part varchar ( 25) )
as
begin
if (select onhand_from_partonline from parameters) <> 'Y'	
	SELECT	SUM ( isnull(o.std_quantity,0) ) as onhand,   
		isnull(sd.order_no, 0) as origin,   
		SUM ( isnull(o.std_quantity,0) ) as available   
	FROM	 	object as o, shipper_detail  as sd   
	WHERE	o.shipper = sd.shipper AND 	  		
		o.part = sd.part_original AND  
		o.part = @l_s_part AND  
		o.status = 'A'    
	GROUP BY sd.order_no    
	UNION     
	SELECT	SUM ( isnull( std_quantity,0) ) as onhand,    
	 	0,   
		SUM ( isnull(std_quantity,0) ) as available     
	FROM	 object as o    
	WHERE	isnull(shipper,0) = 0 AND
		o.part = @l_s_part AND
		status = 'A' 
else
	SELECT	on_hand as onhand,   
		0  as origin,   
		on_hand as available   
	FROM	part_online
	WHERE	part = @l_s_part 
end
GO
