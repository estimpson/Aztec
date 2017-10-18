SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_mps_assignedqty] (@part varchar(25), @rtnval int OUTPUT) as
begin -- (1b)
  declare @qty_tobeassigned numeric(20,6),
          @qty_remain numeric(20,6),
          @part_type char(1),
          @qnty numeric(20,6),
          @due datetime,
          @source integer, 
          @origin integer,
          @id integer,
          @updqty numeric(20,6),
          @totcount integer
  create table #mps_temp 
         (qnty       numeric(20,6) null,
          part       varchar(25) not null,
          due        datetime not null,
          source     integer not null,
          origin     integer null,
          id         integer null )
  begin transaction     
  select @rtnval = 0  
  -- set qty_assigned to 0 in mps table for that part,
  -- get sum of qty_required from workorder_detail table
  -- process row by row for that part in mps table to set the assigned quantity until the qty 
  -- becomes zero
  -- update mps qty assigned column with 0 for that part
  set rowcount 0 
  UPDATE master_prod_sched
      SET qty_assigned = 0 
    WHERE part = @part   
  if @@rowcount > 0 
   begin -- (2b)
     -- get part type
     SELECT @part_type=class
       FROM part
      WHERE part=@part
     -- get the qty to be assigned from either of the table 
     if @part_type = 'M'
        SELECT @qty_tobeassigned=isnull(sum(qty_required),0)
          FROM workorder_detail
         WHERE (part=@part)
     else if @part_type = 'P'
        SELECT @qty_tobeassigned=isnull(sum(standard_qty),0)
          FROM po_detail  
         WHERE (po_detail.status <> 'C') AND (po_detail.part_number = @part )
     -- insert rows into temp table
     insert into #mps_temp (qnty, part, due, source, origin, id)
     select qnty, part, due, source, origin, id
       from master_prod_sched
      where (part=@part)
      order by start_time
     -- get total count
     SELECT @totcount = count(*)
       FROM #mps_temp
     if @totcount > 0 
      begin -- (3b) 
        set rowcount 1 
        select @qnty = qnty,
               @due  = due,
               @source = source,
               @origin = origin,
               @id = id
          from #mps_temp             
        while (@qty_tobeassigned > 0 and @@rowcount > 0) 
         begin -- (4b)
           If @Qty_tobeassigned > @qnty 
              select @updqty = @qnty, @qty_tobeassigned = @qty_tobeassigned - @qnty
           else 
            begin 
              select @updqty = @qty_tobeassigned
              select @qty_tobeassigned = 0
            end
           if @updqty > 0  
            begin
              set rowcount 0 
              update master_prod_sched
                 set qty_assigned = @updqty
               where (part=@part and due=@due and source=@source and id=@id)
	         set rowcount 0 
                 delete
                   from #mps_temp 
                  where (part=@part and due=@due and source=@source and id=@id)
                 set rowcount 1 
                 select @qnty = qnty,
                        @due  = due,
                        @source = source,
                        @origin = origin,
                        @id = id
                   from #mps_temp              
            end 
         end --(4e)
        select @rtnval = 0  
      end -- (3e)
   end -- (2e) 
  if @rtnval <> 0 
     rollback transaction
  else 
     commit transaction 
  set rowcount 0    
end -- (1e)
GO
