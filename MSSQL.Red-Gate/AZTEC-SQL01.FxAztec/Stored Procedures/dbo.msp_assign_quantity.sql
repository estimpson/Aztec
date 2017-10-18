SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_assign_quantity] (
        @part   varchar (25) = null )
as
---------------------------------------------------------------------------
--      msp_assign_quantity :

--      1.      Declarations
--      2.      Declare the required cursors (2)
--      3.      Loop through each part & assign quantities for each part 
--      4.      Reset assigned quantities
--      5.      Assign PO/WO quantities in due order for each part
---------------------------------------------------------------------------

--      1.      Declarations
declare @std_qty numeric (20,6),
        @qnty   numeric(20,6),
        @ai_row integer,
        @cpart	varchar(25)

--      2.      Declare the required cursors (2)
if isnull ( @part, '') = ''
begin

--      3.      Declare cursor for unique parts
        select  @part = min ( distinct mvw_replenish.part )
	from	mvw_replenish
	where	mvw_replenish.part > isnull(@part,'')
	order   by 1

        while @part > ''
        begin -- 1ab

	        execute msp_assign_quantity @part

	        select  @part = min ( mvw_replenish.part )
		from	mvw_replenish
		where	mvw_replenish.part > @part
		order   by 1
        
        end -- 1ab
end
else
begin
        select  @std_qty = convert(numeric(20,6),sum ( std_qty ))
        from    mvw_replenish
        where   part = @part

        declare parts_due cursor for
        select  ai_row, qnty
        from    master_prod_sched
        where   part = @part  
        order by due

        --      3.      Loop through each part & assign quantities for each part 

        begin transaction -- 1t

        --      4.      Reset assigned quantities
        
        update  master_prod_sched
        set     qty_assigned = 0
        where   part = @part

        open parts_due
        
        fetch parts_due into @ai_row, @qnty

        --      5.      Assign PO/WO quantities in due order for each part

        while @@fetch_status = 0 and @std_qty > 0 
        begin -- 2b

               if @qnty >= @std_qty
                begin 
                        update master_prod_sched
                        set     qty_assigned = @std_qty
                        where ai_row = @ai_row

                        select @std_qty=0
                end
                else
                begin 
                        update master_prod_sched
                        set     qty_assigned = @qnty
                        where ai_row = @ai_row

                        select @std_qty=@std_qty - @qnty
                end

                fetch parts_due into @ai_row, @qnty
                
        end -- 2b
        
        close parts_due
        deallocate parts_due

        commit transaction  -- 1t
end
GO
