SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_get_demand_quantity] (@part varchar(25)) as
begin -- (1b)
  declare @demand numeric(20,6),
          @woqty  numeric(20,6),
          @onhand numeric(20,6),
          @parttype char(1)
  begin transaction
  select @demand = sum(mps.qnty) - sum(mps.qty_assigned),
         @parttype = max(mps.type)
    from master_prod_sched as mps
   where mps.part = @part
  select @woqty = sum(wod.qty_required)
    from workorder_detail as wod
   where wod.part = @part
  select @onhand = pol.on_hand
    from part_online as pol
   where pol.part = @part
  select isnull(@demand,0), isnull(@woqty,0), isnull(@onhand,0), isnull(@parttype,'')
  commit transaction
end -- (1e)
GO
