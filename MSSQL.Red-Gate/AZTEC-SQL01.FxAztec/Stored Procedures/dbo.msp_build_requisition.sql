SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_requisition] ( @operator_code varchar (8) = null, @mode varchar (1) = null, @showclosed char(1) = 'N' ) 
as
begin
----------------------------------------------------------------------------------------
--	Stored procedure to get the hierarchy levels, dollar limits for a given operator
--	Arguments: @operator_code varchar (8) : to pass the operator code for which
--						sp is retrieved
--
--		   @mode	varchar (1)   : 'A' or 'S' from requisition_inquiry screen
--
--	Original : 05/10/99	MB
--	Modified : 05/19/99	MB
--		 : 12/20/99	Eric.E.Stimpson	Add minimum and maximum po number to result set.
--		 : 01/31/02	GPH Modified the select statements, included a left outer join 	
----------------------------------------------------------------------------------------
	declare @operator varchar (8),
		@count 		integer,
		@level 		integer,
		@app_operator	varchar (8),
		@operator_level	integer,
		@dollar_prev	numeric (20,6),
		@dollar		numeric (20,6)

	begin transaction
	
--	temp table to process all rows
	create table #mps_operator (
		operator_code		varchar(8),
		approver		varchar(8) null,
		approver_dollar		numeric (20,6) null,
		self_dollar		numeric (20,6) null,
		hierarchy_level		integer )		

		select @level = 0 
		select @count = 0 

--		get operator level for this operator
		select @operator_level = security_level
		from requisition_security
		where operator_code = @operator_code

--		insert row for current operator into the temp table
		insert into #mps_operator
		select operator_code, 
			approver, 
			0,
			self_dollar_limit,
			@level
		from requisition_security 
		where approver =  @operator_code 

--		get number of rows from the temp table
		select @count = count(1)
		from #mps_operator

--		loop while there are more than a row inserted
		while @count > 0 
		begin
		
			select @level = @level - 1 

--			insert previous hierarchy levels operator codes		
			insert into #mps_operator
			select operator_code, 
				approver, 
				0, 
				self_dollar_limit,
				@level
			from requisition_security 
			where approver in ( select operator_code 
					    from #mps_operator 
					    where hierarchy_level = @level + 1) 
			and approver <> @operator_code

			select @count = count(1)
			from requisition_security 
			where approver in ( select operator_code 
						from #mps_operator 
						where hierarchy_level = @level )
			and approver <> @operator_code

			if @count > 0 						
				select @count = 1 
			else if @count is null or @count <= 0 
				select @count = 0 

		end

		select @level = 0 
		select @count = 0 
		select @operator = @operator_code

--		insert rows for operator in next and higher hierarchy levels
		while @operator > '' and @count = 0 
		begin

			select @level = @level + 1 

			insert into #mps_operator
			select operator_code, 
				approver, 
				0,
				self_dollar_limit,
				@level
			from requisition_security 
			where operator_code =  @operator and
			      operator_code not in (select operator_code from #mps_operator 
						    where hierarchy_level <= @level ) 

			select @app_operator = @operator
	
			select @operator = null

			select @operator = approver
			from #mps_operator
			where operator_code = @app_operator  

			if @operator  > '' 
				select @count = count ( 1 )
				from #mps_operator 
				where operator_code = @operator 
			else
				select @count = 1 
			
			if @count > 0 						
				select @count = 1 
			else
				select @count = 0 
		end

