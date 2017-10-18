SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_costs] as
begin

  declare @part_number varchar(25)  

  create table #part_list(
    part varchar(25) not null)

  insert #part_list(part)
  select part.part
    from part
   where part.class in('M','C','P')

  update part_standard
     set cost_cum=0,
         material_cum=0,
         burden_cum=0,
         other_cum=0,
         labor_cum=0,
         flag=0

  set rowcount 1

  select @part_number = part
    from #part_list

  while @@rowcount > 0
    begin
      set rowcount 0

      execute msp_calc_costs @part_number

      set rowcount 1

      delete from #part_list
       where part = @part_number

      select @part_number = part
        from #part_list

    end

  set rowcount 0

end
return
GO
