SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_onhand_from_s] 
(@shipper integer, 
 @returnvalue integer OUTPUT) as
begin -- (1b)
  declare @part_original varchar(25),
          @totalcount integer,
          @onhand     numeric(20,6)
  create table #sd_part_temp (part_original varchar(25))
  insert into #sd_part_temp (part_original)
  SELECT part_original 
    FROM shipper_detail 
   WHERE (shipper_detail.shipper = @shipper)
  select @returnvalue = 0 -- success status
  select @totalcount = count(*)
    from #sd_part_temp
  if (@totalcount > 0) 
   begin -- (2b)
     set rowcount 1
     select @part_original=part_original
       from #sd_part_temp
     while (@@rowcount > 0) 
      begin -- (3b)
        set rowcount 0 
        -- get object onhand
        select @onhand=sum(std_quantity)
          from object
         where (part=@part_original and status='A')
        -- update part online table
        update part_online
           set on_hand=isnull(@onhand,0)
         where (part=@part_original)
        set rowcount 0 
        delete 
          from #sd_part_temp
         where (part_original = @part_original) 
        set rowcount 1
        select @part_original=part_original
          from #sd_part_temp
      end -- (3e)    
   end -- (2e)
  else
   select @returnvalue=100
  drop table #sd_part_temp
end -- (1e)
GO
