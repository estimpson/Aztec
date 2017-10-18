SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_component_list](@top_part varchar(25))
as
begin
 create table #stack(
   part varchar(25) null,
   )
 create table #output_stack(
   part varchar(25) null,
   )
 declare @count integer,
 @part varchar(25)
 insert into #stack values(@top_part)
 select @count=1
 while @count>0
   begin
     select @part=max(part)
       from #stack
     delete from #stack where part=@part
     insert into #output_stack values(@part)
     insert into #stack
       select bom.part
         from bill_of_material as bom
         where bom.parent_part=@part
     select @count=@@rowcount
   end
 select part from #output_stack where part<>@top_part
 drop table #stack
 drop table #output_stack
end
GO
