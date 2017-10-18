SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_vendor_part_list] 
	( 	@mode varchar (1), 
		@st_date datetime, 
		@type varchar (15)= null, 
		@value varchar (15) = null) 
as
begin
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	This stored procedure is used to build the part/vendor list in po processor.
--	This also flags the part/vendor if there are active po releases to the same in the selected date range (week).
--
--	8/30/99 MB Original
--
--	Arguments : 	@mode 	 : 'Part' mode or 'Vendor' Mode on the po processor
--			@st_date : The start date on the po processor window
--			@type 	 : The type of filter selected by user
--			@value 	 : The value to filter for.
--
--	Return :	The set of part/vendor list with the flag value if they have active requirements.
--
--	Process :	
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if @mode = 'V' 
begin

	if @type = 'All'
	
	        select distinct vendor.code,   
	               	vendor.name,   
	                 ( select distinct count ( vendor_code ) - count ( deleted )   
	                   from         po_detail 
	                   where po_detail.vendor_code = vendor.code and
	                   po_detail.status = 'A' and
	                   po_detail.date_due <= dateadd ( day, 7, @st_date ) ) flag
	        from vendor
	        order by 1 
	
	else if @type = 'DropShip'
	
	        select distinct vendor.code,   
	                vendor.name,   
	                 ( select distinct count ( vendor_code ) - count ( deleted )   
	                   from         po_detail 
	                   where   po_detail.vendor_code = vendor.code and
		                   po_detail.status = 'A' and
	        	           po_detail.date_due <= dateadd ( day, 7, getdate() ) and
				   po_detail.ship_type = 'D' ) flag
		from vendor 
		join po_header on po_header.vendor_code = vendor.code  and
				po_header.ship_type = 'DropShip' 
		order by 1
	
	  else if ( @type = 'Buyer' and @value > '' )
	
	        select distinct vendor.code,   
	               	  vendor.name,   
	                 ( select distinct count ( vendor_code ) - count ( deleted )   
	                   from         po_detail 
	                   where po_detail.vendor_code = vendor.code and
	                   po_detail.status = 'A' and
	                   po_detail.date_due <= dateadd ( day, 7, @st_date ) ) flag
	        from vendor
	        where vendor.buyer = @value 
	       order by 1
		
	else if ( @type = 'Vendor' and @value > '' )
	
	                select distinct vendor.code,   
	                       	 vendor.name,   
		                 ( select distinct count ( vendor_code ) - count ( deleted )   
		                   from         po_detail 
		                   where po_detail.vendor_code = vendor.code and
		                   po_detail.status = 'A' and
		                   po_detail.date_due <= dateadd ( day, 7, @st_date ) ) flag
	                from vendor
		where vendor.code = @value 
		order by 1
	
	else if ( @type = 'Plant' and @value > '' )
	
		select distinct po_header.vendor_code,
		       	vendor.name, 
		       	( select distinct count ( vendor_code ) - count ( deleted )   
	                           	from         po_detail 
	        	           	where po_detail.vendor_code = vendor.code and
	        	   	po_detail.status = 'A' and
	                   	po_detail.date_due <= dateadd ( day, 7, @st_date ) ) flag 
		from po_header
			join vendor on po_header.vendor_code = vendor.code 
		where 	( po_header.plant = @value )  and
		 	( po_header.status = 'A' ) 
			order by 1
	end 
	else if @mode = 'P'
	begin
	
	if @type = 'All' 
	
	        select  distinct part.part, 
		        	part.name,
		        	( select distinct count ( vendor_code ) - count ( deleted )   
		           	from         po_detail 
		           	where po_detail.part_number = part.part and
		           	po_detail.status = 'A' and
		           	po_detail.date_due <= dateadd ( day, 7 , getdate() ) ) flag
	          from part 
	          where ( part.class = 'P' ) OR ( part.class = 'N' ) 
	          order by 1
	
	else if  ( @type = 'Buyer' and @value > '' )
	
		select distinct part.part, 
			       part.name,
			        ( select distinct count ( vendor_code ) - count ( deleted )   
			          from         po_detail 
			          where po_detail.part_number = part.part and
			          po_detail.status = 'A' and
			          po_detail.date_due <= dateadd ( day, 7 , getdate() ) ) flag 
		from part, part_purchasing 
		where ( part.part = part_purchasing.part ) 
		AND (part.class = 'P' OR part.class = 'N') 
		AND ( part_purchasing.buyer = @value ) 
		order by 1
	
	else if ( @type = 'Commodity' and @value > '' )
	
		select distinct part.part,		       
			       part.name,
		                ( select distinct count ( vendor_code ) - count ( deleted )   
		                   from         po_detail 
		                   where po_detail.part_number = part.part and
		                   po_detail.status = 'A' and
		                   po_detail.date_due <= dateadd ( day, 7 , getdate() ) ) flag 
		from part 
		where ( part.commodity = @value ) 
		AND   (part.class = 'P' OR part.class = 'N') 
		order by 1
	
	end
end
GO
