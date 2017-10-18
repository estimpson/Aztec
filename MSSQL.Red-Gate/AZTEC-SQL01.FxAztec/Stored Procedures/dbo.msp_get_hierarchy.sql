SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_get_hierarchy]  (@operator_code varchar (8)) 
as

declare @operator varchar (8),
	@backup_approver varchar(8),
	@backup_end_date datetime, 
	@count integer

	create table #mps_hierarchy (
		operator_code varchar (8) )			/*temp table to hold all codes*/

	create table #mps_operator (
		operator		varchar(8),
		backup_approver		varchar(8) null,
		backup_end_date		datetime null)		/*temp table to process all rows*/

		begin transaction				/* begin transaction */

		/* insert all op codes whose approver is @operator_code */
		insert into #mps_hierarchy
		select operator_code
		from requisition_security 
		where approver = @operator_code or operator_code = @operator_code

		/* insert all op codes whose backup approver is @operator_code */
		insert into #mps_operator
		select operator_code,  backup_approver, backup_approver_end_date
		from requisition_security 
		where ( backup_approver = @operator_code AND getdate() <= backup_approver_end_date  )
		AND ( operator_code <> @operator_code )

		set rowcount 1 

		/* get the first row values from #mps_operator table */
 	        select @operator = operator, 
		       @backup_end_date = backup_end_date,
		       @backup_approver = backup_approver
		from  #mps_operator

		while @@rowcount > 0 
		begin

			set rowcount 0

			/* check for the validity of backup approver end date */
			if getdate() <= @backup_end_date 
			begin
				set rowcount 0
				
				select @count = count(*)
				from #mps_hierarchy 
				where operator_code = @operator

				if isnull (@count, 0) = 0 
				begin
					/* insert row to hierarchy table */
					insert into #mps_hierarchy values ( @operator )
					select @count  = 0 
				end

				set rowcount 0
					
				/* get all the operators list for the operator and */
				/*insert rows to process from #mps_operator*/
				insert into #mps_operator
				select operator_code, backup_approver, backup_approver_end_date
				from requisition_security 
				where approver = @operator and
				operator_code <> @operator  

			end
			else if isnull(@backup_approver,'') = ''
			begin
				set rowcount 0
				
				select @count = count(*)
				from #mps_hierarchy 
				where operator_code = @operator

				if isnull (@count, 0) = 0 
				begin
					/* insert row to hierarchy table if backup approver is null */
					insert into #mps_hierarchy values ( @operator )
					select @count  = 0 
				end
			end		

			set rowcount 0

			/* delete the processed row */
			delete from #mps_operator where operator = @operator 

			set rowcount 1 

			/* get the next row to process */
			select @operator = operator, 
			       @backup_end_date = backup_end_date,
 		               @backup_approver = backup_approver
			from  #mps_operator

		end 

		commit transaction			/*commit transaction */	

		set rowcount 0

		/* select output */
		select operator_code 
		from #mps_hierarchy 
		
		drop table #mps_operator
		drop table #mps_hierarchy 

return
GO