-- 	get dollar limits for the operator 
	update #mps_operator
	set approver_dollar = (select dollar 
		      from requisition_security 
		      where #mps_operator.approver = requisition_security.operator_code )

--		insert backup approver for this operator
		if ( select backup_approver 
			from requisition_security 
			where operator_code = @operator_code ) > '' 
		begin
			insert into #mps_operator
			select operator_code, 
			       backup_approver, 
			       dollar, 
			       self_dollar_limit,
			       0
			from  requisition_security 
			where operator_code = @operator_code 
		end

--		insert approver as backup approver 
		if ( select min(operator_code)
			from requisition_security 
			where backup_approver = @operator_code ) > '' 
		begin
			insert into #mps_operator
			select operator_code, 
			       @operator_code, 
			       dollar, 
			       self_dollar_limit,
			       0
			from requisition_security
			where backup_approver = @operator_code
		end

	commit transaction			/*commit transaction */	

	set rowcount 0

--	select output 	
--	select * from #mps_operator order by hierarchy_level 

	if @operator_level = 1 
	begin
		select requisition_header.requisition_number,   
        	 	requisition_header.vendor_code,
	        	 requisition_header.creation_date,   
	        	 requisition_header.status,   
		         requisition_header.requested_date,   
        		 requisition_header.requisitioner,   
		         requisition_header.ship_to_destination,   
        		 requisition_header.terms,   
	        	 requisition_header.fob,   
	        	 requisition_header.ship_via,   
		         requisition_header.notes,   
        		 requisition_header.approved,   
		         requisition_header.approver,   
        		 requisition_header.approval_date,   
	        	 requisition_header.freight_type,
			total_cost = (SELECT isnull ( sum (extended_cost) , 0 )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			min_po = (SELECT min ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			max_po = (SELECT max ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
        	 	name
			from requisition_header
				left outer join vendor on vendor.code = requisition_header.vendor_code   
			where requisition_header.requisitioner = @operator_code and
				requisition_header.status <> ( case @showclosed when 'N' then '7' else '-1' end )
	end
	else if @operator_level = 7  
	begin
		if @mode = 'A'
			select requisition_header.requisition_number,   
        	 	requisition_header.vendor_code,
	        	 requisition_header.creation_date,   
	        	 requisition_header.status,   
		         requisition_header.requested_date,   
        		 requisition_header.requisitioner,   
	        	 requisition_header.ship_to_destination,   
	        	 requisition_header.terms,   
		         requisition_header.fob,   
	        	 requisition_header.ship_via,   
		         requisition_header.notes,   
        		 requisition_header.approved,   
	        	 requisition_header.approver,   
	        	 requisition_header.approval_date,   
		         requisition_header.freight_type,
			 total_cost = (SELECT isnull ( sum (extended_cost) , 0 )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			min_po = (SELECT min ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			max_po = (SELECT max ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),   
        	 	name
			from requisition_header   
				left outer join vendor on vendor.code = requisition_header.vendor_code   
			where ( requisition_header.requisitioner in ( select operator_code 
						 from #mps_operator 
					 	where hierarchy_level <= 1 )  
			or ( requisition_header.status in ( '3', '8' ) ) and  
				requisition_header.status <> ( case @showclosed when 'N' then '7' else '-1' end ) )
		else
		begin

			select @dollar_prev =  (select max ( approver_dollar )
					       from #mps_operator 
						where hierarchy_level = -1 ),
				 @dollar = ( select dollar 
						from requisition_security 
						where operator_code = @operator_code )

			select @dollar_prev = isnull ( @dollar_prev, 0 ),
			       @dollar	    = isnull ( @dollar, 0 )

			select requisition_header.requisition_number,   
		         	requisition_header.vendor_code,   
			         requisition_header.creation_date,   
        			 requisition_header.status,   
		        	 requisition_header.requested_date,   
	        		 requisition_header.requisitioner,   
		        	 requisition_header.ship_to_destination,   
	        		 requisition_header.terms,   
		        	 requisition_header.fob,   
	        		 requisition_header.ship_via,   
			         requisition_header.notes,   
        			 requisition_header.approved,   
	        		 requisition_header.approver,   
		        	 requisition_header.approval_date,   
			         requisition_header.freight_type,
				 total_cost = (SELECT isnull ( sum (extended_cost) , 0 )
						 FROM requisition_detail  
						WHERE requisition_detail.requisition_number =  
							requisition_header.requisition_number ),
			min_po = (SELECT min ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			max_po = (SELECT max ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),   
        	 		name
				from requisition_header   
					left outer join vendor on vendor.code = requisition_header.vendor_code   
				where ( ( ( requisition_header.requisitioner in ( select operator_code 
							 from #mps_operator 
							 where hierarchy_level <= 1 ) ) 
				and ( (SELECT  sum (extended_cost) 
					FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ) > @dollar_prev 
					and 
					(SELECT   sum (extended_cost) 
				 	FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ) <= @dollar ) ) or 
			( requisitioner = @operator_code ) 
			or requisition_header.status = '3' or requisition_header.status = '8' ) and
				requisition_header.status <> ( case @showclosed when 'N' then '7' else '-1' end )

		end
	end
	else 		
	begin
		if @mode = 'A'
			select requisition_header.requisition_number,   
        	 	requisition_header.vendor_code,   
	        	 requisition_header.creation_date,   
	        	 requisition_header.status,   
		         requisition_header.requested_date,   
        		 requisition_header.requisitioner,   
		         requisition_header.ship_to_destination,   
        		 requisition_header.terms,   
	        	 requisition_header.fob,   
	        	 requisition_header.ship_via,   
		         requisition_header.notes,   
        		 requisition_header.approved,   
		         requisition_header.approver,   
        		 requisition_header.approval_date,   
	        	 requisition_header.freight_type,
			 total_cost = (SELECT isnull ( sum (extended_cost) , 0 )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			min_po = (SELECT min ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			max_po = (SELECT max ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),   
        	 	name
			from requisition_header   
				left outer join vendor on vendor.code = requisition_header.vendor_code   
			where ( requisition_header.requisitioner in ( select operator_code 
						 from #mps_operator 
						 where hierarchy_level <= 1 ) )  and
				requisition_header.status <> ( case @showclosed when 'N' then '7' else '-1' end )

		else
		begin
			select @dollar_prev =  ( select max ( approver_dollar )
						from #mps_operator 
						where  hierarchy_level = -1),	       
					 @dollar = ( select dollar 
					from requisition_security  
					where operator_code = @operator_code  )

			select @dollar_prev = isnull ( @dollar_prev, 0 ),
			       @dollar	    = isnull ( @dollar, 0 )
	
			select requisition_header.requisition_number,   
         			requisition_header.vendor_code,   
			         requisition_header.creation_date,   
        			 requisition_header.status,   
			         requisition_header.requested_date,   
        			 requisition_header.requisitioner,   
			         requisition_header.ship_to_destination,   
        			 requisition_header.terms,   
			         requisition_header.fob,   
        			 requisition_header.ship_via,   
			         requisition_header.notes,   
        			 requisition_header.approved,   
			         requisition_header.approver,   
        			 requisition_header.approval_date,   
			         requisition_header.freight_type,
				 total_cost = (SELECT isnull ( sum (extended_cost) , 0 )
						 FROM requisition_detail  
						WHERE requisition_detail.requisition_number =  
							requisition_header.requisition_number ),
			min_po = (SELECT min ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),
			max_po = (SELECT max ( po_number )
					 FROM requisition_detail  
					WHERE requisition_detail.requisition_number =  
						requisition_header.requisition_number ),   
        	 	name
			from requisition_header   
				left outer join vendor on vendor.code = requisition_header.vendor_code   
			where ( ( ( requisition_header.requisitioner in ( select operator_code 
						 from #mps_operator 
						 where hierarchy_level <= 1 ) )  
				and ( (SELECT sum (extended_cost)
				FROM requisition_detail  
				WHERE requisition_detail.requisition_number =  
					requisition_header.requisition_number ) > @dollar_prev 
				and 
				(SELECT sum (extended_cost)
				 FROM requisition_detail  
				WHERE requisition_detail.requisition_number =  
					requisition_header.requisition_number ) <= @dollar ) ) 
				or ( requisitioner = @operator_code ) ) and
				requisition_header.status <> ( case @showclosed when 'N' then '7' else '-1' end )

		end
	end

	drop table #mps_operator

end
GO
