SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_fp_list_sub] (@childpart varchar(25)) as
begin -- (1b)
  declare @currentchildpart varchar(25),
          @parttype varchar(1),
          @partclass varchar(1)
  create table #bom_temp (parent_part varchar(25) not null)
  begin transaction -- (2b)
  set rowcount 0 
  insert into partlist (part)
  select parent_part from bill_of_material where part=@childpart

/*  insert into #bom_temp (parent_part)
  select parent_part from bill_of_material where part=@childpart
  if (@@rowcount > 0) 
  begin -- (3b)
    set rowcount 1
    select @currentchildpart=parent_part
      from #bom_temp
    while (@@rowcount > 0)    
    begin -- (4b)
      set rowcount 0 
      select @partclass=class,
             @parttype=type
        from part
       where (part=@currentchildpart)
      if (@partclass='M' and @parttype='F')
         insert into partlist values(@currentchildpart)
      set rowcount 0  
      exec msp_fp_list_sub @currentchildpart
      set rowcount 0
      delete 
        from #bom_temp  
       where parent_part=@currentchildpart
      set rowcount 1
      select @currentchildpart=parent_part
        from #bom_temp
     end -- (4e)
  end -- (3e)  
*/
  commit transaction -- (2e)
  drop table #bom_temp
end -- (1e)
GO
