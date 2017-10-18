SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_check_downline](@@parent varchar(25),@@child varchar(25)) as
begin
  declare @cur_part varchar(25),
  @level integer,
  @current_datetime datetime
  select @current_datetime=convert(datetime,convert(varchar(12),GetDate())+' '+convert(varchar(2),datepart(hh,GetDate()))+':'+convert(varchar(2),datepart(mi,GetDate()))+':'+convert(varchar(2),datepart(ss,GetDate())))
  insert into temp_bom_stack
    select part,1, @@spid
      from bill_of_material_ec
      where parent_part=@@child
      and start_datetime<=@current_datetime
      and(end_datetime>=@current_datetime
      or end_datetime is null)
  select @level=1
  while @level>0
    begin
      select @cur_part=min(part)
        from temp_bom_stack
        where partlevel=@level and
	 	spid=@@spid
      if @cur_part is not null
        begin
          if @cur_part=@@parent
          begin
          	rollback transaction
          	return
          end
          delete from temp_bom_stack
            where part=@cur_part
            and partlevel=@level and
	    spid=@@spid
          insert into temp_bom_stack
            select part,
              @level+1,@@spid
              from bill_of_material_ec
              where parent_part=@cur_part
              and start_datetime<=@current_datetime
              and(end_datetime>=@current_datetime
              or end_datetime is null)
          if @@error=0
            select @level=@level+1
        end
      else
        select @level=@level-1
    end
end
GO
